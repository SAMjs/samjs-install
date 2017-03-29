path = require "path"
loaderUtils = require "loader-utils"

module.exports = (source, map) ->
  options = loaderUtils.getOptions(@)
  items = []
  if options.configItems.length > 0
    s = "{#{options.configItems.join('},{')}}"
  else
    s = ""
  items.push "config: [#{s}]"
  if options.installItems.length > 0
    s = "{#{options.installItems.join('},{')}}"
  else
    s = ""
  items.push "install: [#{s}]"
  components = """{
    greeting: [{name:"ce-greeting", comp:require('#{options.greeting}')}],
    farewell: [{name:"ce-farewell", comp:require('#{options.farewell}')}],
    #{items.join(',\n')}
  }"""
  cb = @async?() || @callback
  cb(null,source.replace(/getComponents\(\);/g,components),map)