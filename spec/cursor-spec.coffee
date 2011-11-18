{ assert, vows, connect, setup } = require("./helpers")


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
