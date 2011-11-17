vows = require("vows")
assert = require("assert")
{ connect, setup, Model } = require("./helpers")


vows.describe("Connection queries").addBatch

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


vows.describe("Collection queries").addBatch

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


vows.describe("Scope queries").addBatch

  # -- scope.fields() --
   
  "fields":
    topic: ->
      setup (error)=>
        @callback error, connect().find("posts")

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
          assert !post.author_id
          assert !post.created_at

    "multiple arguments":
      topic: (scope)->
        scope.fields("title", "author_id").all @callback
      "should return only specified field": (posts)->
        for post in posts
          assert post.title
          assert post.author_id
          assert !post.created_at

    "array arguments":
      topic: (scope)->
        scope.fields(["title", "created_at"]).all @callback
      "should return only specified field": (posts)->
        for post in posts
          assert post.title
          assert !post.author_id
          assert post.created_at

    
.addBatch

  # -- scope.asc() scope.desc() --
  
  "asc":
    topic: ->
      setup (error)=>
        @callback error, connect().find("posts")

    "no argument":
      topic: (scope)->
        scope.asc().all @callback
      "should return in natural order": (posts)->
        titles = (post.title for post in posts)
        assert.deepEqual titles, ["Post 1", "Post 2", "Post 3"]

    "single argument":
      topic: (scope)->
        scope.asc("category").all @callback
      "should return in specified order": (posts)->
        titles = (post.title for post in posts)
        assert.deepEqual titles, ["Post 2", "Post 1", "Post 3"]

    "multiple arguments":
      topic: (scope)->
        scope.asc("category", "title").all @callback
      "should return in specified order": (posts)->
        titles = (post.title for post in posts)
        assert.deepEqual titles, ["Post 2", "Post 1", "Post 3"]

    "array arguments":
      topic: (scope)->
        scope.asc(["category", "title"]).all @callback
      "should return in specified order": (posts)->
        titles = (post.title for post in posts)
        assert.deepEqual titles, ["Post 2", "Post 1", "Post 3"]

    
  "desc":
    topic: ->
      setup (error)=>
        @callback error, connect().find("posts")

    "no argument":
      topic: (scope)->
        scope.desc().all @callback
      "should return in natural order": (posts)->
        titles = (post.title for post in posts)
        assert.deepEqual titles, ["Post 1", "Post 2", "Post 3"]

    "single argument":
      topic: (scope)->
        scope.desc("title").all @callback
      "should return in specified order": (posts)->
        titles = (post.title for post in posts)
        assert.deepEqual titles, ["Post 3", "Post 2", "Post 1"]

    "multiple arguments":
      topic: (scope)->
        scope.desc("title", "category").all @callback
      "should return in specified order": (posts)->
        titles = (post.title for post in posts)
        assert.deepEqual titles, ["Post 3", "Post 2", "Post 1"]

    "array arguments":
      topic: (scope)->
        scope.desc(["title", "category"]).all @callback
      "should return in specified order": (posts)->
        titles = (post.title for post in posts)
        assert.deepEqual titles, ["Post 3", "Post 2", "Post 1"]


  "combined asc, desc":
    topic: ->
      setup (error)=>
        @callback error, connect().find("posts")

    "same order":
      topic: (scope)->
        scope.asc("category").desc("title").all @callback
      "should return in specified order": (posts)->
        titles = (post.title for post in posts)
        assert.deepEqual titles, ["Post 2", "Post 3", "Post 1"]

    "mixed order":
      topic: (scope)->
        scope.asc("category").asc("title").all @callback
      "should return in specified order": (posts)->
        titles = (post.title for post in posts)
        assert.deepEqual titles, ["Post 2", "Post 1", "Post 3"]


.addBatch

  # -- scope.limit() scope.skip() --

  "limit":
    topic: ->
      setup =>
        scope = connect().find("posts")
        scope.limit(1).all @callback

    "should return specified number of objects": (posts)->
      assert.equal posts.length, 1

    "should return first results": (posts)->
      titles = (post.title for post in posts)
      assert.deepEqual titles, ["Post 1"]


  "skip":
    topic: ->
      setup =>
        scope = connect().find("posts")
        scope.skip(1).all @callback

    "should return specified number of objects": (posts)->
      assert.equal posts.length, 2

    "should skip first result": (posts)->
      titles = (post.title for post in posts)
      assert.deepEqual titles, ["Post 2", "Post 3"]


  "limit, skip":
    topic: ->
      setup =>
        scope = connect().find("posts")
        scope.skip(1).limit(1).all @callback

    "should return specified number of objects": (posts)->
      assert.equal posts.length, 1

    "should skip first result, return only one": (posts)->
      titles = (post.title for post in posts)
      assert.deepEqual titles, ["Post 2"]


.addBatch

  # -- scope.one() scope.each() scope.all() --

  "one":
    topic: ->
      setup =>
        connect().find("posts").where(title: "Post 2").one @callback
    "should return one object": (post)->
      assert post
      assert.equal post.title, "Post 2"


  "each":
    topic: ->
      setup =>
        titles = []
        connect().find("posts").where(author_id: 1).each (error, post)=>
          if post
            titles.push post.title
          else
            @callback null, titles
    "should pass each object, then null": (titles)->
      assert.equal titles.length, 2
      assert.deepEqual titles, ["Post 1", "Post 2"]


  "all":
    topic: ->
      setup =>
        connect().find("posts").where(author_id: 1).all @callback
    "should return all matching objects": (posts)->
      assert.equal posts.length, 2
      for post in posts
        assert.equal post.author_id, 1


.addBatch

  # -- scope.count() scope.distinct() --
  
  "count":
    topic: ->
      setup =>
        connect().find("posts").where(author_id: 1).count @callback
    "should return number of matching objects": (count)->
      assert.equal count, 2


  "distinct":
    topic: ->
      setup =>
        connect().find("posts").where(author_id: 1).distinct "title", @callback
    "should return distinct values": (titles)->
      assert.deepEqual titles, ["Post 1", "Post 2"]


.addBatch

  # -- scope.map() scope.filter() scope.reduce() --

  "map":
    topic: ->
      setup (error)=>
        @callback error, connect().find("posts")
    "function":
      topic: (scope)->
        scope.map ((post)-> post.title + "!"), @callback
      "should return mapped objects": (titles)->
        assert.deepEqual titles, ["Post 1!", "Post 2!", "Post 3!"]

    "name":
      topic: (scope)->
        scope.map "title", @callback
      "should return mapped objects": (titles)->
        assert.deepEqual titles, ["Post 1", "Post 2", "Post 3"]


  "filter":
    topic: ->
      setup (error)=>
        @callback error, connect().find("posts")
    "function":
      topic: (scope)->
        scope.filter ((post)-> post.author_id < 2), @callback
      "should return filtered objects": (posts)->
        for post in posts
          assert post.author_id < 2

    "name":
      topic: (scope)->
        scope.filter "title", @callback
      "should return filtered objects": (posts)->
        assert.equal posts.length, 3


  "reduce":
    topic: ->
      setup (error)=>
        @callback error, connect().find("posts")
    "initial value and function":
      topic: (scope)->
        scope.reduce 0, ((memo, post)-> memo + post.title.length), @callback
      "should return reduced value": (length)->
        assert.equal length, 18

    "function only":
      topic: (scope)->
        scope.reduce ((memo, post)-> memo + post.title.length), @callback
      "should return reduced value": (length)->
        assert.equal length, 18


.export(module)


vows.describe("Cursor").addBatch

  "find next":
    topic: ->
      setup =>
        scope = connect().find("posts")
        posts = []
        each = (error, post)=>
          if post
            posts.push post
            scope.next each
          else
            scope.close()
            @callback null, posts
        scope.next each
    "should call once for each post": (posts)->
      assert.equal posts.length, 3

  "rewind":
    topic: ->
      setup =>
        scope = connect().find("posts").where(title: "Post 2")
        posts = []
        each = (error, post)=>
          if post
            posts.push post
            scope.next each
          else if posts.length == 1
            scope.rewind()
            scope.next each
          else
            scope.close()
            @callback null, posts
        scope.next each
    "should call once for each post": (posts)->
      assert.equal posts.length, 2


.export(module)
