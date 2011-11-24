{ assert, vows, connect, setup, Model } = require("../helpers")


class Post extends Model
  @collection "posts"

  @field "title", String
  @field "author_id"
  @field "created_at", Date


vows.describe("Model query").addBatch

  # -- Model.find --
  
  "Model.find":
    topic: ->
      setup @callback

    "query, options and callback":
      topic: ->
        Post.find { author_id: 1 }, sort: [["title", -1]], @callback
      "should return Post objects": (posts)->
        for post in posts
          assert.instanceOf post, Post
      "should return all posts": (posts)->
        assert.lengthOf posts, 2
        for post in posts
          assert.equal post.author_id, 1
      "should return all posts in order": (posts)->
        title = (post.title for post in posts)
        assert.deepEqual title, ["Post 2", "Post 1"]

    "query and callback":
      topic: ->
        Post.find author_id: 1, @callback
      "should return all posts": (posts)->
        assert.lengthOf posts, 2
        for post in posts
          assert.equal post.author_id, 1

    "callback only":
      topic: ->
        Post.find @callback
      "should return Post objects": (posts)->
        for post in posts
          assert.instanceOf post, Post
      "should return all posts": (posts)->
        assert.lengthOf posts, 3

    "query and options":
      topic: ->
        scope = Post.find({ author_id: 1 }, sort: [["title", -1]])
        scope.all @callback
      "should return all posts": (posts)->
        assert.lengthOf posts, 2
        for post in posts
          assert.equal post.author_id, 1
      "should return all posts in order": (posts)->
        title = (post.title for post in posts)
        assert.deepEqual title, ["Post 2", "Post 1"]

    "query only":
      topic: ->
        scope = Post.find(author_id: 1)
        scope.all @callback
      "should return all posts": (posts)->
        assert.lengthOf posts, 2
        for post in posts
          assert.equal post.author_id, 1

    "no arguments":
      topic: ->
        scope = Post.find()
        scope.all @callback
      "should return Post objects": (posts)->
        for post in posts
          assert.instanceOf post, Post
      "should return all posts": (posts)->
        assert.lengthOf posts, 3

    "IDs, options and callback":
      topic: ->
        connect().distinct "posts", "_id", (err, ids, db)=>
          Post.find ids, sort: [["title", -1]], @callback
      "should return Post objects": (posts)->
        for post in posts
          assert.instanceOf post, Post
      "should return all posts": (posts)->
        assert.lengthOf posts, 3
      "should return all posts in order": (posts)->
        title = (post.title for post in posts)
        assert.deepEqual title, ["Post 3", "Post 2", "Post 1"]

    "IDs and callback":
      topic: ->
        connect().distinct "posts", "_id", (err, ids, db)=>
          Post.find ids, @callback
      "should return all posts": (posts)->
        assert.lengthOf posts, 3

    "IDs only":
      topic: ->
        connect().distinct "posts", "_id", (err, ids, db)=>
          scope = Post.find(ids)
          scope.all @callback
      "should return Post objects": (posts)->
        for post in posts
          assert.instanceOf post, Post
      "should return all posts": (posts)->
        assert.lengthOf posts, 3

    "ID, options and callback":
      topic: ->
        connect().distinct "posts", "_id", (err, ids, db)=>
          Post.find ids[0], fields: ["title"], @callback
      "should return Post object": (post)->
        assert.instanceOf post, Post
      "should return a single post": (post)->
        assert.equal post.title, "Post 1"
      "should return specified fields": (post)->
        assert !post.author_id

    "ID and callback":
      topic: ->
        connect().distinct "posts", "_id", (err, ids, db)=>
          Post.find ids[0], @callback
      "should return a single post": (post)->
        assert.equal post.title, "Post 1"

    "ID and options":
      topic: ->
        connect().distinct "posts", "_id", (err, ids, db)=>
          scope = Post.find(ids[0], fields: ["title"])
          scope.one @callback
      "should return a single post": (post)->
        assert.equal post.title, "Post 1"
      "should return specified fields": (post)->
        assert !post.author_id

    "ID only":
      topic: ->
        connect().distinct "posts", "_id", (err, ids, db)=>
          scope = Post.find(ids[0])
          scope.one @callback
      "should return Post object": (post)->
        assert.instanceOf post, Post
      "should return the selected post": (post)->
        assert.equal post.title, "Post 1"
        

.addBatch


  # -- Model.where --
  
  "Model.where":
    topic: ->
      setup =>
        @callback null, Post.where(title: "Post 2")
    "should return scope": (scope)->
      assert scope.where
      assert scope.desc
    "query":
      topic: (scope)->
        scope.all @callback
      "should return only selected posts": (posts)->
        assert.lengthOf posts, 1
        assert.equal posts[0].title, "Post 2"


.addBatch


  # -- Model loading --

  "default accessor":
    topic: ->
      setup =>
        Post.find(title: "Post 2").one @callback
    "should return field value": (post)->
      assert.equal post.title, "Post 2"
    "should set field value": (post)->
      post.title = "modified"
      assert.equal post.title, "modified"

  "custom accessor":
    topic: ->
      setup =>
        class Custom extends Model
          @collection "posts"
          @field "title"
          @set "title", (title)->
            @x_title = "!#{title}!"
        Custom.find(title: "Post 2").one @callback

        # Proves that setting post.title does set post.x_title
        post = new Custom
        post.title = "Post 2"
        assert.equal post.x_title, "!Post 2!"
    "should not be used to load field value": (post)->
      assert.equal post.title, "Post 2"
      assert !post.x_title

  "some fields":
    topic: ->
      setup =>
        class Missing extends Model
          @collection "posts"
          @field "title"
          @field "created_at"
        Missing.find(title: "Post 2").one @callback
    "should load defined fields": (post)->
      assert post.title
      assert post._.created_at
    "should not load undefined fiels": (post)->
      assert !post.author_id
      assert !post._.category

  "afterLoad":
    topic: ->
      setup =>
        class AfterLoad extends Model
          @collection "posts"
          @field "title"
          afterLoad: ->
            @loaded = @title
        AfterLoad.find(title: "Post 2").one @callback
    "should call onLoad method after assigning fields": (post)->
      assert.equal post.loaded, "Post 2"
  
  "failed afterLoad":
    topic: ->
      setup =>
        class Failed extends Model
          @collection "posts"
          @field "title"
          afterLoad: ->
            throw "Fail!"
        Failed.find(title: "Post 2").one (error)=>
          @callback null, error
    "should pass error to callback": (error)->
      assert.equal error, "Fail!"


.export(module)
