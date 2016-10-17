<template lang="pug">
#install-container.container
  div(
    v-ref:comp,
    :is="currentCompName",
    :samjs="samjs",
    tabindex="-1",
    transition="slide",
    @next="next"
    @validity-changed="validityChanged")
    .card-action
      a.prev-button(@click="prev",@keyup.13 ="prev", v-if="hasPrev", :disabled="processing") back
      .right-align
        a.next-button(@click="next",@keyup.13 ="next", :disabled="processing || !isValid") {{nextText}}
</template>
<script lang="coffee">
Velocity = require("velocity-animate")
items = require("apply!callback!./itemGetter")
components = {
  greeting: require("./greeting")
  finished: require("./finished")
}
for c in items.config
  components[c.name]=c.comp
for i in items.install
  components[i.name]=i.comp
module.exports =
  components: components
  computed:
    currentCompName: ->
      @$nextTick =>
        if @$refs.comp.nextText
          @nextText = @$refs.comp.nextText
        else
          @nextText = "next"
      return switch @state
        when "greeting" then "greeting"
        when "config" then items.config[@currentComp].name
        when "install" then items.install[@currentComp].name
        when "finished" then "finished"

  data: ->
    nextText: "next"
    isValid: true
    hasPrev: false
    processing: false
    state: "greeting"
    currentComp: 0
  methods:
    next: ->
      if @isValid
        @processing = true
        if @currentCompName == "greeting"
          @samjs.install.onceConfigure
          .then @goToFirstConfigItem
          .catch =>
            @samjs.install.onceInstall
            .then @goToFirstInstallItem
            .catch @goToFinished
        else if @currentCompName == "finished"
          document.location.reload()
        else if @state == "config"
          @$refs.comp.next()
          .then =>
            if @currentComp == (items.config.length - 1)
              @samjs.install.onceInstall
              .then @goToFirstInstallItem
              .catch @goToFinished
            else
              @goTo(@currentComp+1)
          .catch @doNothing
        else if @state == "install"
          @$refs.comp.next()
          .then =>
            if @currentComp == (items.install.length - 1)
              @samjs.install.onceInstalled
              .then @goToFinished
            else
              @goTo(@currentComp+1)
          .catch @doNothing

    doNothing: ->
      @processing = false
    goToFirstConfigItem: ->
      @currentComp = 0
      @processing = false
      @hasPrev = false
      @state = "config"
    goToFirstInstallItem: ->
      @currentComp = 0
      @processing = false
      @hasPrev = false
      @state = "install"
    goToFinished: ->
      @currentComp = 0
      @processing = false
      @hasPrev = false
      @isValid = true
      @state = "finished"
    goTo: (newIndex) ->
      if @state == "config"
        @currentComp = items.config[newIndex]
      else if @state == "install"
        @currentComp = items.install[newIndex]
      @processing = false
      @hasPrev = true
    prev: ->
      @processing = true
      if @state == "config"
        if @currentComp == 1
          @goToFirstConfigItem()
        else
          @goTo(@currentComp-1)
      else if @state == "install"
        index = items.install.indexOf(@currentComp)
        if @currentComp == 1
          goToFirstInstallItem()
        else
          @goTo(@currentComp-1)

    validityChanged: (isValid) -> @isValid = isValid


  transitions:
    "slide":
      enter: (el, done) ->
        Velocity.hook el, "translateY", "70%"
        #Velocity.hook el, "translateY", "-70%"
        Velocity.hook el, "scaleX", "90%"
        Velocity el, {translateY: "0", opacity: 1,scaleX: 1},
          {duration: 300
          ease: "easeOutCubic"
          queue:false
          complete: done}
      leave: (el, done) ->
        translateY = "-70%"
        # translateY = "70%"
        Velocity el, {translateY: translateY, opacity: 0,scaleX: 0.9},
          {duration: 300
          ease: "easeOutCubic"
          queue:false
          complete: done}
</script>
<style lang="stylus">
#install-container
  position: relative
  .slide-enter,.slide-leave
    position: absolute
    width: 100%
    top: 0
  .slide-enter
    opacity: 0
  .prev-button,.next-button
    cursor pointer
</style>
