ceri = require "ce/wrapper"
module.exports = ceri
  mixins: [
    require "ce/structure"
  ]
  structure: template 1, """
    <span class="card-title black-text">Samjs</span>
    <p>You are now taken through installation</p>
  """
  data: ->
    nextText: "Let's start"
  connectedCallback: -> @nextButton.focus()
