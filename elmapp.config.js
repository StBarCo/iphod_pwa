module.exports = {
  configureWebpack: (config, env) => {
    const webpack = require('webpack');

     plugins: [
       //  new MiniCssExtractPlugin({ filename: '../css/app.css' }),
       // new CopyWebpackPlugin([{ from: 'static/', to: '../' }]),
       new webpack.ProvidePlugin({
        $: 'jquery',
        jQuery: 'jquery',
        PDBFind: 'pouchdb-find'
      })
     ]

    return config
  },
  homepage: "https://bcp2019.com"
}