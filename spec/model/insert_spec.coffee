{ assert, vows, connect, setup, Model } = require("../helpers")


class Post extends Model
  @collection "posts"

  @field "title", String
  @field "author_id"
  @field "category", String
  @field "created_at", Date


vows.describe("Model insert").addBatch

  # -- Model.insert --

  "Model.insert":
    topic: ->
      setup @callback

    "POJO":
      "single":
        "no callback":
          topic: ->
            result = Post.insert(title: "Insert 3.1")
            return result || "nothing"
          "should return nothing": (result)->
            assert.equal result, "nothing"
          "new document":
            topic: ->
              Post.find title: "Insert 3.1", @callback
            "should exist in database": (posts)->
              assert.equal posts[0].title, "Insert 3.1"

        "with callback":
          topic: ->
            Post.insert title: "Insert 3.2", @callback
          "should pass document to callback": (post)->
            assert.equal post.title, "Insert 3.2"
          "should pass a POJO to callback": (post)->
            assert !(post instanceof Post)
          "should set document ID": (post)->
            assert post._id
          "new document":
            topic: (post)->
              Post.find post._id, @callback
            "should exist in database": (post)->
              assert.equal post.title, "Insert 3.2"

      "multiple":
        "no callback":
          topic: ->
            result = Post.insert([{ title: "Insert 3.3", category: "foo" }, { title: "Insert 3.3", category: "bar" }])
            return result || "nothing"
          "should return nothing": (result)->
            assert.equal result, "nothing"
          "new documents":
            topic: ->
              Post.find title: "Insert 3.3", @callback
            "should exist in database": (posts)->
              assert.lengthOf posts, 2
              categories = (post.category for post in posts).join(" ")
              assert.equal categories, "foo bar"

        "with callback":
          topic: ->
            Post.insert [{ title: "Insert 3.4", category: "foo" }, { title: "Insert 3.4", category: "bar" }], @callback
          "should pass documents to callback": (posts)->
            for post in posts
              assert.equal post.title, "Insert 3.4"
          "should pass POJOs to callback": (posts)->
            for post in posts
              assert !(post instanceof Post)
          "should set document ID": (posts)->
            for post in posts
              assert post._id
          "new documents":
            topic: (posts)->
              ids = (post._id for post in posts)
              Post.find ids, @callback
            "should exist in database": (posts)->
              assert.lengthOf posts, 2
              categories = (post.category for post in posts).join(" ")
              assert.equal categories, "foo bar"


    "Model":
      "no callback":
        topic: ->
          post = new Post(title: "Insert 3.5")
          result = Post.insert(post)
          return result || "nothing"
        "should return nothing": (result)->
          assert.equal result, "nothing"
        "new document":
          topic: ->
            Post.find title: "Insert 3.5", @callback
          "should exist in database": (posts)->
            assert.equal posts[0].title, "Insert 3.5"

      "with callback":
        topic: (post)->
          post = new Post(title: "Insert 3.6")
          Post.insert post, @callback
        "should pass document to callback": (post)->
          assert.equal post.title, "Insert 3.6"
        "should pass a model to callback": (post)->
          assert.instanceOf post, Post
        "should set document ID": (post)->
          assert post._id
        "new document":
          topic: (post)->
            Post.find post._id, @callback
          "should exist in database": (post)->
            assert.equal post.title, "Insert 3.6"

      "multiple":
        "no callback":
          topic: ->
            posts = [new Post( title: "Insert 3.7", category: "foo" ), new Post( title: "Insert 3.7", category: "bar" )]
            result = Post.insert(posts)
            return result || "nothing"
          "should return nothing": (result)->
            assert.equal result, "nothing"
          "new documents":
            topic: ->
              Post.find title: "Insert 3.7", @callback
            "should exist in database": (posts)->
              assert.lengthOf posts, 2
              categories = (post.category for post in posts).join(" ")
              assert.equal categories, "foo bar"

        "with callback":
          topic: ->
            posts = [new Post( title: "Insert 3.8", category: "foo" ), new Post( title: "Insert 3.8", category: "bar" )]
            Post.insert posts, @callback
          "should pass documents to callback": (posts)->
            for post in posts
              assert.equal post.title, "Insert 3.8"
          "should pass models to callback": (posts)->
            for post in posts
              assert.instanceOf post, Post
          "should set document ID": (posts)->
            for post in posts
              assert post._id
          "new documents":
            topic: (posts)->
              ids = (post._id for post in posts)
              Post.find ids, @callback
            "should exist in database": (posts)->
              assert.lengthOf posts, 2
              categories = (post.category for post in posts).join(" ")
              assert.equal categories, "foo bar"


.export(module)
