(function() {
  var Vue, install, samjs;

  require("./materialize.config");

  samjs = require("samjs-client")();

  samjs.io.socket.on("reload", function() {
    console.log("reloading");
    return document.location.reload();
  });

  Vue = require("vue");

  install = new Vue(require("./client-install-comp")).$mount("#install");

  install.samjs = samjs;

}).call(this);
