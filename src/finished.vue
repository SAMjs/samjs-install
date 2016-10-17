<template lang="pug">
.card.black-text
  .card-content
    span.card-title.black-text Done!
    p.
      Have fun with samjs little cms
  slot
</template>
<script lang="coffee">
module.exports =
  props: ["samjs"]
  data: ->
    nextText: "Done"
  ready: ->
    document.querySelector(".next-button").focus()
</script>
