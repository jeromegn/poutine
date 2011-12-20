{ assert, vows, connect, setup, Model } = require("../helpers")


class Post extends Model
  @collection "posts"

  @field "title", String


vows.describe("Model update").addBatch

  # -- Model.update --

  "Model.update":
    topic: ->
      setup @callback
    
    "updating":
      "single":
        topic: ->
          post = { title: "Post to update" }
          Post.insert post, (err, post)=>
            Post.update {title: post.title}, {$set: {title: "Post updated"}}, =>
              Post.find({title: "Post updated"}).one @callback
          return
        "should be updated in the database": (post)->
          assert.equal post.title, "Post updated"
      

      "multiple":
        "shorthand":
          topic: ->
            posts = [
              {title: "test post 1"}
              {title: "test post 2"}
              {title: "test post 3"}
            ]
            Post.insert posts, (err, posts)=>
              Post.update_all {$or: posts}, {$set: {title: "Multiple updated"}}, =>
                Post.find {title: "Multiple updated"}, @callback
            return
          "should be updated in the database": (posts)->
            assert.lengthOf posts, 3
            assert.equal posts[0].title, "Multiple updated"
        "normal":
          topic: ->
            posts = [
              {title: "test post 4"}
              {title: "test post 5"}
            ]
            Post.insert posts, (err, posts)=>
              Post.update {title: /test\spost\s(4|5)/}, {$set: {title: "Multiple updated 2"}}, {multi: true}, =>
                Post.find {title: "Multiple updated 2"}, @callback
            return
          "should be updated in the database": (posts)->
            assert.lengthOf posts, 2
            assert.equal posts[0].title, "Multiple updated 2"
    

    "updating w/ scope":
      "single":
        topic: ->
          post = { title: "Post 2 to update" }
          Post.insert post, (err, post)=>
            Post.where({title: post.title}).update {$set: {title: "Post 2 updated"}}, =>
              Post.find({title: "Post 2 updated"}).all @callback
          return
        "should be updated in the database": (posts)->
          assert.lengthOf posts, 1
          assert.equal posts[0].title, "Post 2 updated"
      
      "multiple":
        topic: ->
          posts = [
            { title: "Post 3 to update" }
            { title: "Post 4 to update" }
          ]
          Post.insert posts, (err, posts)=>
            Post.where($or: posts).update_all {$set: {title: "Dot notation multi updated"}}, =>
              Post.where({title: "Dot notation multi updated"}).all @callback
          return
        "should be updated in the database": (posts)->
          assert.lengthOf posts, 2
          assert.equal posts[0].title, "Dot notation multi updated"


  "Model.upsert":
    "shorthand":
      topic: ->
        post = { title: "to be upserted" }
        Post.upsert post, post, =>
          Post.find({title: "to be upserted"}).one @callback
        return
      "should exist in the database": (post)->
        assert.equal post.title, "to be upserted"
    "normal":
      topic: ->
        post = { title: "to be upserted 2" }
        Post.update post, post, {upsert: true}, =>
          Post.find({title: "to be upserted 2"}).one @callback
        return
      "should exist in the database": (post)->
        assert.equal post.title, "to be upserted 2"


.export(module)
