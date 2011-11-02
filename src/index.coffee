require "sugar"
MongoDB = require "mongodb"
ObjectID = MongoDB.pure().ObjectID

connection = require "./connection"

Poutine = {}

Poutine.collection = connection.collection.bind(connection)
Poutine.connect = connection.connect.bind(connection)
Poutine.connection = connection

Poutine.Model = require "./model"

Poutine.ObjectID = ObjectID

module.exports = Poutine