# Basis for all Poutine models.


assert = require("assert")
connect = require("./connect").connect
{ BSONPure } = require("mongodb")


# Use this class to easily define model classes that can be loaded and saved by Poutine.
#
# Model classes have all sorts of interesting capabilities like field mapping, validation, before/after hooks, etc.
#
# Example:
#   class User extends Poutine
#     @collection "users"
#     @field "name", String
#     @field "password", String
#     @set "password", (clear)->
#       _.password = encrypt(clear)
#
#   User.where(name: "Assaf").one (error, user)->
#     console.log "Loaded #{user.name}"
class Model
  # Default constructor assigns defined fields from any object you pass, e.g.
  #   new User(name: "Assaf")
  constructor: (document)->
    if document
      for name of @constructor.fields
        value = document[name]
        @[name] = value if value

  # -- Schema --
 
  # ObjectID class.
  @ObjectID = BSONPure.ObjectID

  # Sets or returns the collection name (the collection_name property).
  #
  # Examples:
  #   class Post extends Poutine
  #     @collection "posts"
  #
  #   console.log Port.collection()
  @collection: (name)->
    @lifecycle.prepare this
    if name
      @collection_name = name
    else
      return @collection_name

  # Defines a field and adds property accessors.
  #
  # First argument is the field name, second argument is the field type (optional).
  #
  # Only defined fields are loaded and saved.  Fields are loaded into the _ property, and accessors are defined to
    # get/set the field value.  You can write your own accessors.
  #
  # Examples:
  #   class User extends Poutine
  #     @collection "users"
  #     @field "name", String
  #     @field "password", String
  #     @set "password", (clear)->
  #       _.password = encrypt(clear)
  #
  #   User.find().one (error, user)->
  #     console.log user.name
  @field: (name, type)->
    assert name, "Missing field name"
    @lifecycle.prepare this
    @fields ||= {}
    @fields[name] = type || Object
    private = "_#{name}"
    @prototype.__defineGetter__ name, ->
      this._?[name]
    @prototype.__defineSetter__ name, (value)->
      this._ ||= {}
      this._[name] = value

  # Example:
  #   class Post extends Poutine
  #     @collection "posts"
  #     @field "author", Author
  #     @get "author", ->
  #       @author ||= Author.find(@author_id)
  #     @set "author", (@author)->
  #       @author_id = @author?._id
  @get: (name, getter)->
    assert name, "Missing property name"
    assert setter, "Missing getter function"
    @prototype.__defineGetter__ name, getter

  # Convenience method for adding a setter property accessor.
  #
  # Examples:
  #   class User extends Poutine
  #     @collection "users"
  #     @field "password", String
  #     @set "password", (clear)->
  #       _.password = encrypt(clear)
  @set: (name, setter)->
    assert name, "Missing property name"
    assert setter, "Missing setter function"
    @prototype.__defineSetter__ name, setter

  # Returns true if we think the object is an instance of a model
  @isModel: (instance)->
    model = instance.constructor
    return model.collection_name && model.fields


  # -- Finders --

  # Finds all objects that match the query selector.
  #
  # If the last argument is a callback, load all matching objects and pass them to callback.  Callback receives error,
  # objects and connection.
  #
  # Without callback, returns a new Scope object.
  #
  # The first argument is the query selector.  You can also pass an array of identifiers to load specific objects, or a
  # single identifier to load a single object.  If missing, all objects are loaded from the collection.
  #
  # The second argument are query options (limit, sort, etc).  If you want to specify query options, you must also
  # specify a query selector.
  #
  # Examples:
  #   Post.find { author_id: author._id }, limit: 50, (err, posts, db)->
  #     . . .
  #
  #   Post.find id, (err, post, db)->
  #     . . .
  #
  #   scope = Post.find(author_id: author._id)
  #   scope.all (err, posts, db)->
  #     . . .
  @find: (selector, options, callback)->
    connect().find(this, selector, options, callback)

  # Returns a Scope for selecting objects from this model.
  #
  # Example:
  #   my_posts = Post.where(author_id: me._id).desc("created_at")
  #   my_posts.count (err, count, db)->
  #     console.log "I wrote #{count} posts"
  @where: (selector)->
    connect().find(this, selector)

  # Adds an afterLoaded hook, called after the model instance is set from the document.   Raising an error will stop
  # loading any more objects.
  #
  # Example:
  #   class User
  #     @afterLoad (callback)->
  #       # Example. You don't really want to do this, since it will make 1+N queries.
  #       Author.find @author_id, (error, author)=>
  #         @author = author
  #         callback error
  @afterLoad: (hook)->
    @lifecycle.addHook this, "afterLoad", hook


  # -- Insert/update/remove --

  @insert: (document, callback)->
    connect().collection(this).insert document, callback


# Poutine uses these lifecycle methods to perform operations on models, but keeps them separate so we don't pollute the
# Model prototype with methods that are never used directly by actual model classes.  Inheriting from a class that has
# hundreds of implementation methods is an anti-pattern we dislike.
Model.lifecycle =
  # Used to instantiate a new instance from a loaded object.
  load: (model, document, callback)->
    instance = new model()
    instance._ = document
    @callHook "afterLoad", instance, callback, document

  # Need to call this at least once per model.  Takes care of defining accessors for _id, ...
  prepare: (model)->
    unless model._id
      model.prototype.__defineGetter__ "_id", ->
        this._?._id
      model.prototype.__defineSetter__ "_id", (id)->
        this._ ||= {}
        this._._id = id


  # -- Hooks --

  # Add the named hook.
  # model - The model
  # hook  - Hook name
  # fn    - Function to be called
  addHook: (model, name, fn)->
    assert fn, "This method requires a function argument"
    named = model._hooks ||= {}
    hooks = named[name] ||= []
    hooks.push fn

  # Call the named hooks and pass control to callback when done.
  # name      - The hook name, e.g. beforeSave
  # model     - The model class
  # instance  - The model instance
  # args      - Optional arguments to pass to hooks
  callHook: (name, instance, callback, args...)->
    model = instance.constructor
    hooks = model._hooks?[name]
    # No hooks, just go back to callback
    unless hooks
      callback null, instance
      return
  
    # Call the next hook in the chain, until we're done or get an error.
    call = (hooks, index)->
      hook = hooks[index]
      if hook
        try
          # If we get a result, continue to next hook, otherwise, have callback deal with it.
          result = hook.call(instance, args..., (error)->
            return callback error if error
            if result
              process.emit "error", new Error("#{name} hook on #{model.name}/#{instance._id} returned value *and* called callback")
            else
              call hooks, index + 1
          )
          if result
            call hooks, index + 1
        catch error
          callback error
      else
        callback null, instance
    call hooks, 0


exports.Model = Model
