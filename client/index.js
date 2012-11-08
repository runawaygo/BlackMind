seajs.config({
	base: './',
	debug:true,
  	preload: ['plugin-coffee', 'plugin-less', 'plugin-text']
});


define(function(require) {
	console.log('seajs start');
	require('index.less');
	require('app/app');	
});
