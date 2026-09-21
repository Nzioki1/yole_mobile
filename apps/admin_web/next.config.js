const path = require('path');

/** @type {import('next').NextConfig} */
const nextConfig = {
  transpilePackages: ['demo_universe'],
  reactStrictMode: true,
  // Monorepo: pin tracing root so Next does not pick ~/package-lock.json
  outputFileTracingRoot: path.join(__dirname, '../..'),
};

module.exports = nextConfig;
