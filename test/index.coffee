chai = require "chai"
should = chai.should()
chai.use require "chai-as-promised"
samjs = require "samjs"
samjsClient = require "samjs-client"
samjsFiles = require "samjs-files"
samjsFilesClient = require "samjs-files-client"
samjsFilesAuth = require "../src/plugin"
samjsAuth = require "samjs-auth"
samjsAuthClient = require "samjs-auth-client"
fs = samjs.Promise.promisifyAll(require("fs"))
path = require "path"
port = 3060
url = "http://localhost:"+port+"/"
testConfigFile = "test/testConfig.json"

testModel =
  name: "test"
  db: "files"
  files: testConfigFile
  write: "root"
  read: "root"
  plugins:
    auth: null
unlink = (file) ->
  fs.unlinkAsync file
  .catch -> return true

describe "samjs", ->
  client = null
  clientTest = null
  describe "files-auth", ->
    before ->
      samjs.reset().then ->
        unlink testConfigFile
    after ->
      promises = [unlink(testConfigFile)]
      promises.push samjs.shutdown() if samjs.shutdown?
      samjs.Promise.all promises
    it "should be accessible", ->
      samjs.plugins(samjsAuth(),samjsFiles,samjsFilesAuth)
      should.exist samjs.files
      should.exist samjs.auth
    it "should install", ->
      samjs.options({config:testConfigFile})
      .configs()
      .models(testModel)
      .startup().io.listen(port)
      client = samjsClient({
        url: url
        ioOpts:
          reconnection: false
          autoConnect: false
        })()
      client.plugins(samjsAuthClient,samjsFilesClient)
      client.auth.createRoot "rootroot"
    it "should startup", ->
      samjs.state.onceStarted
    describe "client", ->
      clientTest = null
      it "should be unaccessible",  ->
        clientTest = new client.Files("test")
        samjs.Promise.any [clientTest.get(),clientTest.set("something")]
        .should.be.rejected
      it "should auth", ->
        client.auth.login {name:"root",pwd:"rootroot"}
        .then (result) ->
          result.name.should.equal "root"
      it "should be able to set and get", ->
        clientTest.set("something")
        .then ->
          clientTest.get()
        .then (result) ->
          result.should.equal "something"
