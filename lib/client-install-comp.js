var __vueify_insert__ = require("vueify/lib/insert-css")
var __vueify_style__ = __vueify_insert__.insert("#install-container {\n  position: relative;\n}\n#install-container .slide-enter,\n#install-container .slide-leave {\n  position: absolute;\n  width: 100%;\n  top: 0;\n}\n#install-container .slide-enter {\n  opacity: 0;\n}\n#install-container .prev-button,\n#install-container .next-button {\n  cursor: pointer;\n}\n#install-container .prev-button.disabled,\n#install-container .next-button.disabled {\n  cursor: not-allowed;\n  color: #808080;\n}\n")
var Velocity, c, components, i, items, j, k, len, len1, ref, ref1;

Velocity = require("velocity-animate");

items = require("apply!callback!./client-item-getter");

components = {
  greeting: require("./client-greeting"),
  finished: require("./client-finished")
};

ref = items.config;
for (j = 0, len = ref.length; j < len; j++) {
  c = ref[j];
  components[c.name] = c.comp;
}

ref1 = items.install;
for (k = 0, len1 = ref1.length; k < len1; k++) {
  i = ref1[k];
  components[i.name] = i.comp;
}

module.exports = {
  components: components,
  computed: {
    currentCompName: function() {
      this.$nextTick((function(_this) {
        return function() {
          if (_this.$refs.comp.nextText) {
            return _this.nextText = _this.$refs.comp.nextText;
          } else {
            return _this.nextText = "next";
          }
        };
      })(this));
      switch (this.state) {
        case "greeting":
          return "greeting";
        case "config":
          return items.config[this.currentComp].name;
        case "install":
          return items.install[this.currentComp].name;
        case "finished":
          return "finished";
      }
    }
  },
  data: function() {
    return {
      nextText: "next",
      isValid: true,
      hasPrev: false,
      processing: false,
      state: "greeting",
      currentComp: 0
    };
  },
  methods: {
    next: function() {
      if (this.isValid && !this.processing) {
        this.processing = true;
        if (this.currentCompName === "greeting") {
          return this.samjs.install.onceConfigure.then(this.goToFirstConfigItem)["catch"]((function(_this) {
            return function() {
              return _this.samjs.install.onceInstall.then(_this.goToFirstInstallItem)["catch"](_this.goToFinished);
            };
          })(this));
        } else if (this.currentCompName === "finished") {
          return document.location.reload();
        } else if (this.state === "config") {
          return this.$refs.comp.next().then((function(_this) {
            return function() {
              if (_this.currentComp === (items.config.length - 1)) {
                return _this.samjs.install.onceInstall.then(_this.goToFirstInstallItem)["catch"](_this.goToFinished);
              } else {
                return _this.goTo(_this.currentComp + 1);
              }
            };
          })(this))["catch"](this.doNothing);
        } else if (this.state === "install") {
          return this.$refs.comp.next().then((function(_this) {
            return function() {
              if (_this.currentComp === (items.install.length - 1)) {
                return _this.samjs.install.onceInstalled.then(_this.goToFinished);
              } else {
                return _this.goTo(_this.currentComp + 1);
              }
            };
          })(this))["catch"](this.doNothing);
        }
      }
    },
    doNothing: function(e) {
      return this.processing = false;
    },
    goToFirstConfigItem: function() {
      this.currentComp = 0;
      this.processing = false;
      this.hasPrev = false;
      return this.state = "config";
    },
    goToFirstInstallItem: function() {
      this.currentComp = 0;
      this.processing = false;
      this.hasPrev = false;
      return this.state = "install";
    },
    goToFinished: function() {
      this.currentComp = 0;
      this.processing = false;
      this.hasPrev = false;
      this.isValid = true;
      return this.state = "finished";
    },
    goTo: function(newIndex) {
      if (this.state === "config") {
        this.currentComp = items.config[newIndex];
      } else if (this.state === "install") {
        this.currentComp = items.install[newIndex];
      }
      this.processing = false;
      return this.hasPrev = true;
    },
    prev: function() {
      var index;
      if (!this.processing) {
        this.processing = true;
        if (this.state === "config") {
          if (this.currentComp === 1) {
            return this.goToFirstConfigItem();
          } else {
            return this.goTo(this.currentComp - 1);
          }
        } else if (this.state === "install") {
          index = items.install.indexOf(this.currentComp);
          if (this.currentComp === 1) {
            return goToFirstInstallItem();
          } else {
            return this.goTo(this.currentComp - 1);
          }
        }
      }
    },
    validityChanged: function(isValid) {
      return this.isValid = isValid;
    }
  },
  transitions: {
    "slide": {
      enter: function(el, done) {
        Velocity.hook(el, "translateY", "70%");
        Velocity.hook(el, "scaleX", "90%");
        return Velocity(el, {
          translateY: "0",
          opacity: 1,
          scaleX: 1
        }, {
          duration: 300,
          ease: "easeOutCubic",
          queue: false,
          complete: done
        });
      },
      leave: function(el, done) {
        var translateY;
        translateY = "-70%";
        return Velocity(el, {
          translateY: translateY,
          opacity: 0,
          scaleX: 0.9
        }, {
          duration: 300,
          ease: "easeOutCubic",
          queue: false,
          complete: done
        });
      }
    }
  }
};

if (module.exports.__esModule) module.exports = module.exports.default
;(typeof module.exports === "function"? module.exports.options: module.exports).template = "<div class=\"container\" id=\"install-container\"><div v-ref:comp=\"v-ref:comp\" :is=\"currentCompName\" :samjs=\"samjs\" tabindex=\"-1\" transition=\"slide\" @next=\"next\" @validity-changed=\"validityChanged\"><div class=\"card-action\"><a class=\"prev-button\" @click=\"prev\" @keyup.13=\"prev\" v-if=\"hasPrev\" :class=\"{disabled: processing}\">back</a><div class=\"right-align\"><a class=\"next-button\" @click=\"next\" @keyup.13=\"next\" :class=\"{disabled: processing || !isValid}\">{{nextText}}</a></div></div></div></div>"
if (module.hot) {(function () {  module.hot.accept()
  var hotAPI = require("vue-hot-reload-api")
  hotAPI.install(require("vue"), true)
  if (!hotAPI.compatible) return
  module.hot.dispose(function () {
    __vueify_insert__.cache["#install-container {\n  position: relative;\n}\n#install-container .slide-enter,\n#install-container .slide-leave {\n  position: absolute;\n  width: 100%;\n  top: 0;\n}\n#install-container .slide-enter {\n  opacity: 0;\n}\n#install-container .prev-button,\n#install-container .next-button {\n  cursor: pointer;\n}\n#install-container .prev-button.disabled,\n#install-container .next-button.disabled {\n  cursor: not-allowed;\n  color: #808080;\n}\n"] = false
    document.head.removeChild(__vueify_style__)
  })
  if (!module.hot.data) {
    hotAPI.createRecord("_v-b4d4dcce", module.exports)
  } else {
    hotAPI.update("_v-b4d4dcce", module.exports, (typeof module.exports === "function" ? module.exports.options : module.exports).template)
  }
})()}