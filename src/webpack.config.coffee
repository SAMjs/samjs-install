webpack = require "webpack"
autoprefixer = require "autoprefixer"
path = require "path"
HtmlWebpackPlugin = require('html-webpack-plugin')
module.exports =

  entry:
    install: path.resolve(__dirname,'client-index')

  module:
    loaders: [
      { test: /\.vue$/, loader: require.resolve("vue-loader")}
      { test: /\.html$/, loader: require.resolve("html-loader")}
      { test: /\.coffee$/, loader: "coffee-loader" }
      
      { test: /\.woff(\d*)\??(\d*)$/, loader: "url?limit=10000&mimetype=application/font-woff" }
      { test: /\.ttf\??(\d*)$/,    loader: require.resolve("file-loader") }
      { test: /\.eot\??(\d*)$/,    loader: require.resolve("file-loader") }
      { test: /\.svg\??(\d*)$/,    loader: require.resolve("file-loader") }

    ]
    postLoaders: [
      { test: /vue-icons/, loader: require.resolve("callback-loader")}
    ]
    noParse: [
      /velocity\.js/
      /json3\.js/
      /bluebird\.js/
    ]

  resolve:
    extensions: ['', '.js', '.vue', '.coffee', '.scss', '.css']
    alias:
      'vmat': path.resolve(require.resolve('vue-materialize'),"../..")
      'vue': require.resolve('vue')

  plugins: [
    new HtmlWebpackPlugin
      title: "SAMjs Installation"
      filename: "index.html"
      template:  path.resolve(__dirname,'../lib/client-index.html')
      inject: true
  ]
