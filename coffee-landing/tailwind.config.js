/** @type {import('tailwindcss').Config} */
export default {
  content: [
    "./index.html",
    "./src/**/*.{js,ts,jsx,tsx}",
  ],
  theme: {
    extend: {
      colors: {
        coffee: {
          50: '#faf7f2',
          100: '#f5ede0',
          200: '#ead9c1',
          300: '#ddc19a',
          400: '#cfa572',
          500: '#b8864f',
          600: '#9d6d3f',
          700: '#7f5635',
          800: '#6a4630',
          900: '#5a3c2a',
        },
      },
    },
  },
  plugins: [],
}












