fs = require "fs"
path = require "path"
webpack = require "webpack"
kwm = require "koa-webpack-middleware"

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
    icons = []
    configItems = []
    installItems = []
    for key,val of samjs.configs
      if val.installComp
        if val.installComp.icons
          for icon in val.installComp.icons
            if icons.indexOf(icon) == -1
              icons.push icon
        if val.installComp.paths
          for path, i in val.installComp.paths
            configItems.push "name:'config#{key+i}', comp: require('#{path}')"
    for key,val of samjs.models
      if val.installComp
        if val.installComp.icons
          for icon in val.installComp.icons
            if icons.indexOf(icon) == -1
              icons.push icon
        if val.installComp.paths
          for path, i in val.installComp.paths
            installItems.push "name:'install#{key+i}', comp: require('#{path}')"
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
    compiler = webpack(webpackConfig)
    wdm = require('webpack-dev-middleware')(
      compiler
      publicPath:options.publicPath
      noInfo:true
      stats:colors:true
      )
    koa = require("koa")()
    koa.use (next) ->
      ctx = this
      ended = yield (done) ->
        wdm ctx.req, {
          end: (content) ->
            ctx.body = content
            done(null,true)
          setHeader: -> ctx.set.apply(ctx, arguments)
        }, -> done(null,false)
      yield next unless ended
    koa.use (next) ->
      yield require("webpack-hot-middleware")(compiler).bind(null,@req,@res)
      yield next
    samjs.server = require("http").createServer(koa.callback())
    samjs.server.listen(options.port,options.host)
    samjs.server.on "connection", (con) ->
      connections.push con
      con.on "close", ->
        connections.splice(connections.indexOf(con),1)


  samjs.addHook "beforeExposing", ->
    ioClosed = new samjs.Promise (resolve) ->
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
