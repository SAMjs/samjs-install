<template lang="pug">
.card.black-text
  .card-content
    span.card-title.black-text Installation
    p do it!
  slot
</template>
<script lang="coffee">
module.exports =
  props: ["samjs"]
  methods:
    next: ->
      @samjs.install.isInInstallMode()
      .then (nsp) =>
        return @samjs.io.nsp(nsp).getter "test", "correct"
  ready: ->
    document.querySelector(".next-button").focus()
</script>
