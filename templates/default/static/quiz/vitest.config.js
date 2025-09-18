import { defineConfig } from 'vitest/config';

export default defineConfig({
  test: {
    environment: 'jsdom',
    include: ['src/**/*.test.js', 'src/**/*.spec.js'],
  },
  resolve: {
    extensions: ['.js', '.json'],
  },
});
