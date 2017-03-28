require "./materialize.config"
samjs = require("samjs-client")()
samjs.io.socket.on "reload", () ->
  console.log "reloading"
  document.location.reload()
container = document.getElementById "container"
startup = ->
  window.customElements.define "ceri-icon", require "ceri-icon"
  window.customElements.define "install-view", require "./client-component"
  view = document.createElement "install-view"
  view.components = getComponents()
  view.samjs = samjs
  container.appendChild view

polyfillCE = ->
  require.ensure([],((require) ->
    require("document-register-element")
    startup()
  ),"cePoly")
unless window.customElements?
  polyfillCE()
else
  startup()
