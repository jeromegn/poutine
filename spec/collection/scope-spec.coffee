{ assert, vows, connect, setup } = require("../helpers")


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
