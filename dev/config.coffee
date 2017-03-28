ceri = require "ce/wrapper"
module.exports = ceri
  mixins: [
    require "ce/structure"
  ]
  structure: template 1, """
    <span class="card-title black-text">Configuration</span>
    <p>do it!</p>
  """
  methods:
    next: ->
      @samjs.install.set "test", "correct"
  connectedCallback: ->
    @nextButton.focus()