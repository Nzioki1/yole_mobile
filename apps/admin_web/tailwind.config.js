/** @type {import('tailwindcss').Config} */
module.exports = {
  content: [
    './app/**/*.{js,ts,jsx,tsx,mdx}',
    './components/**/*.{js,ts,jsx,tsx,mdx}',
    './lib/**/*.{js,ts,jsx,tsx,mdx}',
  ],
  theme: {
    extend: {
      colors: {
        yole: {
          teal: '#00acac',
          'teal-dark': '#008a8a',
          blue: '#348fe2',
          green: '#32a932',
          red: '#ff5b57',
          yellow: '#f59c1a',
          purple: '#727cb6',
          ink: '#2d353c',
          muted: '#6c757d',
          canvas: '#d9e0e7',
          panel: '#ffffff',
          line: '#e2e7eb',
        },
      },
      fontFamily: {
        sans: [
          'Open Sans',
          '-apple-system',
          'BlinkMacSystemFont',
          'Segoe UI',
          'Roboto',
          'Helvetica Neue',
          'Arial',
          'sans-serif',
        ],
      },
      boxShadow: {
        panel: '0 0 4px rgba(0,0,0,0.1)',
      },
    },
  },
  plugins: [],
  // Avoid fighting Color Admin base resets where possible
  corePlugins: {
    // Color Admin default theme owns base/reset — don't fight it
    preflight: false,
  },
};
