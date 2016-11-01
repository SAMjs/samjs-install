samjs = require "samjs"
chokidar = require "chokidar"
path = require "path"
fs = samjs.Promise.promisifyAll(require("fs"))
testConfigFile = "test/testConfig.json"
fs.unlinkAsync testConfigFile
.catch -> return true
.finally ->
  samjs.bootstrap require("./bootstrap.coffee")
  chokidar.watch(["./dev/server.coffee","./src/plugin.coffee"],{ignoreInitial: true})
  .on "all", (ev,relPath) ->
    absPath = path.resolve(relPath)
    if require.cache[absPath]
      delete require.cache[absPath]
    samjs.reload()
