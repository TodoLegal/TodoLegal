/** @type {import('tailwindcss').Config} */
module.exports = {
  content: [
    './app/views/todolegal_ai/**/*.html.erb',
    './app/views/layouts/todolegal_ai.html.erb',
    './app/views/layouts/todolegal_ai_email.html.erb',
  ],
  theme: {
    extend: {
      colors: {
        brand: {
          50: '#F1F5F9',
          100: '#E2E8F0',
          200: '#CBD5E1',
          300: '#94A3B8',
          400: '#475569',
          500: '#1E40AF',
          600: '#1E3A8A',
          700: '#172554',
          800: '#0F172A',
          900: '#020617',
        },
        cream: {
          50: '#FAFAF7',
          100: '#F5F2EA',
          200: '#E8E4DA',
        },
        ink: '#1A2B4A',
        warmdark: '#1A1815',
      },
      fontFamily: {
        sans: ['Inter', 'system-ui', 'sans-serif'],
        serif: ['"Source Serif 4"', 'Georgia', 'serif'],
      },
      borderRadius: {
        '3xl': '1.5rem',
        '4xl': '1.75rem',
      },
    },
  },
  plugins: [],
}
