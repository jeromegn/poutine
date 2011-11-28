{ assert, vows, connect, setup } = require("../helpers")


vows.describe("Collection insert").addBatch

  # -- collection().insert --

  "insert":
    topic: ->
      setup =>
        @callback null, connect().collection("posts")

    "document only":
      topic: (collection)->
        result = collection.insert(title: "Insert 2.1")
        return result || "nothing"
      "should return null": (result)->
        assert.equal result, "nothing"
      "new document":
        topic: (result, collection)->
          collection.find(title: "Insert 2.1").one @callback
        "should exist in database": (object)->
          assert object

    "document and options":
      topic: (collection)->
        result = collection.insert({ title: "Insert 2.2" }, { safe: true })
        return result || "nothing"
      "should return null": (result)->
        assert.equal result, "nothing"
      "new document":
        topic: (result, collection)->
          collection.find(title: "Insert 2.2").one @callback
        "should exist in database": (object)->
          assert object

    "document, options and callback":
      topic: (collection)->
        collection.insert { title: "Insert 2.3" }, { safe: true }, @callback
      "should pass document to callback": (post)->
        assert post
        assert.equal post.title, "Insert 2.3"
      "should set document ID": (post)->
        assert post._id
      "new document":
        topic: (post, collection)->
          collection.find post._id, @callback
        "should exist in database": (post)->
          assert post
          assert.equal post.title, "Insert 2.3"

    "document and callback":
      topic: (collection)->
        collection.insert title: "Insert 2.4", @callback
      "should pass document to callback": (post)->
        assert post
        assert.equal post.title, "Insert 2.4"
      "should set document ID": (post)->
        assert post._id
      "new document":
        topic: (post, collection)->
          collection.find post._id, @callback
        "should exist in database": (post)->
          assert post
          assert.equal post.title, "Insert 2.4"

    "multiple documents, no callback":
      topic: (collection)->
        result = collection.insert([{ title: "Insert 2.5", category: "foo" }, { title: "Insert 2.5", category: "bar" }])
        return result || "nothing"
      "should return null": (result)->
        assert.equal result, "nothing"
      "new documents":
        topic: (result, collection)->
          collection.find(title: "Insert 2.5").all @callback
        "should all exist in database": (posts)->
          assert.lengthOf posts, 2
          categories = (post.category for post in posts)
          assert.include categories, "foo"
          assert.include categories, "bar"

    "multiple documents and callback":
      topic: (collection)->
        collection.insert [{ title: "Insert 2.6", category: "foo" }, { title: "Insert 2.6", category: "bar" }], @callback
      "should pass all document to callback": (posts)->
        assert.lengthOf posts, 2
        for post in posts
          assert.equal post.title, "Insert 2.6"
      "should set document ID": (posts)->
        for post in posts
          assert post._id
      "new documents":
        topic: (posts, collection)->
          ids = (post._id for post in posts)
          collection.find ids, @callback
        "should exist in database": (posts)->
          assert.lengthOf posts, 2
          categories = (post.category for post in posts)
          assert.include categories, "foo"
          assert.include categories, "bar"


.export(module)
