<template lang="pug">
.card.black-text
  .card-content
    span.card-title.black-text Configuration
    p do it
  slot
</template>
<script lang="coffee">
module.exports =
  props: ["samjs"]
  methods:
    next: ->
      @samjs.install.set "test", "correct"
  ready: ->
    document.querySelector(".next-button").focus()
</script>
