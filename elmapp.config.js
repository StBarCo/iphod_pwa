module.exports = {
  configureWebpack: (config, env) => {
    const webpack = require('webpack');

     plugins: [
   //  new MiniCssExtractPlugin({ filename: '../css/app.css' }),
   // new CopyWebpackPlugin([{ from: 'static/', to: '../' }]),
   new webpack.ProvidePlugin({
    $: 'jquery',
    jQuery: 'jquery'
  })
 ]

    return config
  }
}