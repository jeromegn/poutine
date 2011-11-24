assert = require("assert")
{ Collection } = require("./collection")
{ Db, Server } = require("mongodb")
{ EventEmitter } = require("events")
{ Pool } = require("generic-pool")
# Cleanup on weak references. Optional for now because I don't know how well the
# node-weak works for other people.
try
  weak = require("weak")
catch ex


# Database configuration.  This is basically a wrapped around the Mongodb
# driver, specifically it's Db object.
class Configuration
  constructor: (name, options = {})->
    @_pool = new Pool
      name:     name
      create:   (callback)=>
        server = new Server(options.host || "127.0.0.1", options.port || 27017)
        client = new Db(name, server, options)
        client.open callback
      destroy:  (connection)->
        connection.close()
      max:      options.pool || 10
      idleTimeoutMillis: 30000

  # Acquire new connection.
  acquire: (callback)->
    @_pool.acquire callback

  # Releases open connection.
  release: (connection)->
    @_pool.release connection



# Represents a logical connection to the database.  Calling mongo() returns a
# new connection that you can use to access the database.
#
# Phytical connections are lazily initialized and pooled.
class Database extends EventEmitter
  constructor: (@_configuration)->
    @_collections = []
    @ObjectID = require("mongodb").BSONPure.ObjectID
    # Tracks how many times we called begin, only release TCP connection
    # when zero.
    @_lock = 0
    if weak
      weak this, ->
        if @_connecting
          @_configuration.release @_connection

  # Use this if you need access to the MongoDB driver's connection object.  It
  # passes, error, a connection and a reference to the end method.  Don't forget
  # to call the end function once done with the connection.
  driver: (callback)->
    assert callback instanceof Function, "This function requires a callback"
    end = @end.bind(this)
    # This is the TCP connection, which we use until it's returned to
    # the pool (see end method).
    if connection = @_connection
      @_lock += 1
      process.nextTick ->
        callback null, connection, end
    else
      this.once "connected", (connection)->
        callback null, connection, end
      this.once "error", callback
      unless @_connecting
        # Pool looks at argument count, so we can't use => here.
        self = this
        self._connecting = true
        @_configuration.acquire (error, connection)->
          self._connecting = false
          if error
            self.emit "error", error
          else
            self._connection = connection
            self._lock += self.listeners("connected").length
            self.emit "connected", connection
    return

  # Call this at the start of a sequence of operations that must all use
  # the same TCP connection.  For example, if you're inserting an object
  # and immediately querying and expect to find it.
  #
  # If called with no arguments, returns a reference to the end method.
  #
  # If called with a callback, passes the end method to the callback.
  #
  # Examples
  #   db.begin (end)->
  #     db.insert "posts", { text: "Find me" }, (err, id)->
  #       db.find("posts", id).one (err, post)->
  #         assert post
  #         end()
  #   
  #   end = db.begin()
  #   db.insert "posts", { text: "Find me" }, (err, id)->
  #     db.find("posts", id).one (err, post)->
  #       assert post
  #       end()
  begin: (callback)->
    @_lock += 1
    if callback
      callback @end.bind(this), this
    else
      return @end.find(this)

  # Call this at the end of a sequence of operations that must all use
  # the same TCP connection.  See the `begin` method for examples.
  #
  # Every flow that calls `begin` once, must also call `end` once.  If
  # you pass this object to another function that calls `begin`, it must
  # also call `end` before passing control back.
  end: ->
    @_lock -= 1 if @_lock > 0
    if @_lock == 0 && @_connection
      @_configuration.release @_connection
      delete @_connection

  # Returns the named collection.
  collection: (name)->
    if name instanceof Function
      model = name
      name = model.collection_name
      assert name, "#{model.constructor}.collection_name is undefined, can't determine which collection to access"
    @_collections[name] ||= new Collection(name, this, model)

  # Finds all objects that match the query selector.
  #
  # If the last argument is a callback, load all matching objects and pass them
  # to callback.  Callback receives error, objects and connection.
  #
  # Without callback, returns a new Scope object.
  #
  # The first argument is the collection name.  Second argument is optional and
  # specifies the query selector.  You can also pass an array of identifier to
  # return specific objects, or a single identifier to return a single object.
  #
  # Third argument is optional and specifies query options (limit, sort, etc).
  # When passing options you must also pass the query selector.
  #
  # Examples:
  #    mongo().find "posts", { author_id: author._id }, limit: 50, (err, posts, db)->
  #      . . .
  #
  #    mongo().find "posts", id, (err, post, db)->
  #      . . .
  #
  #    scope = mongo().find("posts", author_id: author._id)
  #    scope.all (err, posts, db)->
  #      . . .
  find: (name, selector, options, callback)->
    return @collection(name).find(selector, options, callback)

  # Counts unique objects based on query selector, and passes error, count and
  # connection to callback.
  #
  # The first argument is the collection name.  Second argument is optional and
  # specifies the query selector.
  # 
  # Example:
  #   mongo().count "posts", author_id: author._id, (err, count, db)->
  #     . . .
  count: (name, selector, callback)->
    @collection(name).count selector, callback

  # Finds distinct values  based on query selector, and passes error, values and
  # connection to callback.
  #
  # The first argument is the collection name.  Second argument if the field
  # name.  Third argument is optional and specifies the query selector.
  # 
  # Example:
  #   mongo().distinct "posts", "author_id", (err, author_ids, db)->
  #     . . .
  distinct: (name, key, selector, callback)->
    @collection(name).distinct key, selector, callback


exports.Configuration = Configuration
exports.Database      = Database
