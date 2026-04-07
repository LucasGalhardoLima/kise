import { defineConfig, Plugin } from "vitest/config";

function mockWasm(): Plugin {
  return {
    name: "mock-wasm",
    enforce: "pre",
    resolveId(source) {
      if (source.endsWith(".wasm")) {
        return "\0virtual:mock-wasm";
      }
    },
    load(id) {
      if (id === "\0virtual:mock-wasm") {
        return "export default {}";
      }
    },
  };
}

export default defineConfig({
  plugins: [mockWasm()],
  resolve: {
    alias: {
      "@resvg/resvg-wasm": "@resvg/resvg-js",
    },
  },
});
