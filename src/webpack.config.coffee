HtmlWebpackPlugin = require('html-webpack-plugin')
UglifyJSPlugin = require "uglifyjs-webpack-plugin"
ExtractTextPlugin = require("extract-text-webpack-plugin")
path = require "path"
webpack = require "webpack"
module.exports = (options) ->

  entry:
    install: path.resolve(__dirname,'samjs-install-client')

  #devtool: "source-map"

  output:
    publicPath: options.publicPath
    filename: "[name]_bundle.js"
    path: path.resolve(options.path)

  module:
    rules: [
      { test: /\.woff(\d*)\??(\d*)$/, use: "url-loader?limit=10000&mimetype=application/font-woff" }
      { test: /\.ttf\??(\d*)$/,    use: "file-loader" }
      { test: /\.eot\??(\d*)$/,    use: "file-loader" }
      { test: /\.svg\??(\d*)$/,    use: "file-loader" }
      { test: /\.css$/, use: ExtractTextPlugin.extract({
        fallback: "style-loader",
        use: ["css-loader"] })
        }
      { test: /\.scss$/, use: ExtractTextPlugin.extract({
        fallback: "style-loader",
        use: ["css-loader","sass-loader"]})
        }
      { test: /\.styl$/, use: ExtractTextPlugin.extract({
        fallback: "style-loader",
        use: ["css-loader","stylus-loader"]})
        }
      { test: /\.html$/, use: "html-loader"}
      { test: /\.coffee$/, use: "coffee-loader"}
      {
        test: /samjs-install-client/
        enforce: "post" 
        options: options
        loader: path.resolve(__dirname,"./items-loader")
      }
      {
        test: /\.(js|coffee)$/
        use: "ceri-loader"
        enforce: "post"
        exclude: /node_modules/
      }
      { 
        test: /ceri-icon\/icon/
        enforce: "post"
        loader: "ceri-icon"
        options: options
      }
    ]
  resolve:
    extensions: [".js", ".json", ".coffee",".scss",".css"]
    alias:
      ce: path.dirname(require.resolve("ceri"))
  resolveLoader:
    extensions: [".js", ".coffee"]
    modules:[
      "web_loaders"
      "web_modules"
      "node_loaders"
      "node_modules"
      path.resolve(__dirname,'../node_modules')
    ]
  plugins: [
    new webpack.DefinePlugin "process.env.NODE_ENV": JSON.stringify(if options.dev then "development" else "production")
    new UglifyJSPlugin
      compress:
        dead_code: true
        warnings: false
      mangle: !options.dev
      beautify: !!options.dev
      sourceMap: true
    new HtmlWebpackPlugin
      filename: "index.html"
      template:  path.resolve(__dirname,'../index.html')
      inject: true
    new ExtractTextPlugin("styles.css")
  ]
