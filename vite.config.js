// const Path = require('path');
import * as Path from 'path';
// const vuePlugin = require('@vitejs/plugin-vue')
import vuePlugin from '@vitejs/plugin-vue';
import { viteCommonjs } from '@originjs/vite-plugin-commonjs';
// const { defineConfig } = require('vite');
import { defineConfig } from 'vite';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = Path.dirname(__filename);


/**
 * https://vitejs.dev/config
 */
const config = defineConfig({
    root: Path.join(__dirname, 'src', 'renderer'),
    publicDir: 'public',
    server: {
        port: 8080,
    },
    open: false,
    build: {
        outDir: Path.join(__dirname, 'build', 'renderer'),
        emptyOutDir: true,
    },
    plugins: [vuePlugin(), viteCommonjs()],
});

export default config;
