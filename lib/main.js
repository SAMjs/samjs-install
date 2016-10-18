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
        var configItems, i, icon, icons, installItems, j, k, key, koa, l, len, len1, len2, len3, m, ref, ref1, ref2, ref3, ref4, ref5, val;
        realServer = samjs.server;
        icons = [];
        configItems = [];
        installItems = [];
        ref = samjs.configs;
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
              ref2 = val.installComp.paths;
              for (i = k = 0, len1 = ref2.length; k < len1; i = ++k) {
                path = ref2[i];
                configItems.push("name:'config" + (key + i) + "', comp: require('" + path + "')");
              }
            }
          }
        }
        ref3 = samjs.models;
        for (key in ref3) {
          val = ref3[key];
          if (val.installComp) {
            if (val.installComp.icons) {
              ref4 = val.installComp.icons;
              for (l = 0, len2 = ref4.length; l < len2; l++) {
                icon = ref4[l];
                if (icons.indexOf(icon) === -1) {
                  icons.push(icon);
                }
              }
            }
            if (val.installComp.paths) {
              ref5 = val.installComp.paths;
              for (i = m = 0, len3 = ref5.length; m < len3; i = ++m) {
                path = ref5[i];
                installItems.push("name:'install" + (key + i) + "', comp: require('" + path + "')");
              }
            }
          }
        }
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
        koa.use(koaHotDevWebpack(webpackConfig));
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
