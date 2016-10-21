fs = require "fs"
path = require "path"
webpack = require "webpack"
koaHotDevWebpack = require "koa-hot-dev-webpack"
# workaround for coffee-script adding .coffee
webpackConfig = require.resolve "./webpack.config"
webpackConfig = require webpackConfig

connections = []
server = null
module.exports = (options) -> (samjs) ->
  debug = samjs.debug("install-server")
  realServer = null
  realIO = null
  options ?= {}
  options.port ?= 8080
  options.publicPath ?= "/"
  options.debug ?= false
  samjs.addHook "beforeStartup", ->
    realIO = samjs.io
    realServer = samjs.server
    samjs.io = null
    samjs.server = null
    samjs.noServer = true
  samjs.on "beforeConfigureOrInstall", ->
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
            for path, i in val.installComp.paths
              p = path.replace(/\\/g,"\\\\")
              itemArray.push "name:'#{name}#{key+i}', comp: require('#{p}')"
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
    webpackConfig.output = publicPath: options.publicPath, path: "/"
    webpackConfig.devtool = '#source-map' if options.debug
    webpackConfig.plugins.push new webpack.DefinePlugin
      'process.env': NODE_ENV: if options.debug then '"development"' else '"production"'
    koa = require("koa")()
    koa.use koaHotDevWebpack(webpackConfig, noInfo: !options.debug)
    server = require("http").createServer(koa.callback())
    samjs.server = server
    samjs.server.listen options.port, options.host, ->
      if options.host
        str = "http://#{options.host}:#{options.port}/"
      else
        str = "port: #{options.port}"
      console.log "samjs-install server listening on #{str}"
      koaHotDevWebpack.reload?()
    samjs.server.on "connection", (con) ->
      connections.push con
      con.once "close", ->
        connections.splice(connections.indexOf(con),1)
    samjs.io = samjs.socketio(samjs.server)


  samjs.addHook "beforeExposing", ->
    ioClosed = new samjs.Promise (resolve) ->
      return resolve() unless samjs.io?.httpServer?
      samjs.io.httpServer.once "close", ->
        samjs.debug("install server closed")
        setTimeout resolve, 50
      setTimeout (->
        samjs.io?.close()
        for con in connections
          con.destroy()
        ),500
    return ioClosed.then ->
      if realIO
        samjs.io = realIO
        samjs.server = realIO.httpserver
      else
        samjs.server = realServer
        samjs.io = samjs.socketio(realServer)
  return new class Install
    name: "samjs-install"
    shutdown: ->
      for con in connections
        con.destroy()
      server?.close?()
      koaHotDevWebpack.close()
