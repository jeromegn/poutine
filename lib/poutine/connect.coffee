# The configure function is used to configure a database connection.
#
# The connect function is used to acquire logicl connection to a database.


assert = require("assert")


# Database configurations.  We use this to configure database access and then
# get the driver instance (Db object).
databases = {}

# Configure a database.
#
# You can call this with one argument, a database name, and it will apply the
# default configuration.
#
# You can call this with database name and an object containing configuration
# options.  Supported options are:
# - host -- Database host name (defaults to 127.0.0.1)
# - port -- Database port number (defaults to 27017)
# - pool -- Connection pool size (defaults to 10)
# - name -- Actual database name if different from name argument
#
# You can also call this with an object, where each key is a database name, and
# the corresponding value the database configuration.
configure = (name, options = {})->
  assert name, "This function requires a database name"
  { Configuration } = require("./database")
  if name.constructor == Object
    configs = name
    for name, options of configs
      configure name, options
  else
    assert !databases[name], "Already have configuration named #{name}"
    options ||= {}
    config = new Configuration(options.name || name, options)
    databases[name] = config
    configure.default ||= name

# Default database name.  If not set, pick the first database.
configure.default = null
configure.DEFAULT = "development"

# Provides access to the specified database (null for default database).
connect = (name)->
  { Database } = require("./database")
  name ||= configure.default || process.env.NODE_ENV || configure.DEFAULT
  unless databases[name]
    configure name
  return new Database(databases[name])


exports.configure = configure
exports.connect   = connect
