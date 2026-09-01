import path from "path";
import { defineConfig } from "vite";
import tailwindcss from "@tailwindcss/vite";

import react from "@vitejs/plugin-react";
import liveReactPlugin from "live_react/vite-plugin";

// https://vitejs.dev/config/
export default defineConfig(({ command }) => {
  const isDev = command !== "build";

  return {
    server: {
      port: parseInt(process.env.VITE_PORT) || 3300,
      host: '0.0.0.0', // listen on all network interfaces
      cors: true, // enable CORS for all origins in development
      strictPort: true, // fail if port is already in use
    },
    base: isDev ? undefined : "/assets",
    publicDir: "static",
    plugins: [react(), liveReactPlugin(), tailwindcss()],
    // SSR is resolved two completely different ways, so this config is split.
    //
    // In dev, LiveReact.SSR.ViteJS renders through the Vite dev server, which
    // resolves imports from assets/node_modules. React must stay EXTERNAL
    // there: Vite's dev module runner evaluates inlined modules as ESM, and
    // react/jsx-dev-runtime.js is CJS, so bundling it raises
    // "ReferenceError: module is not defined".
    //
    // In the build, LiveReact.SSR.NodeJS runs priv/react-components/server.js
    // directly under Node, with no node_modules reachable from priv/ — the
    // release never copies assets/node_modules and Docker's runner stage only
    // copies the release. So the bundle must be self-contained.
    ssr: isDev
      ? {
          external: [
            "react",
            "react-dom",
            "react-dom/server",
            "react/jsx-runtime",
            "react/jsx-dev-runtime",
          ],
          noExternal: ["live_react"],
        }
      : { noExternal: true },
    resolve: {
      alias: {
        "@": path.resolve(__dirname, "./react-components"),
      },
      dedupe: ["react", "react-dom"],
    },
    optimizeDeps: {
      // these packages are loaded as file:../deps/<name> imports
      // so they're not optimized for development by vite by default
      // we want to enable it for better DX
      // more https://vitejs.dev/guide/dep-pre-bundling#monorepos-and-linked-dependencies
      include: ["live_react", "phoenix", "phoenix_html", "phoenix_live_view"],
    },
    build: {
      commonjsOptions: { transformMixedEsModules: true },
      target: "es2020",
      outDir: "../priv/static/assets", // emit assets to priv/static/assets
      emptyOutDir: true,
      sourcemap: isDev, // enable source map in dev build
      manifest: false, // do not generate manifest.json
      rollupOptions: {
        input: {
          app: path.resolve(__dirname, "./js/app.js"),
        },
        output: {
          // remove hashes to match phoenix way of handling assets
          entryFileNames: "[name].js",
          chunkFileNames: "[name].js",
          assetFileNames: "[name][extname]",
        },
      },
    },
  };
});
