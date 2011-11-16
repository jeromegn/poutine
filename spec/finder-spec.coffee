vows = require("vows")
assert = require("assert")
{ connect, setup, Model } = require("./helpers")


class Post extends Model
  @collection: "posts"


vows.describe("Queries").addBatch

  "new database":
    topic: ->
      fixtures =
        posts: [
          { title: "Test 1", author_id: 1, category: "low", created_at: new Date },
          { title: "Test 2", author_id: 1, category: "high", created_at: new Date },
          { title: "Test 3", author_id: 2, category: "low", created_at: new Date }
        ]
      setup fixtures, @callback

    # -- Test connection methods --

    "connection":
    
      # -- Test connect().find() --
      
      "find":
        "query, options and callback":
          topic: ->
            connect().find "posts", { author_id: 1 }, sort: [["title", -1]], @callback
          "should return all posts": (posts)->
            assert.equal posts.length, 2
            for post in posts
              assert.equal post.author_id, 1
          "should return all posts in order": (posts)->
            title = (post.title for post in posts)
            assert.deepEqual title, ["Test 2", "Test 1"]
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
            assert.deepEqual title, ["Test 2", "Test 1"]
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
            connect().find "posts", (err, posts, db)=>
              ids = (post._id for post in posts)
              db.find "posts", ids, sort: [["title", -1]], @callback
          "should return all posts": (posts)->
            assert.equal posts.length, 3
          "should return all posts in order": (posts)->
            title = (post.title for post in posts)
            assert.deepEqual title, ["Test 3", "Test 2", "Test 1"]
        "IDs and callback":
          topic: ->
            connect().find "posts", (err, posts, db)=>
              ids = (post._id for post in posts)
              db.find "posts", ids, @callback
          "should return all posts": (posts)->
            assert.equal posts.length, 3
        "IDs only":
          topic: ->
            connect().find "posts", (err, posts, db)=>
              ids = (post._id for post in posts)
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
            assert.equal post.title, "Test 1"
          "should return specified fields": (post)->
            assert.isUndefined post.author_id
        "ID and callback":
          topic: ->
            connect().find "posts", (err, posts, db)=>
              id = (post._id for post in posts)[0]
              connect().find "posts", id, @callback
          "should return a single post": (post)->
            assert.equal post.title, "Test 1"
        "ID and options":
          topic: ->
            connect().find "posts", (err, posts, db)=>
              id = (post._id for post in posts)[0]
              scope = connect().find("posts", id, fields: ["title"])
              scope.one @callback
          "should return a single post": (post)->
            assert.equal post.title, "Test 1"
          "should return specified fields": (post)->
            assert.isUndefined post.author_id
        "ID only":
          topic: ->
            connect().find "posts", (err, posts, db)=>
              id = (post._id for post in posts)[0]
              scope = connect().find("posts", id)
              scope.one @callback
          "should return a single post": (post)->
            assert.equal post.title, "Test 1"


      # -- Test connect().find() --

      "count":
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


      # -- Test connect().distinct() --
      
      "distinct":
        "query and callback":
          topic: ->
            connect().distinct "posts", "title", author_id: 1, @callback
          "should return distinct values": (values)->
            assert.equal values.length, 2
            assert.deepEqual values, ["Test 1", "Test 2"]
        "callback only":
          topic: ->
            connect().distinct "posts", "title", @callback
          "should return distinct values": (values)->
            assert.equal values.length, 3
            assert.deepEqual values, ["Test 1", "Test 2", "Test 3"]
        "no callback":
          topic: ->
            try
              connect().distinct "posts", "title"
              @callback null
            catch ex
              @callback null, ex
          "should fail": (error)->
            assert error instanceof Error


    # -- Test collection methods --


    "collection":

      # -- Test colletion().find() --
      
      "find":
        topic: ->
          connect().collection("posts")
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
        "query and callback":
          topic: (collection)->
            collection.find author_id: 1
          "should return a Scope object": (scope)->
            assert scope.where && scope.count
        
        "IDs, options and callback":
          topic: (collection)->
            collection.all (err, posts, db)=>
              ids = (post._id for post in posts)
              collection.find ids, fields: ["title"], @callback
          "should return all matching posts": (posts)->
            assert.equal posts.length, 3
          "should return specified fields": (posts)->
            for post in posts
              assert post.title
              assert.isUndefined post.author_id
        "IDs only":
          topic: (collection)->
            collection.all (err, posts, db)=>
              ids = (post._id for post in posts)
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
            assert.equal post.title, "Test 2"
          "should return specified fields": (post)->
            assert.isUndefined post.author_id
        "ID and callback":
          topic: (collection)->
            collection.all (err, posts, db)=>
              id = (post._id for post in posts)[1]
              collection.find id, @callback
          "should return a single post": (post)->
            assert.equal post.title, "Test 2"
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
              assert.equal post.title, "Test 2"

      
      # -- Test colletion().count() --
     
      "count":
        topic: ->
          connect().collection("posts")
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


      # -- Test collection().distinct() --
      
      "distinct":
        topic: ->
          connect().collection("posts")
        "query and callback":
          topic: (collection)->
            collection.distinct "title", author_id: 1, @callback
          "should return distinct values": (values)->
            assert.equal values.length, 2
            assert.deepEqual values, ["Test 1", "Test 2"]
        "callback only":
          topic: (collection)->
            collection.distinct "title", @callback
          "should return distinct values": (values)->
            assert.equal values.length, 3
            assert.deepEqual values, ["Test 1", "Test 2", "Test 3"]
        "no callback":
          topic: (collection)->
            try
              collection.distinct "title"
              @callback null
            catch ex
              @callback null, ex
          "should fail": (error)->
            assert error instanceof Error


      # -- Test collection().where() --
    
      "where":
        topic: ->
          connect().collection("posts")
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
              assert.include (post.title for post in posts), "Test 2"
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
            scope = scope.where(title: "Test 2")
            scope.all @callback
          "should use combined scope": (posts)->
            assert.equal posts.length, 1
            assert.equal posts[0].title, "Test 2"


      # -- Test Scope fields, asc, desc, limit and skip --
     
      "scope":
        "fields":
          topic: (scope)->
            connect().find("posts")
          "no argument":
            topic: (scope)->
              scope.fields().all @callback
            "should return no fields": (posts)->
              for post in posts
                assert.equal Object.keys(post).length, 1
          "single argument":
            topic: (scope)->
              scope.fields("title").all @callback
            "should return only specified field": (posts)->
              for post in posts
                assert post.title
                assert.isUndefined post.author_id
                assert.isUndefined post.created_at
          "multiple arguments":
            topic: (scope)->
              scope.fields("title", "author_id").all @callback
            "should return only specified field": (posts)->
              for post in posts
                assert post.title
                assert post.author_id
                assert.isUndefined post.created_at
          "array arguments":
            topic: (scope)->
              scope.fields(["title", "created_at"]).all @callback
            "should return only specified field": (posts)->
              for post in posts
                assert post.title
                assert.isUndefined post.author_id
                assert post.created_at

        "asc":
          topic: (scope)->
            connect().find("posts")
          "no argument":
            topic: (scope)->
              scope.asc().all @callback
            "should return in natural order": (posts)->
              titles = (post.title for post in posts)
              assert.deepEqual titles, ["Test 1", "Test 2", "Test 3"]
          "single argument":
            topic: (scope)->
              scope.asc("category").all @callback
            "should return in specified order": (posts)->
              titles = (post.title for post in posts)
              assert.deepEqual titles, ["Test 2", "Test 1", "Test 3"]
          "multiple arguments":
            topic: (scope)->
              scope.asc("category", "title").all @callback
            "should return in specified order": (posts)->
              titles = (post.title for post in posts)
              assert.deepEqual titles, ["Test 2", "Test 1", "Test 3"]
          "array arguments":
            topic: (scope)->
              scope.asc(["category", "title"]).all @callback
            "should return in specified order": (posts)->
              titles = (post.title for post in posts)
              assert.deepEqual titles, ["Test 2", "Test 1", "Test 3"]

        "desc":
          topic: (scope)->
            connect().find("posts")
          "no argument":
            topic: (scope)->
              scope.desc().all @callback
            "should return in natural order": (posts)->
              titles = (post.title for post in posts)
              assert.deepEqual titles, ["Test 1", "Test 2", "Test 3"]
          "single argument":
            topic: (scope)->
              scope.desc("title").all @callback
            "should return in specified order": (posts)->
              titles = (post.title for post in posts)
              assert.deepEqual titles, ["Test 3", "Test 2", "Test 1"]
          "multiple arguments":
            topic: (scope)->
              scope.desc("title", "category").all @callback
            "should return in specified order": (posts)->
              titles = (post.title for post in posts)
              assert.deepEqual titles, ["Test 3", "Test 2", "Test 1"]
          "array arguments":
            topic: (scope)->
              scope.desc(["title", "category"]).all @callback
            "should return in specified order": (posts)->
              titles = (post.title for post in posts)
              assert.deepEqual titles, ["Test 3", "Test 2", "Test 1"]

        "combined asc, desc":
          topic: (scope)->
            connect().find("posts")
          "same order":
            topic: (scope)->
              scope.asc("category").desc("title").all @callback
            "should return in specified order": (posts)->
              titles = (post.title for post in posts)
              assert.deepEqual titles, ["Test 2", "Test 3", "Test 1"]
          "mixed order":
            topic: (scope)->
              scope.asc("category").asc("title").all @callback
            "should return in specified order": (posts)->
              titles = (post.title for post in posts)
              assert.deepEqual titles, ["Test 2", "Test 1", "Test 3"]

        "limit":
          topic: (scope)->
            scope = connect().find("posts")
            scope.limit(1).all @callback
          "should return specified number of objects": (posts)->
            assert.equal posts.length, 1
          "should return first results": (posts)->
            titles = (post.title for post in posts)
            assert.deepEqual titles, ["Test 1"]

        "skip":
          topic: (scope)->
            scope = connect().find("posts")
            scope.skip(1).all @callback
          "should return specified number of objects": (posts)->
            assert.equal posts.length, 2
          "should skip first result": (posts)->
            titles = (post.title for post in posts)
            assert.deepEqual titles, ["Test 2", "Test 3"]

        "limit, skip":
          topic: (scope)->
            scope = connect().find("posts")
            scope.skip(1).limit(1).all @callback
          "should return specified number of objects": (posts)->
            assert.equal posts.length, 1
          "should skip first result, return only one": (posts)->
            titles = (post.title for post in posts)
            assert.deepEqual titles, ["Test 2"]
    ###
    "Simple queries":
      "count":
        "all":
          topic: (connect)->
            connect.find("posts").count @callback
          "should return number of records in collection": (count)->
            assert.equal count, 3
        "query":
          topic: (connect)->
            connect.find("posts", text: "Test 1").count @callback
          "should return number of records in collection": (count)->
            assert.equal count, 1

      "distinct":
        "all":
          topic: (connect)->
            connect.find("posts").distinct "text", @callback
          "should return all distinct values": (values)->
            assert.equal values.length, 3
            assert.include values, "Test 1"
            assert.include values, "Test 2"
            assert.include values, "Test 3"
        "query":
          topic: (connect)->
            connect.find("posts", text: "Test 2").distinct "text", @callback
          "should return only matching records": (values)->
            assert.equal values.length, 1
            assert.include values, "Test 2"

      "find one":
        "no query":
          topic: (connect)->
            connect.find("posts").one @callback
          "should return a single post": (post)->
            assert.equal "Test 1", post.text
            assert post._id
        "with query":
          topic: (connect)->
            connect.find("posts", text: "Test 2").one @callback
          "should return a single post": (post)->
            assert.equal "Test 2", post.text
        "with where query":
          topic: (connect)->
            connect.find("posts").where(text: "Test 3").one @callback
          "should return a single post": (post)->
            assert.equal "Test 3", post.text
        "with no fields":
          topic: (connect)->
            connect.find("posts").fields().one @callback
          "should return _id only": (post)->
            assert post._id
            assert.isUndefined post.text
        "with specified fields":
          topic: (connect)->
            connect.find("posts").fields("text").one @callback
          "should return specified fields only": (post)->
            assert post._id
            assert post.text
            assert.isUndefined post.author_id
        "with nested arrays":
          topic: (connect)->
            connect.find("posts").fields(["author_id"]).one @callback
          "should return specified fields only": (post)->
            assert post._id
            assert.isUndefined post.text
            assert post.author_id

 
    "Using cursor":
      "find next":
        topic: (connect)->
          finder = connect.find("posts")
          objects = []
          takeNext = (error, object)=>
            objects.push object
            if object
              finder.next takeNext
            else
              @callback null, objects
          finder.next takeNext
        "should call once for each post": (objects)->
          assert.equal "Test 1", objects[0].text
          assert.equal "Test 2", objects[1].text
          assert.equal "Test 3", objects[2].text
        "should call last with null": (objects)->
          assert.equal 4, objects.length
          assert.isNull objects[3]

      ##
      # Rewind is broken in connect 0.9.6-23
      "rewind":
        topic: (connect)->
          finder = connect.find("posts").where(text: "Test 2")
          objects = []
          takeNext = (error, object)=>
            objects.push object
            if object
              finder.next takeNext
            else if objects.length == 2
              finder.rewind()
              finder.next takeNext
            else
              @callback null, objects
          finder.next takeNext
        "should rewind on query results": (objects)->
          assert.equal "Test 2", objects[0].text
          assert.isNull objects[1]
          assert.equal "Test 2", objects[2].text
          assert.isNull objects[3]
      ##


    ###
   
    
  
    # -- Test somet of these methods, using models --

    ###
    "model":

      "database find with callback":
        topic: ->
          connect().find Post, { author_id: 1 }, @callback
        "should return all posts": (posts)->
          assert.equal posts.length, 2
          for post in posts
            assert.equal post.author_id, 1
        "should construct models": (posts)->
          for post in posts
            assert post instanceof Post
    ###

.export(module)
