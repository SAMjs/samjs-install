webpack = require "webpack"
autoprefixer = require "autoprefixer"
path = require "path"
HtmlWebpackPlugin = require('html-webpack-plugin')
module.exports =

  entry:
    install: path.resolve(__dirname,'install')

  module:
    loaders: [
      { test: /\.vue$/, loader: "vue"}
      { test: /\.html$/, loader: "html"}
      { test: /\.coffee$/, loader: "coffee" }
      { test: /\.scss$/, loader: "style!css!sass" }
      { test: /\.css$/, loader: "style!css" }
      { test: /\.woff(\d*)\??(\d*)$/, loader: "url?limit=10000&mimetype=application/font-woff" }
      { test: /\.ttf\??(\d*)$/,    loader: "file" }
      { test: /\.eot\??(\d*)$/,    loader: "file" }
      { test: /\.svg\??(\d*)$/,    loader: "file" }

    ]
    postLoaders: [
      { test: /vue-icons/, loader: "callback-loader"}
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
      template:  path.resolve(__dirname,'../lib/install.html')
      inject: true
  ]
