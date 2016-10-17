require "./materialize.config"
samjs = require("samjs-client")()
samjs.io.socket.on "reload", () ->
  console.log "reloading"
  document.location.reload()
Vue = require "vue"
install = new Vue(require("./install-comp")).$mount("#install")
install.samjs = samjs
