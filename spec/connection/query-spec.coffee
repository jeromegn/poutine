{ assert, vows, connect, setup } = require("../helpers")


vows.describe("Connection query").addBatch

  # -- connect().find --

  "find":
    topic: ->
      setup @callback
    "query, options and callback":
      topic: ->
        connect().find "posts", { author_id: 1 }, sort: [["title", -1]], @callback
      "should return all posts": (posts)->
        assert.equal posts.length, 2
        for post in posts
          assert.equal post.author_id, 1
      "should return all posts in order": (posts)->
        title = (post.title for post in posts)
        assert.deepEqual title, ["Post 2", "Post 1"]

    "query and callback":
      topic: ->
        connect().find "posts", author_id: 1, @callback
      "should return all posts": (posts)->
        assert.equal posts.length, 2
        for post in posts
          assert.equal post.author_id, 1

    "callback only":
      topic: ->
        connect().find "posts", @callback
      "should return all posts": (posts)->
        assert.equal posts.length, 3

    "query and options":
      topic: ->
        scope = connect().find("posts", { author_id: 1 }, sort: [["title", -1]])
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
        scope = connect().find("posts", author_id: 1)
        scope.all @callback
      "should return all posts": (posts)->
        assert.equal posts.length, 2
        for post in posts
          assert.equal post.author_id, 1

    "no arguments":
      topic: ->
        scope = connect().find("posts")
        scope.all @callback
      "should return all posts": (posts)->
        assert.equal posts.length, 3

    "IDs, options and callback":
      topic: ->
        connect().distinct "posts", "_id", (err, ids, db)=>
          db.find "posts", ids, sort: [["title", -1]], @callback
      "should return all posts": (posts)->
        assert.equal posts.length, 3
      "should return all posts in order": (posts)->
        title = (post.title for post in posts)
        assert.deepEqual title, ["Post 3", "Post 2", "Post 1"]

    "IDs and callback":
      topic: ->
        connect().distinct "posts", "_id", (err, ids, db)=>
          db.find "posts", ids, @callback
      "should return all posts": (posts)->
        assert.equal posts.length, 3

    "IDs only":
      topic: ->
        connect().distinct "posts", "_id", (err, ids, db)=>
          scope = connect().find("posts", ids)
          scope.all @callback
      "should return all posts": (posts)->
        assert.equal posts.length, 3

    "ID, options and callback":
      topic: ->
        connect().find "posts", (err, posts, db)=>
          id = (post._id for post in posts)[0]
          connect().find "posts", id, fields: ["title"], @callback
      "should return a single post": (post)->
        assert.equal post.title, "Post 1"
      "should return specified fields": (post)->
        assert !post.author_id

    "ID and callback":
      topic: ->
        connect().find "posts", (err, posts, db)=>
          id = (post._id for post in posts)[0]
          connect().find "posts", id, @callback
      "should return a single post": (post)->
        assert.equal post.title, "Post 1"

    "ID and options":
      topic: ->
        connect().find "posts", (err, posts, db)=>
          id = (post._id for post in posts)[0]
          scope = connect().find("posts", id, fields: ["title"])
          scope.one @callback
      "should return a single post": (post)->
        assert.equal post.title, "Post 1"
      "should return specified fields": (post)->
        assert !post.author_id

    "ID only":
      topic: ->
        connect().find "posts", (err, posts, db)=>
          id = (post._id for post in posts)[0]
          scope = connect().find("posts", id)
          scope.one @callback
      "should return a single post": (post)->
        assert.equal post.title, "Post 1"


.addBatch

  # -- connect().count() --

  "count":
    topic: ->
      setup @callback
    "query and callback":
      topic: ->
        connect().count "posts", author_id: 1, @callback
      "should return number of posts": (count)->
        assert.equal count, 2

    "callback only":
      topic: ->
        connect().count "posts", @callback
      "should return number of posts": (count)->
        assert.equal count, 3

    "no callback":
      topic: ->
        try
          connect().count "posts", { author_id: 1}
          @callback null
        catch ex
          @callback null, ex
      "should fail": (error)->
        assert error instanceof Error


.addBatch

  # -- connect().distinct() --
      
  "distinct":
    topic: ->
      setup @callback
    "query and callback":
      topic: ->
        connect().distinct "posts", "title", author_id: 1, @callback
      "should return distinct values": (values)->
        assert.equal values.length, 2
        assert.deepEqual values, ["Post 1", "Post 2"]

    "callback only":
      topic: ->
        connect().distinct "posts", "title", @callback
      "should return distinct values": (values)->
        assert.equal values.length, 3
        assert.deepEqual values, ["Post 1", "Post 2", "Post 3"]

    "no callback":
      topic: ->
        try
          connect().distinct "posts", "title"
          @callback null
        catch ex
          @callback null, ex
      "should fail": (error)->
        assert error instanceof Error



.export(module)
