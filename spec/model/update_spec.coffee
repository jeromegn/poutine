{ assert, vows, connect, setup, Model } = require("../helpers")


class Post extends Model
  @collection "posts"

  @field "title", String


vows.describe("Model update").addBatch

  # -- Model.update --

  "Model.update":
    topic: ->
      setup @callback
    
    "POJO":
      "single":
        topic: ->
          posts = [
            {title: "Update 1"}
            {title: "Update 1"}
          ]
          Post.insert posts, {safe: true}, @callback

        "no callback":
          topic: ->
            update = Post.update {title: "Update 1"}, {title: "Update 1.1"}
            return update || "nothing"
          "should return nothing": (update)->
            assert.equal update, "nothing"
          "updated document":
            topic: ->
              Post.find title: "Update 1.1", @callback
            "should exist in database": (posts)->
              assert.equal posts[0].title, "Update 1.1"

        "with callback":
          topic: ->
            Post.update {title: "Update 1"}, {$set: {title: "Update 1.2"}}, {safe: true}, @callback
          "should pass the number of updated documents to the callback": (updated)->
            assert.equal updated, 1
          "updated document":
            topic: ->
              Post.find title: "Update 1.2", @callback
            "should exist in database": (posts)->
              assert.equal posts[0].title, "Update 1.2"
      

      "multiple":
        "long form":
          topic: ->
            posts = [
              {title: "Update 2"}
              {title: "Update 2"}
              {title: "Update 3"}
              {title: "Update 3"}
            ]
            Post.insert posts, {safe: true}, @callback

          "no callback":
            topic: (posts) ->
              update = Post.update {title: "Update 2"}, {title: "Update 2.1"}, {multi: true}
              return update || "nothing"
            "should return nothing": (update)->
              assert.equal update, "nothing"
            "updated document":
              topic: ->
                Post.find title: "Update 2.1", @callback
              "should exist in database": (posts)->
                assert.lengthOf posts, 2
                posts.forEach (post) ->
                  assert.equal post.title, "Update 2.1"
          
          "with callback":
            topic: ->
              Post.update {title: "Update 3"}, {$set: {title: "Update 3.1"}}, {safe: true, multi: true}, @callback
            "should pass the number of updated documents to the callback": (updated)->
              assert.equal updated, 2
            "updated document":
              topic: ->
                Post.find title: "Update 3.1", @callback
              "should exist in database": (posts)->
                assert.lengthOf posts, 2
                posts.forEach (post) ->
                  assert.equal post.title, "Update 3.1"
        

        "with convenience method":
          topic: ->
            posts = [
              {title: "Update 4"}
              {title: "Update 4"}
              {title: "Update 5"}
              {title: "Update 5"}
            ]
            Post.insert posts, {safe: true}, @callback

          "no callback":
            topic: (posts) ->
              update = Post.update_all {title: "Update 4"}, {title: "Update 4.1"}
              return update || "nothing"
            "should return nothing": (update)->
              assert.equal update, "nothing"
            "updated document":
              topic: ->
                Post.find title: "Update 4.1", @callback
              "should exist in database": (posts)->
                assert.lengthOf posts, 2
                posts.forEach (post) ->
                  assert.equal post.title, "Update 4.1"
          
          "with callback":
            topic: ->
              Post.update_all {title: "Update 5"}, {$set: {title: "Update 5.1"}}, {safe: true}, @callback
            "should pass the number of updated documents to the callback": (updated)->
              assert.equal updated, 2
            "updated document":
              topic: ->
                Post.find title: "Update 5.1", @callback
              "should exist in database": (posts)->
                assert.lengthOf posts, 2
                posts.forEach (post) ->
                  assert.equal post.title, "Update 5.1"
    
    "Model":
      "single":
        topic: ->
          @posts = [
            new Post(title: "Update 6")
            new Post(title: "Update 6")
          ]
          Post.insert @posts, {safe: true}, @callback

        "no callback":
          topic: ->
            update = Post.update @posts[0], {$set: {title: "Update 6.1"}}
            return update || "nothing"
          "should return nothing": (update)->
            console.log @posts[0]
            assert.equal update, "nothing"
          "updated document":
            topic: ->
              Post.find title: "Update 6.1", @callback
            "should exist in database": (posts)->
              assert.equal posts[0].title, "Update 6.1"

        "with callback":
          topic: ->
            Post.update @posts[1], {$set: {title: "Update 6.2"}}, {safe: true}, @callback
          "should pass the number of updated documents to the callback": (updated)->
            assert.equal updated, 1
          "updated document":
            topic: ->
              Post.find title: "Update 6.2", @callback
            "should exist in database": (posts)->
              assert.equal posts[0].title, "Update 6.2"
        

  ###
  "Model.upsert":
    "shorthand":
      topic: ->
        post = { title: "to be upserted, short form" }
        Post.upsert post, post, {safe: true}, @callback
      
      "when querying for it":
        topic: ->
          Post.find(title: "to be upserted, short form").one @callback
        "should exist in the database": (post)->
          assert.equal post.title, "to be upserted, short form"
    
    "normal":
      topic: ->
        post = { title: "to be upserted, long form" }
        Post.update post, post, {upsert: true, safe: true}, @callback
      
      "when querying for it":
        topic: ->
          Post.find(title: "to be upserted, long form").one @callback
        "should exist in the database": (post)->
          assert.equal post.title, "to be upserted, long form"
  ###


.export(module)
