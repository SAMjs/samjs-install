ceri = require "ce/wrapper"
module.exports = ceri
  mixins: [
    require "ce/structure"
    require "ce/#show"
    require "ce/class"
    require "ce/style"

  ]
  structure: template 1, """
    <div class=card-content #ref=content>
    </div>
    <div class=card-action>
      <a
        tabindex=1
        class="back-button"
        @click=back
        @keyup=back 
        #show=hasBack
        #ref=backButton 
        :disabled=disabledBack
        >{{@backText}}
      </a>
      <a
        tabindex=0
        class="next-button"
        style="margin: 20px;position: absolute;right: 0;top:0"
        @click=next
        @keyup=next 
        #ref=nextButton
        :disabled=disabledNext
        >{{@nextText}}
      </a>
    </div>
  """
  initClass: "card"
  initStyle: 
    maxWidth: "600px"
    display: "block"
  computed:
    nextText: -> @currentComp?.nextText || "next"
    backText: -> @currentComp?.backText || "back"
    isValid: -> if @currentComp?.isValid? then @currentComp?.isValid else true
    disabledNext: -> !@isValid || @processing
    disabledBack: -> @processing
    index: -> @currentComp?._index || 0
    state: -> @currentComp?._state || "greeting"
    hasBack: -> !@isFirst
    isFirst: -> @index == 0
    isLast: -> @components[@state].length == @index+1

        

  states: ["greeting","config","install","farewell"]
  data: ->
    currentComp: null
    cards: {}
    processing: false
  connectedCallback: ->
    @loadComponent "greeting", 0
  methods:
    loadComponent: (state, index) ->
      item = @components[state][index]
      if item
        unless (c = @cards[item.name])
          window.customElements.define item.name, item.comp
          c = @cards[item.name] = document.createElement item.name
          c._index = index
          c._state = state
          c.nextButton = @nextButton
          c.backButton = @backButton
          c.samjs = @samjs
          c.finished = @next.bind(@)
        @content.removeChild @content.firstChild if @content.firstChild
        @content.appendChild c
        @$nextTick ->
          @currentComp = c
      else
        throw new Error "item not found"
      @processing = false

    next: (e)->

      if @isValid and not @processing
        @processing = true
        switch @state
          when @states[0]
            @samjs.install.onceConfigure
            .then @loadComponent.bind @, @states[1], 0
            .catch (e) =>
              @samjs.install.onceInstall
              .then @loadComponent.bind @, @states[2], 0
              .catch @loadComponent.bind @, @states[3], 0
          when @states[1]
            @currentComp.next()
            .then =>
              if @isLast
                @samjs.install.onceInstall
                .then @loadComponent.bind @, @states[2], 0
                .catch @loadComponent.bind @, @states[3], 0
              else
                @loadComponent(@state,@index+1)
            .catch @doNothing
          when @states[2]
            @currentComp.next()
            .then =>
              if @isLast
                @loadComponent(@states[3], 0)
              else
                @loadComponent(@state,@index+1)
            .catch @doNothing
          when @states[3]
            document.location.reload()


    doNothing: (e) -> @processing = false

    prev: ->
      if not @processing and not @isFirst
        @processing = true
        @loadComponent(@state,@index-1)



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

