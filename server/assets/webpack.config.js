const path = require('path');
const glob = require('glob');
const MiniCssExtractPlugin = require('mini-css-extract-plugin');
const TerserPlugin = require('terser-webpack-plugin');
const CSSMinimizerPlugin = require('css-minimizer-webpack-plugin');
const CopyWebpackPlugin = require('copy-webpack-plugin');
const { VueLoaderPlugin } = require('vue-loader');

module.exports = (env, options) => ({
  optimization: {
    minimizer: [
      new TerserPlugin({ parallel: true }),
      new CSSMinimizerPlugin()
    ]
  },
  entry: {
    app: glob.sync('./vendor/**/*.js').concat(['./js/app.js']),
    spectate: glob.sync('./modules/**/*.js').concat(['./js/spectate.js']),
    scoreboard: glob.sync('./modules/**/*.js').concat(['./js/scoreboard.js']),
    admin: glob.sync('./modules/**/*.js').concat(['./js/admin.js']),
  },
  output: {
    filename: '[name].js',
    path: path.resolve(__dirname, '../priv/static/js')
  },
  module: {
    rules: [
      {
        test: /\.vue$/,
        exclude: /node_modules/,
        loader: 'vue-loader',
      },
      {
        test: /\.js$/,
        exclude: /node_modules/,
        use: {
          loader: 'babel-loader'
        }
      },
      {
        test: /\.css$/,
        use: [MiniCssExtractPlugin.loader, 'css-loader']
      }
    ]
  },
  plugins: [
    new MiniCssExtractPlugin({ filename: '../css/app.css' }),
    new CopyWebpackPlugin({ patterns: [{ from: 'static/', to: '../' }] }),
    new VueLoaderPlugin()
  ]
});
