/*
 * Original work Copyright (c) 2016 Edgardo Avilés, Michiel Helvensteijn
 * See LICENSE @ https://github.com/mhelvens/esdoc-babel-plugin/blob/dad7c82bde8d2b25c153fe7b20c03b12137cacf5/LICENSE
 */

const babel = require('@babel/core');
const path = require('path');

let babelOptions;

exports.onStart = function onStart(event) {
	if (typeof event.data.option !== 'object') {
		throw new Error(`Please supply an "option" object in the configuration of esdoc-babel-plugin.`);
	}
	babelOptions = event.data.option || {};
};

exports.onHandleCode = function onHandleCode(event) {
    const filename = path.basename(event.data.filePath)

	try {
		const result      = babel.transform(event.data.code, { filename, ...babelOptions });
		event.data.code = result.code;
	} catch (error) {
		console.error(error);
	}
};