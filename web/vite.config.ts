import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'
import path from 'path'

// https://vitejs.dev/config/
export default defineConfig({
  plugins: [react({
    // Optimize React development
    babel: {
      plugins: process.env.NODE_ENV === 'development' ? [] : []
    }
  })],
  resolve: {
    alias: {
      '@': path.resolve(__dirname, './src'),
    },
  },
  server: {
    port: 3000,
    host: true,
    open: false, // Don't auto-open browser
  },
  build: {
    target: 'es2020',
    outDir: 'dist',
    sourcemap: true,
    minify: 'esbuild',
    chunkSizeWarningLimit: 1000,
    rollupOptions: {
      output: {
        // Chunk splitting strategy
        manualChunks: {
          // React ecosystem
          'react-vendor': ['react', 'react-dom'],
          // Canvas and graphics
          'canvas-vendor': ['fabric'],
          // Utilities
          'utils-vendor': ['uuid']
        },
        // Asset naming for better caching
        chunkFileNames: 'assets/[name]-[hash].js',
        entryFileNames: 'assets/[name]-[hash].js',
        assetFileNames: 'assets/[name]-[hash].[ext]'
      }
    },
    // Optimize CSS
    cssCodeSplit: true,
    // Asset processing
    assetsInlineLimit: 4096, // 4KB
    // Terser options for better minification
    terserOptions: {
      compress: {
        drop_console: true,
        drop_debugger: true
      }
    }
  },
  optimizeDeps: {
    include: ['fabric', 'uuid', 'react', 'react-dom'],
  },
  // CSS processing
  css: {
    devSourcemap: true,
    modules: {
      localsConvention: 'camelCase'
    }
  },
  // Define global constants
  define: {
    __APP_VERSION__: JSON.stringify(process.env.npm_package_version || '1.0.0'),
    __BUILD_TIME__: JSON.stringify(new Date().toISOString()),
  },
  // Preview configuration
  preview: {
    port: 4173,
    host: true,
    cors: true
  }
})