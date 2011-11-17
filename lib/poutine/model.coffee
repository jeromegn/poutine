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
  #    Post.find { author_id: author._id }, limit: 50, (err, posts, db)->
  #      . . .
  #
  #    Post.find id, (err, post, db)->
  #      . . .
  #
  #    scope = Post.find(author_id: author._id)
  #    scope.all (err, posts, db)->
  #      . . .
  @find: (selector, options, callback)->
    connect().find(this, selector, options, callback)

  # Used to instantiate a new instance from a loaded object.
  @instantiate: (model, values)->
    instance = new model(values)
    # Use assign method if defined, otherwise copy fields.
    if instance.assign instanceof Function
      instance.assign(values)
    else
      for name, type of model.fields
        instance[name] = values[name]
    # Call onLoad handler if defined.
    if instance.onLoad instanceof Function
      instance.onLoad()
    return instance

  # Defines a field.
  @field: (name)->
    @fields ||= {}
    @fields[name] = true
