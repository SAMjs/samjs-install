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
    it "should work", ->