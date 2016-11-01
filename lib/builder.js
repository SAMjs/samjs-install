(function() {
  var path, samjs;

  path = require("path");

  require("coffee-script/register");

  samjs = require("samjs");

  module.exports = function(options) {
    var bootstrap;
    if (!(options.args.length > 0)) {
      throw new Error("no bootstrap file provided");
    }
    bootstrap = require(path.resolve(options.args[0]));
    samjs.__samjsinstallbuild = options.out || true;
    return bootstrap(samjs);
  };

}).call(this);
