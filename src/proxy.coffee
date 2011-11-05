class Proxy
  constructor: (@doc, @parentModel, @childModel) ->
    if Object.isString(@parentModel)
      @parentModel = ->
        Poutine.models[@parentModel]
    else
      @parentModel = -> @parentModel
    
    if Object.isString(@childModel)
      @childModel = ->
        Poutine.models[@childModel]
    else
      @childModel = -> @childModel
  
  create: (fields, callback) ->
    @childModel().create(fields, callback)

class Proxy.HasMany extends Proxy
  constructor: (doc, parentModel, childModel) ->
    super(doc, parentModel, childModel)
    @type = "hasMany"

  create: (fields, callback) ->
    console.log Poutine.models
    @field = @childModel().collection_name + "_ids"
    @remoteField = @parentModel.name.toLowerCase() + "_id"
    fields[@remoteField] = @doc._id
    super(fields, callback)

module.exports = Proxy