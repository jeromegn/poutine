Mongo = require "mongodb"
ObjectID = Mongo.pure().ObjectID

utils = require "./utils"
extend = require "./lib/extend"

connection = require "./connection"

class Model

  @connect = (callback) ->
    console.log "I'm in your `connect`"
    this.collection callback

  @setCollectionName = ->
    this.prototype.collection_name = utils.toCollectionName(this.name)

  @collection = (name, callback) ->
    console.log "I'm in ur `collection`"

    unless this.prototype.collection_name then this.setCollectionName.call(this)

    [name, callback] = [this.prototype.collection_name, name] unless callback
    connection.connect (err, database)->
      if err
        callback err
      else
        callback null, new Mongo.Collection(database, name)
  
  @index = (fields, options = {}) ->
    this.connect (err, collection)->
      process.emit "error", err if err
      collection.ensureIndex fields, options, (err)->
        process.emit "error", err if err

  @create = (fields, callback)->
    object = new this(fields)
    object.save callback

  @find = (query = {}, options = {})->
    if Object.isString(query) || query instanceof ObjectID
      callback = options
      query = new ObjectID(query) unless query instanceof ObjectID
      this.connect (err, collection)->
        return callback err if err
        collection.findOne query, options, (err, record) ->
          return callback err if err
          callback null, record && new this().load(record)
    else
      iterator =
        each: (callback)->
          this.connect (err, collection)->
            return callback err if err
            collection.find(query, options).each (err, record) ->
              return callback err if err
              callback null, record && new this().load(record)
        all: (callback)->
          this.connect (err, collection)->
            return callback err if err
            collection.find(query, options).toArray (err, records) ->
              return callback err if err
              callback null, records.map((record)-> new this().load(record))
        one: (callback)->
          this.connect (err, collection)->
            return callback err if err
            collection.findOne query, options, (err, record) ->
              return callback err if err
              callback null, record && new this().load(record)
        count: (callback)->
          this.connect (err, collection)->
            return callback err if err
            collection.find(query, options).count (err, count) ->
              return callback err if err
              callback null, count
        stream: ->
          events = new EventEmitter
          this.connect (err, collection)->
            return events.emit "error", err if err
            collection.find query, options, (err, cursor) ->
              return events.emit "error", err if err
              next =
                cursor.nextObject (err, item)->
                  return events.emit "error", err if err
                  if item
                    events.emit "data", item
                    process.nextTick next
                  else
                    events.emit "done"
              next()
          return events
      return iterator

  @remove = (query, options, callback)->
    [callback, options] = [options, {}] unless callback
    [callback, query] = [query, {}] unless callback
    this.constructor.connect (err, collection)->
      return callback err if err
      collection.remove query, options, callback

  # Prototypes
  constructor: (values) ->
    Object.merge this, values

  isNewRecord: ->
    return !this._existing

  _callbacks: (names, callback)->
    if fn = this[names[0]]
      fn.call this, (err)=>
        return callback err if err
        if names.length > 1
          this._callbacks names.slice(1), callback
        else
          callback()
    else if names.length > 1
      this._callbacks names.slice(1), callback
    else
      callback()

  load: (values)->
    Object.merge this, values
    this._existing = true
    return this

  save: (options, callback)->
    [callback, options] = [options, {}] unless callback
    if this.isNewRecord()
      console.log "NEW RECORD"
      this.create options, callback
    else
      console.log "EXISTING"
      this.update options, callback
  
  create: (options, callback)->
    [callback, options] = [options, {}] unless callback
    this._callbacks ["prepare", "validate", "beforeCreate", "beforeSave"], (err)=>
      return callback err if err
      console.log "before connect"
      this.constructor.connect (err, collection)=>
        console.log "in before connect"
        return callback err if err
        fields = {}
        for name, type of this.constructor.prototype.fields
          fields[name] = this[name]
        fields[_id] = @_id if @_id
        collection.insert fields, options, (err, results)=>
          return callback err if err
          this._id = results[0]._id
          this._existing = true
          this._callbacks ["afterSave", "afterCreate"], (err)=>
            return callback err if err
            callback null, this
    
  update: (options, callback)->
    [callback, options] = [options, {}] unless callback
    this._callbacks ["prepare", "validate", "beforeUpdate", "beforeSave"], (err)=>
      return callback err if err
      this.constructor.connect (err, collection)=>
        return callback err if err
        fields = {}
        for name, type of this.constructor.prototype.fields
          fields[name] = this[name]
        collection.update { _id: @_id }, fields, options, (err, results)=>
          return callback err if err
          this._callbacks ["afterSave", "afterUpdate"], (err)=>
            return callback err if err
            callback null, this

  remove: (options, callback) ->
    [callback, options] = [options, {}] unless callback
    return callback new Error("Can't remove an unsaved record.") if this.isNewRecord()
    console.log "before connect"
    this.constructor.connect (err, collection)=>
      console.log "in before connect"
      return callback err if err
      collection.remove { _id: @_id }, options, (err) =>
        return callback err if err
        callback null

# Backbone-like extending
Model.extend = extend

module.exports = Model