module.exports = (sails) ->
  global["Sequelize"] = require("sequelize")
  Sequelize.cls = require("continuation-local-storage").createNamespace("sails-sequelize-postgresql")

  initialize: (next) ->
    hook = this
    hook.initAdapters()
    hook.initModels()

    sails.log.verbose "Using connection named #{sails.config.models.connection}"
    connection = sails.config.connections[sails.config.models.connection]
    if not connection?
      throw new Error "Connection '#{sails.config.models.connection}' not found in config/connections"
    if not connection.options?
      connection.options = {}
    connection.options.logging = connection.options.logging or sails.log.verbose  #A function that gets executed everytime Sequelize would log something.

    migrate = sails.config.models.migrate
    sails.log.verbose "Migration: #{migrate}"

    sequelize = new Sequelize connection.database, connection.user, connection.password, connection.options
    global["sequelize"] = sequelize

    # create a separate sequelize instance for each connection
    sequelizeConnections = {}

    # create an key/val object with all connections defined
    for connName, cxn of sails.config.connections
      if not cxn.options
        cxn.options = {}
      cxn.options.logging = cxn.options.logging or sails.log.verbose
      seq = new Sequelize cxn.database, cxn.user, cxn.password, cxn.options
      sequelizeConnections[connName] = seq
      # if a property with this name already exists in "sequelize", don't overwrite it
      # throw an Error instead
      if sequelize[connName]?
        throw new Error "The property '#{connName}' already exists in sequelize. Please change the name of your connection to something else."
      sequelize[connName] = seq

    sails.modules.loadModels (err, models) ->
      if err?
        return next(err)

      for modelName, modelDef of models
        modelId = modelDef.globalId
        sails.log.verbose "Loading model '#{modelId}'"
        newModel = sequelize.define modelId, modelDef.attributes, modelDef.options

        # for each connection defined in sequelizeConnections,
        #   attach a model to newModel with the property key = connection name of the connection
        for connName of sails.config.connections
          seq = sequelizeConnections[connName]
          # if a property with this name already exists in this Model, don't overwrite it
          # throw an Error instead
          if newModel[connName]?
            throw new Error "The property '#{connName}' already exists in the model '#{modelId}. Please change the name of your connection to something else."
          newModel[connName] = seq.define modelId, modelDef.attributes, modelDef.options
          sails.log.verbose "Createing model '#{modelId}[#{connName}]'"

        global[modelId] = newModel
        sails.models[modelId.toLowerCase()] = newModel

      for modelName, modelDef of models
        hook.setAssociation modelDef
        hook.setDefaultScope modelDef

      # NOTE: sync is NOT supported for "extra" models
      if migrate is "safe"
        return next()
      else
        forceSync = migrate is "drop"
        sequelize.sync(force: forceSync).then ->
          next()
      return


  initAdapters: ->
    if sails.adapters is `undefined`
      sails.adapters = {}
    return

  initModels: ->
    if sails.models is `undefined`
      sails.models = {}
    return

  # NOTE: associations NOT supported for "extra" models
  setAssociation: (modelDef) ->
    if modelDef.associations?
      sails.log.verbose "Loading associations for '#{modelDef.globalId}'"
      if typeof modelDef.associations is "function"
        modelDef.associations modelDef
    return

  setDefaultScope: (modelDef) ->
    if modelDef.defaultScope?
      sails.log.verbose "Loading default scope for '#{modelDef.globalId}'"
      model = global[modelDef.globalId]
      if typeof modelDef.defaultScope is "function"
        model.$scope = modelDef.defaultScope() or {}
    return
