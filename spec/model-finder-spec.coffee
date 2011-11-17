vows = require("vows")
assert = require("assert")
{ connect, setup, Model } = require("./helpers")


class Post extends Model
  @collection: "posts"

  @field "title", String
  @field "author_id"
  @field "created_at", Date


vows.describe("Model finder").addBatch

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
        assert.equal posts.length, 2
        for post in posts
          assert.equal post.author_id, 1
      "should return all posts in order": (posts)->
        title = (post.title for post in posts)
        assert.deepEqual title, ["Post 2", "Post 1"]

    "query and callback":
      topic: ->
        Post.find author_id: 1, @callback
      "should return all posts": (posts)->
        assert.equal posts.length, 2
        for post in posts
          assert.equal post.author_id, 1

    "callback only":
      topic: ->
        Post.find @callback
      "should return Post objects": (posts)->
        for post in posts
          assert.instanceOf post, Post
      "should return all posts": (posts)->
        assert.equal posts.length, 3

    "query and options":
      topic: ->
        scope = Post.find({ author_id: 1 }, sort: [["title", -1]])
        scope.all @callback
      "should return all posts": (posts)->
        assert.equal posts.length, 2
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
        assert.equal posts.length, 2
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
        assert.equal posts.length, 3

    "IDs, options and callback":
      topic: ->
        connect().distinct "posts", "_id", (err, ids, db)=>
          Post.find ids, sort: [["title", -1]], @callback
      "should return Post objects": (posts)->
        for post in posts
          assert.instanceOf post, Post
      "should return all posts": (posts)->
        assert.equal posts.length, 3
      "should return all posts in order": (posts)->
        title = (post.title for post in posts)
        assert.deepEqual title, ["Post 3", "Post 2", "Post 1"]

    "IDs and callback":
      topic: ->
        connect().distinct "posts", "_id", (err, ids, db)=>
          Post.find ids, @callback
      "should return all posts": (posts)->
        assert.equal posts.length, 3

    "IDs only":
      topic: ->
        connect().distinct "posts", "_id", (err, ids, db)=>
          scope = Post.find(ids)
          scope.all @callback
      "should return Post objects": (posts)->
        for post in posts
          assert.instanceOf post, Post
      "should return all posts": (posts)->
        assert.equal posts.length, 3

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
      "should return a single post": (post)->
        assert.equal post.title, "Post 1"
        

.addBatch


  # -- Model.where --
  
  "Model.where":
    topic: ->
      setup @callback


.addBatch


  # -- Model finder callbacks --
  
  "load":
    topic: ->
      setup @callback
    
    "one":
      topic: ->
        connect().find(Post).one @callback
      "should load object": (post)->
        assert post instanceof Post
      "should load fields": (post)->
        assert post.title
        assert post.author_id
        assert post.created_at

    "all":
      topic: ->
        connect().find(Post).all @callback
      "should load object": (posts)->
        for post in posts
          assert post instanceof Post
      "should load fields": (posts)->
        for post in posts
          assert post.title
          assert post.author_id
          assert post.created_at

    "undefined fields":
      topic: ->
        class Assign extends Model
          @collection: "posts"
          @field "title"
          @field "created_at"
        connect().collection(Assign).one @callback
      "should not be loaded": (post)->
        assert post.title
        assert post.created_at
        assert !post.author_id

    "custom assignment":
      topic: ->
        class Assign
          @collection: "posts"
          assign: (values)->
            @title = values.title + "!"
        connect().collection(Assign).one @callback
      "should call assign method": (post)->
        assert.equal post.title, "Post 1!"
      "should not set other fields": (post)->
        assert !post.author_id

    "failed assignment":
      topic: ->
        class Failed
          @collection: "posts"
          assign: (values)->
            throw "Fail!"
        connect().collection(Failed).all (error, posts)=>
          @callback null, error
      "should pass error to callback": (error)->
        assert.equal error, "Fail!"

    "onLoad":
      topic: ->
        class Assign
          @collection: "posts"
          @fields:
            title: String
          onLoad: ->
            @loaded = true if @title
        connect().collection(Assign).one @callback
      "should call onLoad method after assigning fields": (post)->
        assert post.loaded

    "failed onLoad":
      topic: ->
        class Failed
          @collection: "posts"
          onLoad: (values)->
            throw "Fail!"
        connect().collection(Failed).all (error, posts)=>
          @callback null, error
      "should pass error to callback": (error)->
        assert.equal error, "Fail!"


.export(module)
