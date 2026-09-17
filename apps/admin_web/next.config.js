/** @type {import('next').NextConfig} */
const nextConfig = {
  // Mac Color Admin next.config was not in the task-2 Mac copy set.
  // Minimal config required so Next can transpile the workspace TS package.
  transpilePackages: ['demo_universe'],
  reactStrictMode: true,
};

module.exports = nextConfig;
