ExtractTextPlugin = require("extract-text-webpack-plugin")
path = require "path"
module.exports =
  entry:
    materialize: path.resolve(__dirname,'./src/materialize.config.scss')
  output:
    path: path.resolve(__dirname,"./lib")
    filename: "empty"
  module:
    rules: [
      { test: /\.scss$/, use: ExtractTextPlugin.extract({
        fallback: "style-loader",
        use: ["css-loader","sass-loader"]})
        }
    ]
  plugins: [
    new ExtractTextPlugin("materialize.config.css")
  ]
