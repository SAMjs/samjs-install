(function() {
  var connections, fs, koaHotDevWebpack, path, webpack, webpackConfig;

  fs = require("fs");

  path = require("path");

  webpack = require("webpack");

  koaHotDevWebpack = require("koa-hot-dev-webpack");

  webpackConfig = require.resolve("./webpack.config");

  webpackConfig = require(webpackConfig);

  connections = [];

  module.exports = function(options) {
    return function(samjs) {
      var Install, debug, realServer;
      debug = samjs.debug("install-server");
      realServer = null;
      if (options == null) {
        options = {};
      }
      if (options.port == null) {
        options.port = 8080;
      }
      if (options.publicPath == null) {
        options.publicPath = "/";
      }
      samjs.addHook("beforeStartup", function() {
        var configItems, getItems, icons, installItems, koa;
        realServer = samjs.server;
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
        koa = require("koa")();
        koa.use(koaHotDevWebpack(webpackConfig, {
          noInfo: false
        }));
        samjs.server = require("http").createServer(koa.callback());
        samjs.server.listen(options.port, options.host);
        return samjs.server.on("connection", function(con) {
          connections.push(con);
          return con.on("close", function() {
            return connections.splice(connections.indexOf(con), 1);
          });
        });
      });
      samjs.addHook("beforeExposing", function() {
        var ioClosed;
        ioClosed = new samjs.Promise(function(resolve) {
          return samjs.io.httpServer.on("close", function() {
            samjs.debug("install server closed");
            return setTimeout(resolve, 50);
          });
        });
        setTimeout((function() {
          var con, j, len, results;
          samjs.io.close();
          results = [];
          for (j = 0, len = connections.length; j < len; j++) {
            con = connections[j];
            results.push(con.destroy());
          }
          return results;
        }), 500);
        return ioClosed.then(function() {
          samjs.server = realServer;
          return samjs.io = samjs.socketio(realServer);
        });
      });
      return new (Install = (function() {
        function Install() {}

        Install.prototype.name = "samjs-install";

        return Install;

      })());
    };
  };

}).call(this);
