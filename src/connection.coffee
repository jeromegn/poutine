Mongo = require("mongodb")
EventEmitter = require("events").EventEmitter
ObjectID = Mongo.pure().ObjectID

class Connection extends EventEmitter
  # Get a connection and call the callback with either error, or null and the
  # open database connection.
  connect: (callback)->
    if @error
      return callback @error
    if @database
      return callback null, @database

    unless @url
      callback new Error("Missing connection URL, must set model.connection.url = <url>")
      return

    if @connecting
      this.once "connected", (database)-> callback null, database
      this.once "error", (error)-> callback error
    else
      @connecting = true
      console.log "Connecting to MongoDB server ..."
      Mongo.connect @url, (@error, @database)=>
        if @error
          console.error "Error while attempting to connect to MongoDB: #{@error.toString()}"
          this.emit "error", @error
          callback @error
          return

        console.log "Connected to MongoDB server"
        this.emit "connected", @database
        callback null, @database

  # New listener added. If we know what the outcome is (db or error) and can
  # fire the event listener.
  newListener: (event, listener)->
    if event == "connected" && @database
      process.nextTick =>
        listener @database
    else if event == "error" && @error
      process.nextTick =>
        listener @error

  # Set connection URL.
  set: (@url)->

  # Without callback, returns a collection. Only makes sense if DB already
  # connected. With callback, waits for datbase connection and calls with
  # error, or null and connection.
  collection: (name, callback)->
    if callback
      this.connect (err, database)->
        if err
          callback err
        else
          callback null, new Mongo.Collection(database, name)
    else if @database
      return new Mongo.Collection(@database, name)
    else
      throw new Error("No database, please call with callback or connect first")

connection = new Connection

connection.on "newListener", connection.newListener

module.exports = connection