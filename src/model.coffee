Mongo = require "mongodb"
ObjectID = Mongo.pure().ObjectID

{HasMany} = require("./proxy")(Poutine)

utils = require "./utils"

connection = require "./connection"

apply = (model)->
  # Determine collection name by inflection.
  unless model.prototype.collection_name
    name = model.name.underscore()
    name = name + "s" unless name.endsWith("s")
    model.prototype.collection_name = name

  model.fields ||= {}

  model.connect = (callback)->
    model.collection callback

  model.collection = (name, callback)->
    [name, callback] = [model.prototype.collection_name, name] unless callback
    connection.connect (err, database)->
      if err
        callback err
      else
        callback null, new Mongo.Collection(database, name)

  model.index = (fields, options = {})->
    model.connect (err, collection)->
      process.emit "error", err if err
      collection.ensureIndex fields, options, (err)->
        process.emit "error", err if err

  model.create = (fields, callback)->
    object = new model(fields)
    object.save callback

  # Model.find "id", (err, record)->
  # or
  # Model.find().all (err, records)->
  # Model.find(query).one (err, record)->
  # Model.find(query, options).each (err, record)->
  model.find = (query = {}, options = {})->
    if Object.isString(query) || query instanceof ObjectID
      callback = options
      query = new ObjectID(query) unless query instanceof ObjectID
      model.connect (err, collection)->
        return callback err if err
        collection.findOne query, options, (err, record) ->
          return callback err if err
          callback null, record && new model().load(record)
    else
      iterator =
        each: (callback)->
          model.connect (err, collection)->
            return callback err if err
            collection.find(query, options).each (err, record) ->
              return callback err if err
              callback null, record && new model().load(record)
        all: (callback)->
          model.connect (err, collection)->
            return callback err if err
            collection.find(query, options).toArray (err, records) ->
              return callback err if err
              callback null, records.map((record)-> new model().load(record))
        one: (callback)->
          model.connect (err, collection)->
            return callback err if err
            collection.findOne query, options, (err, record) ->
              return callback err if err
              callback null, record && new model().load(record)
        count: (callback)->
          model.connect (err, collection)->
            return callback err if err
            collection.find(query, options).count (err, count) ->
              return callback err if err
              callback null, count
        stream: ->
          events = new EventEmitter
          model.connect (err, collection)->
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

  model.remove = (query, options, callback)->
    [callback, options] = [options, {}] unless callback
    [callback, query] = [query, {}] unless callback
    model.connect (err, collection)->
      return callback err if err
      collection.remove query, options, callback

  model.prototype.load = (values)->
    Object.merge this, values
    @_existing = true
    return this

  model.prototype.save = (options, callback)->
    [callback, options] = [options, {}] unless callback
    if this.isNewRecord()
      console.log "NEW RECORD"
      this.create options, callback
    else
      console.log "EXISTING"
      this.update options, callback

  model.prototype.isNewRecord = ->
    return !@_existing

  model.prototype._callbacks = (names, callback)->
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

  model.prototype.create = (options, callback)->
    [callback, options] = [options, {}] unless callback
    this._callbacks ["prepare", "validate", "beforeCreate", "beforeSave"], (err)=>
      return callback err if err
      model.connect (err, collection)=>
        return callback err if err
        fields = {}
        for name, type of model.prototype.fields
          fields[name] = this[name]
        fields[_id] = @_id if @_id
        collection.insert fields, options, (err, results)=>
          return callback err if err
          this._id = results[0]._id
          this._existing = true
          this._callbacks ["afterSave", "afterCreate"], (err)=>
            return callback err if err
            callback null, this

  model.prototype.update = (options, callback)->
    [callback, options] = [options, {}] unless callback
    this._callbacks ["prepare", "validate", "beforeUpdate", "beforeSave"], (err)=>
      return callback err if err
      model.connect (err, collection)=>
        return callback err if err
        fields = {}
        for name, type of model.prototype.fields
          fields[name] = this[name]
        collection.update { _id: @_id }, fields, options, (err, results)=>
          return callback err if err
          this._callbacks ["afterSave", "afterUpdate"], (err)=>
            return callback err if err
            callback null, this
  
  model.prototype.remove = (options, callback) ->
    [callback, options] = [options, {}] unless callback
    return callback new Error("Can't remove an unsaved record.") if this.isNewRecord()
    console.log "before connect"
    model.connect (err, collection)=>
      console.log "in before connect"
      return callback err if err
      collection.remove { _id: @_id }, options, (err) =>
        return callback err if err
        callback null

module.exports = apply