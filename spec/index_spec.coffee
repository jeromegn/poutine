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

vows.describe("Indexes").addBatch(
    
  "already added indexes to a model":
    topic: ->
      User.index 'email', unique: true, (err, index)=>
        User.collection (err, collection) =>
          collection.indexInformation this.callback
      return
    
    "should create indexes in the database": (err, indexes)->
      assert.include indexes, "email_1"

).export(module)