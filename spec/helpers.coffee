{ connect, configure, Model } = require("../lib/poutine")
{ Db, Server } = require("mongodb")
{ EventEmitter } = require("events")
File = require("fs")
Path = require("path")


# Configure default database.
configure "poutine-test", pool: 10


# Load named fixture from a file in spec/fixtures
loadFixture = (connection, name, callback)->
  File.readFile "#{__dirname}/fixtures/#{name}.json", (error, json)->
    return callback error if error
    try
      records = JSON.parse(json)
    catch error
      callback error
      return

    connection.collection name, (error, collection)->
      return callback error if error
      collection.remove {}, safe: true, (error)->
        return callback error if error
        for record in records
          collection.insert record
        connection.lastError ->
          callback()

# Load the named fixtures from files in spec/fixtures
loadFixtures = (connection, names, callback)->
  if name = names[0]
    loadFixture connection, name, (error)->
      return callback error if error
      loadFixtures connection, names.slice(1), callback
  else
    callback null

# Delete collections and load fixtures.
loading = new EventEmitter
loading.setMaxListeners 0
setup = (callback)->
  loading.once "loaded", callback

  if loading.loaded
    loading.emit "loaded"
    return
  if loading.listeners("loaded").length == 1
    db = new Db("poutine-test", new Server("127.0.0.1", 27017), {})
    db.open (error, connection)->
      if error
        loading.emit "error", error
        return
      names = File.readdirSync("#{__dirname}/fixtures").map((name)-> Path.basename(name, ".json"))
      loadFixtures connection, names, (error)->
        if error
          loading.emit "error", error
        else
          setup.loaded = true
          loading.emit "loaded"


exports.assert = require("assert")
exports.connect = connect
exports.setup = setup
exports.vows = require("vows")
exports.Model = Model
