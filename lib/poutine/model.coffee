class Model

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


exports.Model = Model
