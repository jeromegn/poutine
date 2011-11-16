{ Model } = require("./model")


# Represents a collection and all the operation you can do on one.  Database
# methods like find and insert operate through a collection.
class Collection
  constructor: (@name, @database, @model)->

  # -- Finders --

  # Finds all objects that match the query selector.
  #
  # If the last argument is a callback, load all matching objects and pass them
  # to callback.  Callback receives error, objects and connection.
  #
  # Without callback, returns a new Scope object.
  #
  # The first argument is optional and specifies the query selector.  You can
  # also pass an array of identifier to return specific objects, or a single
  # identifier to return a single object.
  #
  # Second argument is optional and specifies query options (limit, sort, etc).
  # When passing options you must also pass the query selector.
  #
  # Examples:
  #    posts = connect().collection("posts")
  #    posts.find { author_id: author._id }, limit: 50, (err, posts, db)->
  #      . . .
  #
  #    posts.find "posts", id, (err, post, db)->
  #      . . .
  #
  #    query = posts.find(author_id: author._id)
  #    query.all (err, posts, db)->
  #      . . .
  find: (selector, options, callback)->
    if !callback && options instanceof Function
      [callback, options] = [options, null]
    if !callback && !options && selector instanceof Function
      [callback, selector] = [selector, null]
    if @model
      options ||= {}
      options.fields ||= Object.keys(@model.fields)
    if selector instanceof @database.ObjectID || selector instanceof String
      if callback
        @one selector, options, callback
      else
        return @where(_id: selector).extend(options)
    else
      if callback
        @all selector, options, callback
      else
        return @where(selector).extend(options)

  # Passes matching object from this query to callback.
  #
  # Takes three arguments, selector, options and callback.  Can also be called
  # with selector and callback or callback alone.
  one: (selector, options, callback)->
    unless callback
      if options
        [callback, options] = [options, null]
      else
        [callback, selector] = [selector, null]
    throw new Error("Callback required") unless callback instanceof Function
    @_connect (error, collection, database)=>
      return callback error if error
      collection.findOne selector || {}, options || {}, (error, object)=>
        database.end()
        if @model && object
          try
            object = Model.instantiate(@model, object)
          catch error
            callback error
            return
        callback error, object, database
    return

  # Passes each objects from this query to callback.  Passes null after the
  # last object.
  #
  # Takes three arguments, selector, options and callback.  Can also be called
  # with selector and callback or callback alone.
  each: (selector, options, callback)->
    unless callback
      if options
        [callback, options] = [options, null]
      else
        [callback, selector] = [selector, null]
    throw new Error("Callback required") unless callback instanceof Function
    if selector instanceof Array
      selector = { _id: { $in: selector } }
    @_query selector, options, (error, cursor)=>
      return callback error if error
      # Retrieve next object and pass to callback.
      readNext = =>
        cursor.nextObject (error, object)=>
          if error
            cursor.close()
            callback error
          else
            if @model && object
              try
                object = Model.instantiate(@model, object)
              catch error
                callback error
                cursor.close()
                return
            callback null, object
            # Use nextTick to avoid stack overflow on large result sets.
            if object
              process.nextTick readNext
            else
              cursor.close()
      readNext()
    return

  # Passes all objects from this query to callback.
  #
  # Takes three arguments, selector, options and callback.  Can also be called
  # with selector and callback or callback alone.
  all: (selector, options, callback)->
    unless callback
      if options
        [callback, options] = [options, null]
      else
        [callback, selector] = [selector, null]
    throw new Error("Callback required") unless callback instanceof Function
    objects = []
    @each selector, options, (error, object)=>
      return callback error if error
      if object
        objects.push object
      else
        callback null, objects, @database

  # Passes number of records in this query to callback.
  #
  # If called with single argument (callback), counts all objects in the
  # collection.
  count: (selector, callback)->
    unless callback
      [callback, selector] = [selector, null]
    throw new Error("Callback required") unless callback instanceof Function
    @_connect (error, collection, database)=>
      return callback error if error
      collection.count selector || {}, (error, count)=>
        database.end()
        callback error, count, database
    return

  # Passes distinct values to callback.
  #
  # If called with two arguments (key and callback), finds all distinct values
  # in the collection.   With three arguments, only looks at objects that match
  # the selector.
  distinct: (key, selector, callback)->
    unless callback
      [callback, selector] = [selector, null]
    throw new Error("Callback required") unless callback instanceof Function
    @_connect (error, collection, database)=>
      return callback error if error
      collection.distinct key, selector || {},  (error, count)=>
        database.end()
        callback error, count, database
    return

  # Returns a Scope on this collection.
  #
  # Example:
  #   my_posts = connect().find("posts").where(author_id: me._id).desc("created_at")
  #   my_posts.count (err, count, db)->
  #     console.log "I wrote #{count} posts"
  where: (selector)->
    return new Scope(this, selector)


  # -- Implementation details --

  # Passes error, collection and database to callback.
  _connect: (callback)->
    @database.driver (error, connection, end)=>
      return callback error if error
      connection.collection @name, (error, collection)=>
        if error
          end()
          callback error
        else
          callback null, collection, @database

  # Used internally to open a cursor for queries.
  _query: (selector, options, callback)->
    unless callback
      if options
        [callback, options] = [options, null]
      else
        [callback, selector] = [selector, null]
    @_connect (error, collection, database)=>
      return callback error if error
      collection.find selector || {}, options || {}, (error, cursor)=>
        database.end()
        callback error, cursor



# A scope limits objects returned by a query.  Scopes can also be used to
# insert, update and remove selected objects.
#
# Scopes are returned when you call `find` with no callback, or call `where` on
# a collection.
#
# A scope can be further refined by calling `where`.  You can also modify query
# options by calling `fields`, `asc`, `desc`, `limit` and `skip`.
#
# You can retrieve objects by calling `one`, `all`, `each`, `map`, `filter` or
# `reduce`.
#
# For example, to find 50 posts by certain author and only return their title:
#
#   posts = connect().find("posts")
#   by_author = posts.where(author_id: author._id)
#   limited = by_author.fields("title").limit(50)
#   limited.all (err, posts)->
#     titles = (post.title for post in posts)
#     console.log "Found these posts:", titles
class Scope
  constructor: (@collection, @selector, @options)->

  # -- Refine selector/options --

  # Refines query selector.
  #
  # These two are equivalent:
  #   connect().find("posts", author_id: author._id)
  #   connect().find("posts").where(author_id: author._id)
  where: (selector)->
    combined = {}
    if @selector
      combined[k] = v for k, v of @selector
    if selector
      combined[k] = v for k, v of selector
    return new Scope(@collection, combined, @options)

  # Instructs query to return only named fields.  You can call with multiple
  # arguments, an array argument or no arguments if you're only interested in
  # the object IDs.
  #
  # Example:
  #   connect().find("posts").fields("author_id", "title")
  #   connect().find("posts").fields(["author_id", "title"])
  fields: ->
    fields = []
    for arg in arguments
      if Array.isArray(arg)
        fields = fields.concat(arg)
      else
        fields.push arg.toString()
    return @extend(fields: fields)

  # Instructs query to sort object by ascending order.  You can call with
  # multiple arguments, an array argument or no arguments if you're only
  # interested in the object IDs.
  #
  # Example:
  #   connect().find("posts").asc("created_at")
  asc: ->
    return @sort(arguments, 1)

  # Instructs query to sort object by descending order.  You can call with
  # multiple arguments, an array argument or no arguments if you're only
  # interested in the object IDs.
  #
  # Example:
  #   connect().find("posts").desc("created_at")
  desc: ->
    return @sort(arguments, -1)

  # Limit number of records returned.
  #
  # Example:
  #   first_ten = posts.limit(10)
  limit: (limit)->
    return @extend(limit: limit)

  # Return records from specified offset.
  #
  # Example:
  #   next_ten = posts.skip(10).limit(10)
  skip: (skip)->
    return @extend(skip: skip)

  # Returns a scope with combined options.
  extend: (options)->
    combined = {}
    if @options
      combined[k] = v for k,v of @options
    if options
      combined[k] = v for k,v of options
    return new Scope(@collection, @selector, combined)

  # Changes sorting order.
  sort: (fields, dir)->
    throw "Direction must be 1 (asc) or -1 (desc)" unless dir == 1 || dir == -1
    sort = @options.sort || []
    for field in fields
      if Array.isArray(field)
        sort = sort.concat([f, dir] for f in field)
      else
        sort = sort.concat([[field, dir]])
    return @extend(sort: sort)


  # -- Load objects --

  # Passes object to callback.
  #
  # Example:
  #   connect().find("posts", author_id: id).one (err, post, db)->
  one: (callback)->
    throw new Error("Callback required") unless callback instanceof Function
    @collection.one @selector, @options, callback

  # Passes each object to callback.  Passes null as last object.
  #
  # Example:
  #   connect().find("posts").each (err, post, db)->
  each: (callback)->
    throw new Error("Callback required") unless callback instanceof Function
    @collection.each @selector, @options, callback

  # Passes all objects to callback.
  #
  # Example:
  #   connect().find("posts").all (err, posts)->
  all: (callback)->
    throw new Error("Callback required") unless callback instanceof Function
    @collection.all @selector, @options, callback

  # Passes number of records in this query to callback.
  #
  # Example:
  #   connect().find("posts", author_id: id).count (err, count)->
  count: (callback)->
    @collection.count @selector, callback

  # Passes distinct values callback.
  #
  # Example:
  #   connect().find("posts").distinct "author_id", (err, author_ids)->
  distinct: (key, callback)->
    @collection.distinct key, @selector, callback


  # -- Transformation --

  # Passes each object to the mapping function, and passes the result to the
  # callback.  You can also call with a function name, in which case it will
  # call that function on each object.
  #
  # Example:
  #   connect().find("posts").map ((post)-> "#{post.title} on #{post.created_at}"), (error, posts)->
  #     console.log posts
  map: (fn, callback)->
    unless typeof fn == "function"
      name = fn
      fn = (object)-> object[name]
    throw new Error("Callback required") unless callback instanceof Function
    results = []
    @collection.each @selector, @options, (error, object)->
      return callback error if error
      if object
        try
          results.push fn(object)
        catch error
          callback error
      else
        callback null, results

  # Passes each object to the filtering function, select only objects for which
  # the filtering function returns true, and pass that selection to the
  # callback.  You can also call with a function name, in which case it will
  # call that function on each object.
  #
  # Example:
  #   connect().find("posts").filter ((post)-> post.body.length > 500), (error, posts)->
  #     console.log "Found #{posts.count} posts longer than 500 characters"
  filter: (fn, callback)->
    unless typeof fn == "function"
      name = fn
      fn = (object)-> object[name]
    throw new Error("Callback required") unless callback instanceof Function
    results = []
    @collection.each @selector, @options, (error, object)->
      return callback error if error
      if object
        try
          results.push object if fn(object)
        catch error
          callback error
      else
        callback null, results

  # Passes each object to the reduce function, collects the reduce value, and
  # passes that to the callback.
  #
  # With two arguments, the first argument is the reduce function that accepts
  # value and object, and the second argument is the callback.  The initial
  # value is null.
  #
  # With three arguments, the first arguments supplies the initial value.
  #
  # Example:
  #   connect().find("posts").reduce ((total, post)-> total + post.body.length), (error, total)->
  #     console.log "Wrote #{total} characters"
  reduce: (value, fn, callback)->
    if arguments.length < 3
      [value, fn, callback] = [null, value, fn]
    throw new Error("Callback required") unless callback instanceof Function
    @collection.each @selector, @options, (error, object)->
      return callback error if error
      if object
        try
          value = fn(value, object)
        catch error
          callback error
      else
        callback null, value


  # -- Cursors --

  # Opens cursor and passes next result to query.  Passes null if there are no
  # more results.
  next: (callback)->
    if @_cursor
      @_cursor.nextObject (error, object)->
        callback error, object
    else
      @collection._query @selector, @options, (error, @_cursor)=>
        return callback error if error
        @_cursor.nextObject callback
    return

  # Rewind cursor to beginning.
  rewind: ->
    if @_cursor
      @_cursor.rewind()
    return

  close: ->
    if @_cursor
      @_cursor.close()
    return


exports.Collection = Collection
