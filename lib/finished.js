module.exports = {
  props: ["samjs"],
  data: function() {
    return {
      nextText: "Done"
    };
  },
  ready: function() {
    return document.querySelector(".next-button").focus();
  }
};

if (module.exports.__esModule) module.exports = module.exports.default
;(typeof module.exports === "function"? module.exports.options: module.exports).template = "<div class=\"card black-text\"><div class=\"card-content\"><span class=\"card-title black-text\">Done!</span><p>Have fun with samjs little cms</p></div><slot></slot></div>"
if (module.hot) {(function () {  module.hot.accept()
  var hotAPI = require("vue-hot-reload-api")
  hotAPI.install(require("vue"), true)
  if (!hotAPI.compatible) return
  if (!module.hot.data) {
    hotAPI.createRecord("_v-b4d4dcce", module.exports)
  } else {
    hotAPI.update("_v-b4d4dcce", module.exports, (typeof module.exports === "function" ? module.exports.options : module.exports).template)
  }
})()}