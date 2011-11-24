{ assert, vows, connect, setup } = require("../helpers")


vows.describe("Collection query").addBatch

  # -- collection().find() --
  
  "find":
    topic: ->
      setup (error)=>
        @callback error, connect().collection("posts")

    "query, options and callback":
      topic: (collection)->
        collection.find { author_id: 1 }, fields: ["title"], @callback
      "should return all matching posts": (posts)->
        assert.equal posts.length, 2
      "should return specified fields": (posts)->
        for post in posts
          assert post.title

    "query and callback":
      topic: (collection)->
        collection.find author_id: 1, @callback
      "should return all matching posts": (posts)->
        assert.equal posts.length, 2

    "query only":
      topic: (collection)->
        collection.find author_id: 1
      "should return a Scope object": (scope)->
        assert scope.where && scope.count
    
    "IDs, options and callback":
      topic: (collection)->
        collection.distinct "_id", (err, ids)=>
          collection.find ids, fields: ["title"], @callback
      "should return all matching posts": (posts)->
        assert.equal posts.length, 3
      "should return specified fields": (posts)->
        for post in posts
          assert post.title
          assert !post.author_id

    "IDs only":
      topic: (collection)->
        collection.distinct "_id", (err, ids)=>
          @callback null, collection.find(ids)
      "should return a Scope": (scope)->
        assert scope.all && scope.one
      "executed":
        topic: (scope)->
          scope.all @callback
        "should find all objects": (posts)->
          assert.equal posts.length, 3

    "ID, options and callback":
      topic: (collection)->
        collection.all (err, posts, db)=>
          id = (post._id for post in posts)[1]
          collection.find id, fields: ["title"], @callback
      "should return a single post": (post)->
        assert.equal post.title, "Post 2"
      "should return specified fields": (post)->
        assert !post.author_id

    "ID and callback":
      topic: (collection)->
        collection.all (err, posts, db)=>
          id = (post._id for post in posts)[1]
          collection.find id, @callback
      "should return a single post": (post)->
        assert.equal post.title, "Post 2"
      "should return all fields": (post)->
        assert post.author_id
        assert post.title

    "ID only":
      topic: (collection)->
        collection.all (err, posts, db)=>
          id = (post._id for post in posts)[1]
          @callback null, collection.find(id)
      "should return a Scope": (scope)->
        assert scope.all && scope.one
      "executed":
        topic: (scope)->
          scope.one @callback
        "should find specific object": (post)->
          assert.equal post.title, "Post 2"


.addBatch
      
  # -- collection().one() --
  
  "one":
    topic: ->
      setup (error)=>
        @callback error, connect().collection("posts")

    "query, options and callback":
      topic: (collection)->
        collection.one { author_id: 1 }, fields: ["author_id"], @callback
      "should return matching post": (post)->
        assert.equal post.author_id, 1
      "should return specified fields": (post)->
        assert post.author_id
        assert !post.title

    "query and callback":
      topic: (collection)->
        collection.one author_id: 1, @callback
      "should return matching post": (post)->
        assert.equal post.author_id, 1

    "no callback":
      topic: (collection)->
        try
          collection.one author_id: 1
          @callback null
        catch ex
          @callback null, ex
      "should fail": (error)->
        assert error instanceof Error
   
    "ID, options and callback":
      topic: (collection)->
        collection.all (err, posts, db)=>
          id = (post._id for post in posts)[1]
          collection.one id, fields: ["title"], @callback
      "should return matching post": (post)->
        assert.equal post.title, "Post 2"
      "should return specified fields": (post)->
        assert post.title
        assert !post.author_id

    "ID and callback":
      topic: (collection)->
        collection.all (err, posts, db)=>
          id = (post._id for post in posts)[1]
          collection.one id, @callback
      "should return a single post": (post)->
        assert.equal post.title, "Post 2"
      "should return all fields": (post)->
        assert post.author_id
        assert post.title


.addBatch

  # -- collection().all() --
  
  "all":
    topic: ->
      setup (error)=>
        @callback error, connect().collection("posts")

    "query, options and callback":
      topic: (collection)->
        collection.all { author_id: 1 }, fields: ["title"], @callback
      "should return all matching posts": (posts)->
        assert.equal posts.length, 2
      "should return specified fields": (posts)->
        for post in posts
          assert post.title

    "query and callback":
      topic: (collection)->
        collection.all author_id: 1, @callback
      "should return all matching posts": (posts)->
        assert.equal posts.length, 2

    "no callback":
      topic: (collection)->
        try
          collection.all author_id: 1
          @callback null
        catch ex
          @callback null, ex
      "should fail": (error)->
        assert error instanceof Error
    
    "IDs, options and callback":
      topic: (collection)->
        collection.distinct "_id", (err, ids)=>
          collection.all ids, fields: ["title"], @callback
      "should return all matching posts": (posts)->
        assert.equal posts.length, 3
      "should return specified fields": (posts)->
        for post in posts
          assert post.title
          assert !post.author_id


.addBatch

  # -- collection().each() --
  
  "each":
    topic: ->
      setup (error)=>
        @callback error, connect().collection("posts")

    "query, options and callback":
      topic: (collection)->
        posts = []
        collection.each { author_id: 1 }, fields: ["title"], (error, post)=>
          if post
            posts.push post
          else
            @callback null, posts
      "should return all matching posts": (posts)->
        assert.equal posts.length, 2
      "should return specified fields": (posts)->
        for post in posts
          assert post.title

    "query and callback":
      topic: (collection)->
        posts = []
        collection.each author_id: 1, (error, post)=>
          if post
            posts.push post
          else
            @callback null, posts
      "should return all matching posts": (posts)->
        assert.equal posts.length, 2

    "no callback":
      topic: (collection)->
        try
          collection.each author_id: 1
          @callback null
        catch ex
          @callback null, ex
      "should fail": (error)->
        assert error instanceof Error
    
    "IDs, options and callback":
      topic: (collection)->
        posts = []
        collection.distinct "_id", (err, ids)=>
          collection.each ids, fields: ["title"], (error, post)=>
            if post
              posts.push post
            else
              @callback null, posts
      "should return all matching posts": (posts)->
        assert.equal posts.length, 3
      "should return specified fields": (posts)->
        for post in posts
          assert post.title
          assert !post.author_id


.addBatch

  # -- collection().count() --
 
  "count":
    topic: ->
      setup (error)=>
        @callback error, connect().collection("posts")

    "query and callback":
      topic: (collection)->
        collection.count author_id: 1, @callback
      "should return number of posts": (count)->
        assert.equal count, 2

    "callback only":
      topic: (collection)->
        collection.count @callback
      "should return number of posts": (count)->
        assert.equal count, 3

    "no callback":
      topic: (collection)->
        try
          collection.count author_id: 1
          @callback null
        catch ex
          @callback null, ex
      "should fail": (error)->
        assert error instanceof Error


.addBatch

  # -- collection().distinct() --
  
  "distinct":
    topic: ->
      setup (error)=>
        @callback error, connect().collection("posts")

    "query and callback":
      topic: (collection)->
        collection.distinct "title", author_id: 1, @callback
      "should return distinct values": (values)->
        assert.equal values.length, 2
        assert.deepEqual values, ["Post 1", "Post 2"]

    "callback only":
      topic: (collection)->
        collection.distinct "title", @callback
      "should return distinct values": (values)->
        assert.equal values.length, 3
        assert.deepEqual values, ["Post 1", "Post 2", "Post 3"]

    "no callback":
      topic: (collection)->
        try
          collection.distinct "title"
          @callback null
        catch ex
          @callback null, ex
      "should fail": (error)->
        assert error instanceof Error


.addBatch

  # -- collection().where() --

  "where":
    topic: ->
      setup (error)=>
        @callback error, connect().collection("posts")

    "no criteria":
      topic: (collection)->
        collection.where()
      "should return a Scope": (scope)->
        assert scope.all && scope.one
      "executed":
        topic: (scope)->
          scope.all @callback
        "should find all objects in the collection": (posts)->
          assert.equal posts.length, 3
          assert.include (post.title for post in posts), "Post 2"

    "with criteria":
      topic: (collection)->
        scope = collection.where(author_id: 1)
        scope.all @callback
      "should find specific objects in the collection": (posts)->
        assert.equal posts.length, 2
        for post in posts
          assert.equal post.author_id, 1

    "nested":
      topic: (collection)->
        scope = collection.where(author_id: 1)
        scope = scope.where(title: "Post 2")
        scope.all @callback
      "should use combined scope": (posts)->
        assert.equal posts.length, 1
        assert.equal posts[0].title, "Post 2"


.export(module)
