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
    if selector instanceof Array
      selector = { _id: { $in: selector } }
    if selector instanceof @database.ObjectID || selector instanceof String
      if callback
        this.where(_id: selector).extend(options).one callback
      else
        return this.where(_id: selector).extend(options)
    else
      if callback
        this.where(selector).extend(options).all callback
      else
        return this.where(selector).extend(options)

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
    this.query selector, options, (error, cursor)=>
      return callback error if error
      # Retrieve next object and pass to callback.
      readNext = =>
        cursor.nextObject (error, object)=>
          if error
            cursor.close()
            callback error
          else
            if @model && object
              model = new @model()
              for k,v of object
                model[k] = v
              callback null, model
            else
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
    objects = []
    this.each selector, options, (error, object)=>
      return callback error if error
      if object
        objects.push object
      else
        callback null, objects, @database


  

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
    @_connect (error, collection, database)=>
      return callback error if error
      collection.findOne selector || {}, options || {}, (error, object)=>
        database.end()
        callback error, object, database
    return

  # Used internally to open a cursor for queries.
  query: (selector, options, callback)->
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




# Represents a query.  The find method returns this object.  You can further
# refine the query using chained method before asking it to return records,
# counts, etc.
#
# For example, to find 50 posts and only return their text:
#
#   connect().find("posts", author_id: authpor._id).fields("text").limit(50).all (err, posts, db)->
class Scope
  constructor: (@collection, @selector, @options)->

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

  # Instructs query to return only named fields.
  #
  # Example:
  #   connect().find("posts").fields("author_id", "title")
  #   connect().find("posts").fields(["author_id", "title"])
  fields: ()->
    fields = []
    for arg in arguments
      if Array.isArray(arg)
        fields = fields.concat(arg)
      else
        fields.push arg.toString()
    return @extend(fields: fields)

  # Limit number of records returned.
  limit: (limit)->
    return @extend(limit: limit)

  # Return records from specified offset.
  skip: (skip)->
    return @extend(skip: skip)

  # Returns query with combined options.
  extend: (options)->
    combined = {}
    if @options
      combined[k] = v for k,v of @options
    if options
      combined[k] = v for k,v of options
    return new Scope(@collection, @selector, combined)


  # Passes object to callback.
  #
  # Example:
  #   connect().find("posts", author_id: id).one (err, post, db)->
  one: (callback)->
    @collection.one @selector, @options, callback

  # Passes each object to callback.  Passes null as last object.
  #
  # Example:
  #   connect().find("posts").each (err, post, db)->
  each: (callback)->
    @collection.each @selector, @options, callback

  # Passes all objects to callback.
  #
  # Example:
  #   connect().find("posts").all (err, posts)->
  all: (callback)->
    @collection.all @selector, @options, callback

  # Opens cursor and passes next result to query.  Passes null if there are no
  # more results.
  next: (callback)->
    if @cursor
      @cursor.nextObject (error, object)=>
        callback error, object
    else
      @collection.query @selector, @options, (error, @cursor)=>
        return callback error if error
        @cursor.nextObject callback
    return

  # Rewind cursor to beginning.
  rewind: ->
    if @cursor
      @cursor.rewind()
    return

  close: ->
    if @cursor
      @cursor.close()
    return


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



exports.Collection = Collection
