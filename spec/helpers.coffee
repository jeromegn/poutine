{ connect, configure } = require("../lib/poutine")

# Configure default database.
configure "poutine-test", pool: 1


{ Db, Server } = require("mongodb")

exports.setup = (fixtures, callback)->
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
          callback error

    nextCollection Object.keys(fixtures)


exports.connect = connect
