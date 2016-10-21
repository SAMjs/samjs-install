(function() {
  var connections, fs, koaHotDevWebpack, path, server, webpack, webpackConfig;

  fs = require("fs");

  path = require("path");

  webpack = require("webpack");

  koaHotDevWebpack = require("koa-hot-dev-webpack");

  webpackConfig = require.resolve("./webpack.config");

  webpackConfig = require(webpackConfig);

  connections = [];

  server = null;

  module.exports = function(options) {
    return function(samjs) {
      var Install, debug, realIO, realServer;
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
      if (options.debug == null) {
        options.debug = false;
      }
      samjs.addHook("beforeStartup", function() {
        realIO = samjs.io;
        realServer = samjs.server;
        samjs.io = null;
        samjs.server = null;
        return samjs.noServer = true;
      });
      samjs.on("beforeConfigureOrInstall", function() {
        var configItems, getItems, icons, installItems, koa;
        icons = [];
        configItems = [];
        installItems = [];
        getItems = function(name, itemArray) {
          var i, icon, j, key, len, p, ref, ref1, results, val;
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
                    path = ref2[i];
                    p = path.replace(/\\/g, "\\\\");
                    results1.push(itemArray.push("name:'" + name + (key + i) + "', comp: require('" + p + "')"));
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
          path: "/"
        };
        if (options.debug) {
          webpackConfig.devtool = '#source-map';
        }
        webpackConfig.plugins.push(new webpack.DefinePlugin({
          'process.env': {
            NODE_ENV: options.debug ? '"development"' : '"production"'
          }
        }));
        koa = require("koa")();
        koa.use(koaHotDevWebpack(webpackConfig, {
          noInfo: !options.debug
        }));
        server = require("http").createServer(koa.callback());
        samjs.server = server;
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
        samjs.server.on("connection", function(con) {
          connections.push(con);
          return con.once("close", function() {
            return connections.splice(connections.indexOf(con), 1);
          });
        });
        return samjs.io = samjs.socketio(samjs.server);
      });
      samjs.addHook("beforeExposing", function() {
        var ioClosed;
        ioClosed = new samjs.Promise(function(resolve) {
          var ref;
          if (((ref = samjs.io) != null ? ref.httpServer : void 0) == null) {
            return resolve();
          }
          samjs.io.httpServer.once("close", function() {
            samjs.debug("install server closed");
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
          var con, j, len;
          for (j = 0, len = connections.length; j < len; j++) {
            con = connections[j];
            con.destroy();
          }
          if (server != null) {
            if (typeof server.close === "function") {
              server.close();
            }
          }
          return koaHotDevWebpack.close();
        };

        return Install;

      })());
    };
  };

}).call(this);
