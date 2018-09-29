const DuplicatePackageCheckerPlugin = require("duplicate-package-checker-webpack-plugin");
const MiniCssExtractPlugin = require('mini-css-extract-plugin');
const OptimizeCSSAssetsPlugin = require('optimize-css-assets-webpack-plugin');
const UglifyJsPlugin = require('uglifyjs-webpack-plugin');
const path = require('path');

module.exports = {
    entry: './src/js/index.js',
    output: {
        path: path.resolve(__dirname, 'public'),
        filename: 'app.min.js',
    },
    module: {
        rules: [
            {
                // look for .js or .jsx files
                test: /\.(js|jsx)$/,
                exclude: /(node_modules)/,
                use: [
                    'babel-loader'
                ]
            },
            {
                test: /\.(css|less)$/,
                include: path.resolve(__dirname, './src/less/index.less'),
                use: [
                    MiniCssExtractPlugin.loader,
                    'css-loader',
                    'less-loader'
                ],
            },
            {
                test: /\.(png|jpg|gif|svg)$/i,
                use: [
                    {
                        loader: 'url-loader',
                        options: {
                            name: '[path][name].[ext]',
                            context: 'src',
                            limit: 8192,
                        }
                    },
                    'image-webpack-loader',
                ]
            },
            {
                test: /\.(|woff|woff2|eot|ttf)$/i,
                use: [
                    {
                        loader: 'file-loader',
                        options: {
                            name: 'fonts/[name].[ext]',
                            context: 'src',
                        }
                    }
                ]
            },
            {
                test: /webfonts\/(.+?)\.svg$/i,
                use: [
                    {
                        loader: 'file-loader',
                        options: {
                            name: 'fonts/[name].[ext]',
                            context: 'src',
                        }
                    }
                ]
            }
        ]
    },
    plugins: [
        new MiniCssExtractPlugin({
            // Options similar to the same options in webpackOptions.output
            // both options are optional
            filename: 'app.min.css',
            chunkFilename: '[id].css'
        }),
        new DuplicatePackageCheckerPlugin()
    ],
    optimization: {
        minimizer: [
            new OptimizeCSSAssetsPlugin(),
            new UglifyJsPlugin()
        ],
    },
}