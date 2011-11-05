vows = require("vows")
assert = require("assert")
{Poutine} = require("./helpers")

random = -> Math.random().toString().substr(3)

# Fields and collection_name gotta be set topmost
# before the extend and include methods are called
class User extends Poutine.Model
  collection_name: "users_#{random()}"
  fields:
    name: String
    email: String

  @extend Poutine.Collection
  @include Poutine.Document

  @index 'email', unique: true

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
            console.log arguments
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


).export(module)