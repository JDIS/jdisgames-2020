const esbuild = require('esbuild');
const esbuildVue = require('esbuild-plugin-vue-next');
const { copy } = require('esbuild-plugin-copy');

esbuild.build({
	entryPoints: {
		'js/app': 'js/app.js',
		'js/spectate': 'js/spectate.js',
		'js/scoreboard': 'js/scoreboard.js',
		'js/admin': 'js/admin.js',
		'css/app': 'css/app.css'
	},
	bundle: true,
	minify: true,
	sourcemap: 'linked',
	outdir: '../priv/static',
	plugins: [esbuildVue(), copy({ assets: { from: './static/**/*', to: '.'}, keepStructure: true })],
	watch: process.argv.includes('--watch'),
	target: 'es2020'
});
