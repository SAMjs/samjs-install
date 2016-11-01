# out: ../lib/builder.js
path = require "path"
require "coffee-script/register"
samjs = require "samjs"
module.exports = (options) ->
  unless options.args.length > 0
    throw new Error "no bootstrap file provided"
  bootstrap = require path.resolve(options.args[0])
  samjs.__samjsinstallbuild = options.out or true
  bootstrap(samjs)
