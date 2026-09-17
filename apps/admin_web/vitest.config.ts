import { defineConfig } from 'vitest/config';
import path from 'node:path';

export default defineConfig({
  test: {
    globals: true,
  },
  resolve: {
    alias: {
      demo_universe: path.resolve(__dirname, '../../packages/demo_universe/ts/index.ts'),
      '@': path.resolve(__dirname),
    },
  },
});
