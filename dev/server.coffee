samjs = require "samjs"
path = require "path"
fs = samjs.Promise.promisifyAll(require("fs"))
testConfigFile = "test/testConfig.json"
fs.unlinkAsync testConfigFile
.catch -> return true
.finally ->
  samjs
  .plugins(require("../src/main.coffee")())
  .options({config:testConfigFile})
  .configs(
    name:"test"
    installComp:
      paths: [path.resolve(__dirname, "./config")]
      icons: ["material-person"]
    isRequired: true
    test: (val) -> new samjs.Promise (resolve, reject) ->
      if val == "correct"
        resolve()
      else
        reject()
  )
  .models(
    name:"test"
    installComp:
      paths: [path.resolve(__dirname, "./install")]
      icons: ["material-vpn_key"]
    isRequired: true
    test: -> new samjs.Promise (resolve, reject) =>
      if @val == "correct"
        resolve()
      else
        reject()
    installInterface: (socket) ->
      socket.on "test", (request) =>
        if request.token?
          @val = request.content
          samjs.state.checkInstalled()
          socket.emit "test.#{request.token}", success: true
      return ->
        if socket?
          socket.removeAllListeners "test"
  )
  .startup()
  .on "started", -> samjs.io.listen(8080)