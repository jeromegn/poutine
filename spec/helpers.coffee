{ connect, configure, Model } = require("../lib/poutine")
{ Db, Server } = require("mongodb")
File = require("fs")
vows = require("vows")


vows.options.error = false


# Configure default database.
configure "poutine-test", pool: 10


fixtures_loaded = false
# Load fixtures and call callback.
exports.setup = (callback)->
  if fixtures_loaded
    callback()
    return

  File.readFile "#{__dirname}/fixtures.json", (error, json)->
    return callback error if error
    try
      fixtures = JSON.parse(json)
    catch error
      callback error
      return

    db = new Db("poutine-test", new Server("127.0.0.1", 27017), {})
    db.open (error, connection)->
      return callback error if error

      nextRecord = (collection, collections, records)->
        record = records[0]
        if record
          collection.insert record, (error, docs)->
            return callback error if error
            nextRecord collection, collections, records.slice(1)
        else
          nextCollection collections

      nextCollection = (names)->
        name = names[0]
        if name
          connection.collection name, (error, collection)->
            return callback error if error
            collection.remove {}, safe: true, (error, callback)->
              return callback error if error
              nextRecord collection, names.slice(1), fixtures[name]
        else
          db.lastError (error)->
            fixtures_loaded = !error
            callback error

      nextCollection Object.keys(fixtures)



exports.connect = connect
exports.Model = Model
