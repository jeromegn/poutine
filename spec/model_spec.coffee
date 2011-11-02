# testCase = require("nodeunit").testCase
vows = require "vows"
assert = require "assert"
Poutine = require "../src"

Poutine.connection.url = "mongodb://localhost:27017/poutine-test"

class User extends Poutine.Model
  fields :
    name  : String
    email : String 

User.index 'email', unique: true

vows.describe("Model").addBatch(
  
  "once a connection is established":
    topic: ->
      Poutine.connect this.callback
      return

    "creating a new model instance":
      topic: new User(name: "Jerome", email: "test@test.com")

      "should have populated fields": (user)->
        assert.equal user.name, "Jerome"
  
      "should not exist in the database": (user) ->
        assert.equal user.isNewRecord(), true
    
      "saving an instance":
        topic: (user) ->
          user.save this.callback
          return
        "should exist in the database": (user)->
          assert.equal user.isNewRecord(), false
      
        "and then searching for it with its _id":
          topic: (savedUser)->
            User.find savedUser._id, (err, user) =>
              this.callback(err, user, savedUser)
            return
          
          "should not err": (err, user)->
            assert.isNull err
          
          "should return the same instance": (err, user, savedUser) ->
            assert.equal user._id.toString(), savedUser._id.toString()
        
        "and then deleting it":
          topic: (err, user) ->
            user.remove (err) =>
              this.callback err, user
            return
          
          "should not err": (err, oldUser) ->
            assert.isNull err
          
          "and then searching for it in vain":
            topic: (err, oldUser) ->
              User.find oldUser._id, this.callback
              return
            
            "should not err": (err, user) ->
              assert.isNull err
            
            "should not find any record": (err, user) ->
              assert.isNull user
    
    teardown: ->
      console.log "TEARING DOWN"
      Poutine.connection.database.dropDatabase (err) ->
        if (err) then console.log err
        Poutine.connection.database.close()

).export(module)