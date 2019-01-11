/*
 * Copyright Elasticsearch B.V. and/or licensed to Elasticsearch B.V. under one
 * or more contributor license agreements. Licensed under the Elastic License;
 * you may not use this file except in compliance with the Elastic License.
 */

const path = require('path');
const TerserPlugin = require('terser-webpack-plugin');
const HTMLWebpackPlugin = require('html-webpack-plugin');
const CleanWebpackPlugin = require('clean-webpack-plugin');
const FaviconsWebpackPlugin = require('favicons-webpack-plugin');
const OptimizeCssAssetsPlugin = require('optimize-css-assets-webpack-plugin');

module.exports = {
  entry: {
    mapbox: './node_modules/mapbox-gl/dist/mapbox-gl.js',
    main: ['babel-polyfill', path.resolve(__dirname, 'public/main.js')]
  },
  mode: 'development',
  output: {
    path: path.resolve(__dirname, 'build/release'),
    filename: '[name].bundle.js'
  },
  module: {
    rules: [
      {
        test: /\.(png|jpg|gif)$/,
        use: ['file-loader']
      },
      {
        test: /\.css$/,
        use: ['style-loader', 'css-loader'],
      },
      {
        test: /\.scss$/,
        use: ['style-loader', 'css-loader', 'resolve-url-loader', 'postcss-loader', 'sass-loader'],
        exclude: /node_modules/
      },
      {
        test: /\.js$/,
        exclude: /node_modules\/(?!@elastic\/eui)/,
        use: {
          loader: 'babel-loader'
        }
      }
    ]
  },
  resolve: {
    alias: {
    }
  },
  optimization: {
    minimizer: [
      new TerserPlugin({
        exclude: /node_modules\/(?!mapbox-gl\/dist)/
      })
    ],
    occurrenceOrder: true,
    splitChunks: {
      chunks: 'all'
    },
  },
  plugins: [
    new CleanWebpackPlugin(['build/release']),
    new FaviconsWebpackPlugin('@elastic/eui/lib/components/icon/assets/app_ems.svg'),
    new HTMLWebpackPlugin({
      template: 'public/index.html',
      hash: true
    }),
    new OptimizeCssAssetsPlugin()
  ],
  stats: {
    colors: true
  },
  devtool: 'source-map',
  devServer: {
    contentBase: './build/release',
    compress: true
  }
};