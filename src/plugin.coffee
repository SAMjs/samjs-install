# out: ../lib/plugin.js
fs = require "fs"
path = require "path"
webpack = require "webpack"
koaHotDevWebpack = require "koa-hot-dev-webpack"
# workaround for coffee-script adding .coffee
webpackConfig = require.resolve "./webpack.config"
webpackConfig = require webpackConfig

connections = []
io = null
module.exports = (options) -> (samjs) ->

  prepareWebpackConfig = ->
    icons = []
    configItems = []
    installItems = []
    getItems = (name,itemArray) ->
      for key,val of samjs[name]
        if val.installComp
          if val.installComp.icons
            for icon in val.installComp.icons
              if icons.indexOf(icon) == -1
                icons.push icon
          if val.installComp.paths
            for p, i in val.installComp.paths
              p2 = p.replace(/\\/g,"\\\\")
              itemArray.push "name:'#{name}#{key+i}', comp: require('#{p2}')"
    getItems("configs",configItems)
    getItems("models",installItems)
    webpackConfig.callbackLoader =
      getIcons: require("vue-icons/icon-loader")(icons).getIcons
      configItems: ->
        if configItems.length > 0
          return "[{" +configItems.join("},{")+"}]"
        return "[]"
      installItems: ->
        if installItems.length > 0
          return "[{" +installItems.join("},{")+"}]"
        return "[]"
    webpackConfig.output = publicPath: options.publicPath, path: options.path or "/"
    webpackConfig.plugins.push new webpack.DefinePlugin
      'process.env': NODE_ENV: if options.dev then '"development"' else '"production"'

  debug = samjs.debug("install-server")
  realServer = null
  realIO = null
  options ?= {}
  options.port ?= 8080
  options.publicPath ?= "/"
  options.dev ?= process.env.NODE_ENV != "production"
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
      prepareWebpackConfig()
      if typeof samjs.__samjsinstallbuild == "string" or samjs.__samjsinstallbuild instanceof String
        webpackConfig.output.path = samjs.__samjsinstallbuild
      webpackConfig.plugins.push new webpack.optimize.UglifyJsPlugin compress: warnings: false
      ExtractTextPlugin = require("extract-text-webpack-plugin")
      webpackConfig.plugins.push new ExtractTextPlugin("[name].css")
      webpackConfig.module.loaders.push test: /\.css$/, loader: ExtractTextPlugin.extract("style", "css")
      webpackConfig.module.loaders.push test: /\.scss$/, loader: ExtractTextPlugin.extract("style", "css!sass")
      return new samjs.Promise (resolve,reject) ->
        webpack webpackConfig, (err, stats) ->
          samjs.state.startup.catch (e) -> throw e if e?
          return reject(err) if err
          console.log stats.toString(colors: true)
          if stats.hasErrors() or stats.hasWarnings()
            console.log "please fix the warnings and errors with webpack first"
          reject()

  samjs.on "beforeConfigureOrInstall", ->
    prepareWebpackConfig()
    webpackConfig.module.loaders.push test: /\.css$/, loader: "style!css"
    webpackConfig.module.loaders.push test: /\.scss$/, loader: "style!css!sass"
    koa = require("koa")()
    if options.path? and !options.dev
      sendfile = require "koa-sendfile"
      serve = require "koa-static"
      indexFile = path.resolve(options.path,"./index.html")
      koa.use serve(options.path,index:false)
      koa.use -> yield sendfile(@, indexFile)
    else
      webpackConfig.devtool = '#source-map' if options.dev
      koa.use koaHotDevWebpack(webpackConfig, noInfo: !options.dev)
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
      koaHotDevWebpack.reload?()
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
      koaHotDevWebpack.close()
      if io?
        io.httpServer.once "close", resolve
        io.httpServer.close()
        io.engine.close()
        io.close()
      else
        resolve()
