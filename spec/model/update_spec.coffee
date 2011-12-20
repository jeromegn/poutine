{ assert, vows, connect, setup, Model } = require("../helpers")


class Post extends Model
  @collection "posts"

  @field "title", String


vows.describe("Model update").addBatch

  # -- Model.update --

  "Model.update":
    topic: ->
      setup @callback
    

    "single":
      topic: ->
        post = { title: "Post to update" }
        Post.insert post, (err, post)=>
          Post.update {title: post.title}, {$set: {title: "Post updated"}}, @callback
      "should return nothing": (err) ->
        assert !err
      
      "updated document":
        topic: ->
          Post.find({title: "Post updated"}).one @callback
        "should be updated in the database": (post)->
          assert.equal post.title, "Post updated"
    

    "multiple":
      topic: ->
        posts = [
          {title: "test post 1"}
          {title: "test post 2"}
          {title: "test post 3"}
        ]
        Post.insert posts, (err, posts)=>
          Post.update {title: /test\spost/}, {$set: {title: "Multiple updated"}}, {multi: true}, @callback
      "should return nothing": (err) ->
        assert !err
      
      "updated documents":
        topic: ->
          Post.find {title: "Multiple updated"}, @callback
        "should be updated in the database": (posts)->
          assert.lengthOf posts, 3
          assert.equal posts[0].title, "Multiple updated"
    

    "upsert":
      topic: ->
        post = { title: "to be upserted" }
        Post.update post, post, {upsert: true}, @callback
      "should return nothing": (err) ->
        assert !err
      
      "upserted document":
        topic: ->
          Post.find({title: "to be upserted"}).one @callback
        "should exist in the database": (post)->
          assert.equal post.title, "to be upserted"


    "query notation":
      topic: ->
        post = { title: "Post 2 to update" }
        Post.insert post, (err, post)=>
          Post.where({title: post.title}).update {$set: {title: "Post 2 updated"}}, @callback
      "should return nothing": (err) ->
        assert !err
      
      "updated document":
        topic: ->
          Post.find({title: "Post 2 updated"}).one @callback
        "should be updated in the database": (post)->
          assert.equal post.title, "Post 2 updated"



.export(module)
