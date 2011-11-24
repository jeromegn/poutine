connect = require("./connect").connect


exports.Model = class Model

  # Finds all objects that match the query selector.
  #
  # If the last argument is a callback, load all matching objects and pass them to callback.
  # Callback receives error, objects and connection.
  #
  # Without callback, returns a new Scope object.
  #
  # The first argument is the query selector.  You can also pass an array of identifiers to load
  # specific objects, or a single identifier to load a single object.  If missing, all objects
  # are loaded from the collection.
  #
  # The second argument are query options (limit, sort, etc).  If you want to specify query
  # options, you must also specify a query selector.
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

  # Defines a field.
  @field: (name, type)->
    @fields ||= {}
    @fields[name] = type || Object
    private = "_#{name}"
    @prototype.__defineGetter__ name, ->
      this._[name] if this._
    @prototype.__defineSetter__ name, (value)->
      this._ ||= {}
      this._[name] = value


Model.lifecycle =
  # Used to instantiate a new instance from a loaded object.
  load: (model, values)->
    instance = new model(values)
    instance._ = values
    # Call afterLoad handler if defined.
    if instance.afterLoad instanceof Function
      instance.afterLoad()
    return instance

