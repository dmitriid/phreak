const path                    = require('path')
const glob                    = require('glob')
const MiniCssExtractPlugin    = require('mini-css-extract-plugin')
const UglifyJsPlugin          = require('uglifyjs-webpack-plugin')
const OptimizeCSSAssetsPlugin = require('optimize-css-assets-webpack-plugin')
const CopyWebpackPlugin       = require('copy-webpack-plugin')

module.exports = (env, options) => ({
  optimization: {
    minimizer: [
      new UglifyJsPlugin({cache: true, parallel: true, sourceMap: false}),
      new OptimizeCSSAssetsPlugin({})
    ]
  },
  entry:        {
    './js/app.js': ['./js/app.js'].concat(glob.sync('./vendor/**/*.js'))
  },
  output:       {
    filename: 'app.js',
    path:     path.resolve(__dirname, '../priv/static/js')
  },
  module:       {
    rules: [
      {
        test:    /\.js$/,
        exclude: /node_modules/,
        use:     {
          loader: 'babel-loader'
        }
      },
      {
        test:    /\.css$/,
        exclude: /node_modules/,
        use:     [
          {loader: 'style-loader',},
          {loader: MiniCssExtractPlugin.loader},
          {loader: 'css-loader', options: {importLoaders: 1, url: false}},
          {loader: 'postcss-loader'},
        ]
      },
    ]
  },
  plugins:      [
    new MiniCssExtractPlugin({filename: '../css/app.css'}),
    new MiniCssExtractPlugin({filename: '../css/clr-ui.min.css'}),
    new MiniCssExtractPlugin({filename: '../css/clr-icons.min.css'}),
    new CopyWebpackPlugin([{from: 'static/', to: '../'}])
  ]
})
