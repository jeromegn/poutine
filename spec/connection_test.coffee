testCase = require('nodeunit').testCase
Poutine = require "../src"

module.exports = testCase
	setUp: (callback) ->
		Poutine.connect "poutine_test", callback

	tearDown: (callback) ->
		Poutine.db.close()
		callback()

	"it should contain a reference to the MongoDB database" : (test) ->
		test.expect 1

		test.ok Poutine.db.state == "connected"

		test.done()