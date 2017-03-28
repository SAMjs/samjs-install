ceri = require "ce/wrapper"
module.exports = ceri
  mixins: [
    require "ce/structure"
  ]
  structure: template 1, """
    <span class="card-title black-text">Done!</span>
    <p>Have fun with samjs</p>
  """
  data: ->
    nextText: "Done"
  connectedCallback: -> @nextButton.focus()
