ceri = require "ce/wrapper"
module.exports = ceri
  mixins: [
    require "ce/structure"
  ]
  structure: template 1, """
    <span class="card-title black-text">Installation</span>
    <p>do it!</p>
  """
  methods:
    next: ->
      @samjs.install.isInInstallMode()
      .then (nsp) =>
        return @samjs.io.nsp(nsp).getter "test", "correct"
  connectedCallback: ->
    @nextButton.focus()