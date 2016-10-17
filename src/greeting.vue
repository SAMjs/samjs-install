<template lang="pug">
.card.black-text
  .card-content
    span.card-title.black-text Samjs
    p You are now taken through installation
  slot
</template>
<script lang="coffee">
module.exports =
  props: ["samjs"]
  data: ->
    nextText: "Let's start"
  ready: ->
    document.querySelector(".next-button").focus()
</script>
