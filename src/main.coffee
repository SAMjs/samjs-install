fs = require "fs"
path = require "path"
webpack = require "webpack"
koaHotDevWebpack = require "koa-hot-dev-webpack"
# workaround for coffee-script adding .coffee
webpackConfig = require.resolve "./webpack.config"
webpackConfig = require webpackConfig

connections = []

module.exports = (options) -> (samjs) ->
  debug = samjs.debug("install-server")
  realServer = null
  options ?= {}
  options.port ?= 8080
  options.publicPath ?= "/"
  samjs.addHook "beforeStartup", ->
    realServer = samjs.server
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
    koa = require("koa")()
    koa.use koaHotDevWebpack(webpackConfig, noInfo: false)
    samjs.server = require("http").createServer(koa.callback())

    samjs.server.listen(options.port,options.host)
    samjs.server.on "connection", (con) ->
      connections.push con
      con.on "close", ->
        connections.splice(connections.indexOf(con),1)
    samjs.io = samjs.socketio(samjs.server)


  samjs.addHook "beforeExposing", ->
    ioClosed = new samjs.Promise (resolve) ->
      return resolve() unless samjs.io?
      samjs.io.httpServer.on "close", ->
        samjs.debug("install server closed")
        setTimeout resolve, 50
      setTimeout (->
        samjs.io.close()
        for con in connections
          con.destroy()
        ),500
    return ioClosed.then ->
      samjs.server = realServer
      samjs.io = samjs.socketio(realServer)
  return new class Install
    name: "samjs-install"
