(function() {
  var connections, fs, io, koaHotDevWebpack, path, webpack, webpackConfig;

  fs = require("fs");

  path = require("path");

  webpack = require("webpack");

  koaHotDevWebpack = require("koa-hot-dev-webpack");

  webpackConfig = require.resolve("./webpack.config");

  webpackConfig = require(webpackConfig);

  connections = [];

  io = null;

  module.exports = function(options) {
    return function(samjs) {
      var Install, debug, prepareWebpackConfig, realIO, realServer;
      prepareWebpackConfig = function() {
        var configItems, getItems, icons, installItems;
        icons = [];
        configItems = [];
        installItems = [];
        getItems = function(name, itemArray) {
          var i, icon, j, key, len, p, p2, ref, ref1, results, val;
          ref = samjs[name];
          results = [];
          for (key in ref) {
            val = ref[key];
            if (val.installComp) {
              if (val.installComp.icons) {
                ref1 = val.installComp.icons;
                for (j = 0, len = ref1.length; j < len; j++) {
                  icon = ref1[j];
                  if (icons.indexOf(icon) === -1) {
                    icons.push(icon);
                  }
                }
              }
              if (val.installComp.paths) {
                results.push((function() {
                  var k, len1, ref2, results1;
                  ref2 = val.installComp.paths;
                  results1 = [];
                  for (i = k = 0, len1 = ref2.length; k < len1; i = ++k) {
                    p = ref2[i];
                    p2 = p.replace(/\\/g, "\\\\");
                    results1.push(itemArray.push("name:'" + name + (key + i) + "', comp: require('" + p2 + "')"));
                  }
                  return results1;
                })());
              } else {
                results.push(void 0);
              }
            } else {
              results.push(void 0);
            }
          }
          return results;
        };
        getItems("configs", configItems);
        getItems("models", installItems);
        webpackConfig.callbackLoader = {
          getIcons: require("vue-icons/icon-loader")(icons).getIcons,
          configItems: function() {
            if (configItems.length > 0) {
              return "[{" + configItems.join("},{") + "}]";
            }
            return "[]";
          },
          installItems: function() {
            if (installItems.length > 0) {
              return "[{" + installItems.join("},{") + "}]";
            }
            return "[]";
          }
        };
        webpackConfig.output = {
          publicPath: options.publicPath,
          path: options.path || "/"
        };
        return webpackConfig.plugins.push(new webpack.DefinePlugin({
          'process.env': {
            NODE_ENV: options.dev ? '"development"' : '"production"'
          }
        }));
      };
      debug = samjs.debug("install-server");
      realServer = null;
      realIO = null;
      if (options == null) {
        options = {};
      }
      if (options.port == null) {
        options.port = 8080;
      }
      if (options.publicPath == null) {
        options.publicPath = "/";
      }
      if (options.dev == null) {
        options.dev = process.env.NODE_ENV !== "production";
      }
      samjs.addHook("startupInitialization", function() {
        debug("saving original server");
        realIO = samjs.io;
        realServer = samjs.server;
        samjs.io = null;
        samjs.server = null;
        return samjs.noServer = true;
      });
      samjs.addHook("beforeStartup", function() {
        var ExtractTextPlugin;
        if (samjs.__samjsinstallbuild != null) {
          debug("bulding install bundle");
          prepareWebpackConfig();
          if (typeof samjs.__samjsinstallbuild === "string" || samjs.__samjsinstallbuild instanceof String) {
            webpackConfig.output.path = samjs.__samjsinstallbuild;
          }
          webpackConfig.plugins.push(new webpack.optimize.UglifyJsPlugin({
            compress: {
              warnings: false
            }
          }));
          ExtractTextPlugin = require("extract-text-webpack-plugin");
          webpackConfig.plugins.push(new ExtractTextPlugin("[name].css"));
          webpackConfig.module.loaders.push({
            test: /\.css$/,
            loader: ExtractTextPlugin.extract("style", "css")
          });
          webpackConfig.module.loaders.push({
            test: /\.scss$/,
            loader: ExtractTextPlugin.extract("style", "css!sass")
          });
          return new samjs.Promise(function(resolve, reject) {
            return webpack(webpackConfig, function(err, stats) {
              samjs.state.startup["catch"](function(e) {
                if (e != null) {
                  throw e;
                }
              });
              if (err) {
                return reject(err);
              }
              console.log(stats.toString({
                colors: true
              }));
              if (stats.hasErrors() || stats.hasWarnings()) {
                console.log("please fix the warnings and errors with webpack first");
              }
              return reject();
            });
          });
        }
      });
      samjs.on("beforeConfigureOrInstall", function() {
        var indexFile, koa, sendfile, serve;
        prepareWebpackConfig();
        webpackConfig.module.loaders.push({
          test: /\.css$/,
          loader: "style!css"
        });
        webpackConfig.module.loaders.push({
          test: /\.scss$/,
          loader: "style!css!sass"
        });
        koa = require("koa")();
        if ((options.path != null) && !options.dev) {
          sendfile = require("koa-sendfile");
          serve = require("koa-static");
          indexFile = path.resolve(options.path, "./index.html");
          koa.use(serve(options.path, {
            index: false
          }));
          koa.use(function*() {
            return (yield sendfile(this, indexFile));
          });
        } else {
          if (options.dev) {
            webpackConfig.devtool = '#source-map';
          }
          koa.use(koaHotDevWebpack(webpackConfig, {
            noInfo: !options.dev
          }));
        }
        debug("setting install server");
        samjs.server = require("http").createServer(koa.callback());
        samjs.server.on("connection", function(con) {
          debug("got connection");
          connections.push(con);
          return con.once("close", function() {
            debug("connection closed");
            return connections.splice(connections.indexOf(con), 1);
          });
        });
        samjs.server.listen(options.port, options.host, function() {
          var str;
          if (options.host) {
            str = "http://" + options.host + ":" + options.port + "/";
          } else {
            str = "port: " + options.port;
          }
          console.log("samjs-install server listening on " + str);
          return typeof koaHotDevWebpack.reload === "function" ? koaHotDevWebpack.reload() : void 0;
        });
        io = samjs.socketio(samjs.server);
        return samjs.io = io;
      });
      samjs.addHook("beforeExposing", function() {
        var ioClosed;
        ioClosed = new samjs.Promise(function(resolve) {
          var ref;
          if (((ref = samjs.io) != null ? ref.httpServer : void 0) == null) {
            return resolve();
          }
          samjs.io.httpServer.once("close", function() {
            debug("install server closed");
            return setTimeout(resolve, 50);
          });
          return setTimeout((function() {
            var con, j, len, ref1, results;
            if ((ref1 = samjs.io) != null) {
              ref1.close();
            }
            results = [];
            for (j = 0, len = connections.length; j < len; j++) {
              con = connections[j];
              results.push(con.destroy());
            }
            return results;
          }), 500);
        });
        return ioClosed.then(function() {
          debug("restoring original server");
          if (realIO) {
            samjs.io = realIO;
            return samjs.server = realIO.httpserver;
          } else {
            samjs.server = realServer;
            return samjs.io = samjs.socketio(realServer);
          }
        });
      });
      return new (Install = (function() {
        function Install() {}

        Install.prototype.name = "samjs-install";

        Install.prototype.shutdown = function() {
          return new samjs.Promise(function(resolve) {
            var con, j, len;
            for (j = 0, len = connections.length; j < len; j++) {
              con = connections[j];
              debug("destroying connection");
              con.destroy();
            }
            connections = [];
            koaHotDevWebpack.close();
            if (io != null) {
              io.httpServer.once("close", resolve);
              io.httpServer.close();
              io.engine.close();
              return io.close();
            } else {
              return resolve();
            }
          });
        };

        return Install;

      })());
    };
  };

}).call(this);
