path = require "path"
loaderUtils = require "loader-utils"

module.exports = (source, map) ->
  options = loaderUtils.getOptions(@)
  
  components = """{
    greeting: [{name:"greeting", comp:require('#{options.greeting}')}],
    farewell: [{name:"farewell", comp:require('#{options.farewell}')}],
    config: [{#{options.configItems.join('},{')}}],
    install: [{#{options.installItems.join('},{')}}]
  }"""
  cb = @async?() || @callback
  cb(null,source.replace(/getComponents\(\);/g,components),map)