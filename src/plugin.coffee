# out: ../lib/plugin.js
fs = require "fs"
path = require "path"

if path.extname(__filename) == ".coffee"
  require "coffee-script/register"

connections = []
io = null
koaHotDevWebpack = null
module.exports = (options) -> (samjs) ->
  debug = samjs.debug("install-server")
  realServer = null
  realIO = null

  defaults = 
    port: 8080
    publicPath: ""
    dev: process.env.NODE_ENV != "production"
    greeting: path.resolve __dirname, "./client-greeting"
    farewell: path.resolve __dirname, "./client-farewell"
  options = Object.assign defaults, options

  options.icons ?= []
  options.configItems ?= []
  options.installItems ?= []
  getItems = (name,itemArray) ->
    for key,val of samjs[name]
      if val.installComp
        if val.installComp.icons
          for icon in val.installComp.icons
            if options.icons.indexOf(icon) == -1
              options.icons.push icon
        if val.installComp.paths
          for p, i in val.installComp.paths
            p2 = p.replace(/\\/g,"\\\\")
            itemArray.push "name:'ce-#{name.toLowerCase()}-#{key.toLowerCase()}-#{i}', comp: require('#{p2}')"
  getWebpackConfig = (options) ->
    getItems("configs",options.configItems)
    getItems("models",options.installItems)
    webpackConfig = require("./webpack.config")(options)
    return webpackConfig
  
  
  samjs.addHook "startupInitialization", ->
    debug("saving original server")
    realIO = samjs.io
    realServer = samjs.server
    samjs.io = null
    samjs.server = null
    samjs.noServer = true
  samjs.addHook "beforeStartup", ->
    if samjs.__samjsinstallbuild?
      debug("bulding install bundle")
      if typeof samjs.__samjsinstallbuild == "string" or samjs.__samjsinstallbuild instanceof String
        options.path = samjs.__samjsinstallbuild
      webpackConfig = getWebpackConfig(options)
      return new samjs.Promise (resolve,reject) ->
        webpack = require "webpack"
        webpack webpackConfig, (err, stats) ->
          samjs.state.startup.catch (e) -> throw e if e?
          return reject(err) if err
          console.log stats.toString(colors: true)
          if stats.hasErrors() or stats.hasWarnings()
            console.log "please fix the warnings and errors with webpack first"
          reject()


  samjs.on "beforeConfigureOrInstall", ->
    Koa = require("koa")
    koa = new Koa()
    
    if options.path? and !options.dev
      serve = require "koa-static"
      koa.use serve(options.path)
    else
      koaHotDevWebpack = require "koa-hot-dev-webpack"
      koa.use koaHotDevWebpack(getWebpackConfig(options))
    debug("setting install server")
    samjs.server = require("http").createServer(koa.callback())
    samjs.server.on "connection", (con) ->
      debug("got connection")
      connections.push con
      con.once "close", ->
        debug("connection closed")
        connections.splice(connections.indexOf(con),1)
    samjs.server.listen options.port, options.host, ->
      if options.host
        str = "http://#{options.host}:#{options.port}/"
      else
        str = "port: #{options.port}"
      console.log "samjs-install server listening on #{str}"
      koaHotDevWebpack?.reload?()
    io = samjs.socketio(samjs.server)
    samjs.io = io


  samjs.addHook "beforeExposing", ->
    ioClosed = new samjs.Promise (resolve) ->
      return resolve() unless samjs.io?.httpServer?
      samjs.io.httpServer.once "close", ->
        debug("install server closed")
        setTimeout resolve, 50
      setTimeout (->
        samjs.io?.close()
        for con in connections
          con.destroy()
        ),500
    return ioClosed.then ->
      koaHotDevWebpack?.close()
      debug("restoring original server")
      if realIO
        samjs.io = realIO
        samjs.server = realIO.httpserver
      else
        samjs.server = realServer
        samjs.io = samjs.socketio(realServer)
  return new class Install
    name: "samjs-install"
    shutdown: -> new samjs.Promise (resolve) ->
      for con in connections
        debug("destroying connection")
        con.destroy()
      connections = []
      koaHotDevWebpack?.close()
      if io?
        io.httpServer.once "close", resolve
        io.httpServer.close()
        io.engine.close()
        io.close()
      else
        resolve()
