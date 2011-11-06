require "sugar"
Mongo = require "mongodb"
ObjectID = Mongo.pure().ObjectID

Async = require "async"

connection = require "./connection"

utils = require "./utils"

Poutine = {}

Poutine.collection = connection.collection.bind(connection)
Poutine.connect = connection.connect.bind(connection)
Poutine.connection = connection

Poutine.collections = {}

reservedKeywords = ["extended", "included"]

finder = (query = {}, options = {})->
  if Object.isString(query) || query instanceof ObjectID
    callback = options
    query = new ObjectID(query) unless query instanceof ObjectID
    this.connect (err, collection)=>
      return callback err if err
      collection.findOne query, options, (err, record) ->
        return callback err if err
        callback null, record && new this().load(record)
  else
    iterator =
      each: (callback)=>
        this.connect (err, collection)=>
          return callback err if err
          collection.find(query, options).each (err, record) =>
            return callback err if err
            callback null, record && new this().load(record)
      all: (callback)=>
        this.connect (err, collection)=>
          return callback err if err
          collection.find(query, options).toArray (err, records) =>
            return callback err if err
            callback null, records.map((record)=> new this().load(record))
      one: (callback)=>
        this.connect (err, collection)=>
          return callback err if err
          collection.findOne query, options, (err, record) =>
            return callback err if err
            callback null, record && new this().load(record)
      count: (callback)=>
        this.connect (err, collection)=>
          return callback err if err
          collection.find(query, options).count (err, count) =>
            return callback err if err
            callback null, count
      stream: =>
        events = new EventEmitter
        this.connect (err, collection)=>
          return events.emit "error", err if err
          collection.find query, options, (err, cursor) =>
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

Poutine.Collection =
  # Once extended
  extended: ->
    this.relations = []
    this.prototype.fields ||= {}

    # Generate a collection name
    unless this.prototype.collection_name
      name = this.name.underscore()
      name = name + "s" unless name.endsWith("s")
      this.prototype.collection_name = name
    
    Poutine.collections[this.prototype.collection_name] = this

  connect: (callback)->
    this.collection callback

  collection: (name, callback)->
    [name, callback] = [this.prototype.collection_name, name] unless callback
    connection.connect (err, database)->
      if err
        callback err
      else
        callback null, new Mongo.Collection(database, name)

  index: (fields, options, callback)->
    options ||= {}
    callback ||= (err, index) ->
      process.emit "error", err if err
    this.connect (err, collection)->
      process.emit "error", err if err
      console.log "Ensuring indexes in the collection #{collection.collectionName}"
      collection.ensureIndex fields, options, callback

  create: (fields, callback)->
    object = new this(fields)
    object.save callback

  # Model.find "id", (err, record)->
  # or
  # Model.find().all (err, records)->
  # Model.find(query).one (err, record)->
  # Model.find(query, options).each (err, record)->
  find: ->
    finder.apply this, arguments

  remove: (query, options, callback)->
    [callback, options] = [options, {}] unless callback
    [callback, query] = [query, {}] unless callback
    this.connect (err, collection)->
      return callback err if err
      collection.remove query, options, callback

  hasMany: (collection) ->
    this.relations.push
      type: "hasMany"
      parent: this
      child: collection

  belongsTo: (collection) ->
    # To implement

Poutine.Document =

  load: (values)->
    Object.merge this, values
    @_existing = true
    return this

  save: (options, callback)->
    [callback, options] = [options, {}] unless callback
    if this.isNewRecord()
      this.create options, callback
    else
      this.update options, callback

  isNewRecord: ->
    return !@_existing

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

  create: (options, callback)->
    [callback, options] = [options, {}] unless callback
    this._callbacks ["prepare", "validate", "beforeCreate", "beforeSave"], (err)=>
      return callback err if err
      this.constructor.connect (err, collection)=>
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

class Poutine.Model
  constructor: (values)->
    Object.merge this, values
    # Don't enumerate _existing
    Object.defineProperty this, '_existing', {writable: true}
    this.setupRelations()
  
  setupRelations: ->
    this.constructor.relations.forEach (relation) =>
      if relation.type == "hasMany"
        Object.defineProperty this, relation.child, {
          get: -> new Proxy.HasMany(this, relation.parent, relation.child)
        }
        #this[relation.child] = new Proxy.HasMany(this, relation.parent, relation.child)

  @extend: (obj) ->
    for key, value of obj when key not in reservedKeywords
      @[key] = value

    obj.extended?.apply(@)
    this

  @include: (obj) ->
    for key, value of obj when key not in reservedKeywords
      # Assign properties to the prototype
      @::[key] = value

    obj.included?.apply(@)
    this

class Proxy
  constructor: (@doc, @parentModel, @childModel) ->
    if Object.isString(@parentModel)
      parentModel = "#{@parentModel}"
      @parentModel = ->
        Poutine.collections[parentModel]
    else
      @parentModel = -> @parentModel
    
    if Object.isString(@childModel)
      childModel = "#{@childModel}"
      @childModel = ->
        Poutine.collections[childModel]
    else
      @childModel = -> @childModel

  create: (fields, callback) ->
    @childModel().create(fields, callback)

class Proxy.HasMany extends Proxy
  constructor: (doc, parentModel, childModel) ->
    super(doc, parentModel, childModel)
    @field ||= @childModel().prototype.collection_name + "_ids"
    @remoteField ||= @doc.constructor.name.toLowerCase() + "_id"
    @childModel().prototype.fields[@remoteField] ||= Array
    @doc.constructor.prototype.fields[@field] ||= ObjectID

    #@childModel().index @remoteField
    #@doc.constructor.index @field

    @doc[@field] ||= []

  create: (fields, callback) ->
    fields[@remoteField] = @doc._id

    super fields, (err, child)=>
      return callback(err) if err
      @doc[@field].push child._id
      @doc.save (err)=>
        return callback(err) if err
        callback(null, child)
  
  push: (model, callback) ->
    oid = ""
    if Object.isString(model)
      oid = new ObjectID(model)
      model = false
    else if model instanceof ObjectID
      oid = model
      model = false
    else
      oid = model._id
    
    @doc[@field].push oid

    saveAll = (child) =>
      Async.parallel {
        parent: (cb) =>
          @doc.save cb
        child: (cb) =>
          child.save cb
      }, (err, models) =>
        return callback(err) if err
        callback(null, models.parent, models.child)

    if model
      model[@remoteField] = @doc._id
      saveAll(model)
    else
      @childModel().find(_id: oid).one (err, child) =>
        return callback(err) if err
        return callback(new Error("No record found with #{oid}")) if !child
        child[@remoteField] = @doc._id
        saveAll(child)
  
  find: (query = {}, options = {})->
    query[@remoteField] = @doc._id
    finder.call @childModel(), query, options



Poutine.Proxy = Proxy

Poutine.ObjectID = ObjectID

module.exports = Poutine