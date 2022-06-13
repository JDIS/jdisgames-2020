const esbuild = require('esbuild');
const esbuildVue = require('esbuild-plugin-vue-next');
const { copy } = require('esbuild-plugin-copy');

const shouldWatch = process.argv.includes('--watch')

// Abort the watcher if stdin is closed to avoid zombie processes
if (shouldWatch) {
	process.stdin.on('end', () => process.exit(0))
	process.stdin.resume()
}

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
	watch: shouldWatch,
	target: 'es2020'
});
