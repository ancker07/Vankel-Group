/** @type {import('tailwindcss').Config} */
export default {
  content: [
    "./index.html",
    "./src/**/*.{js,ts,jsx,tsx}",
    "./components/**/*.{js,ts,jsx,tsx}",
    "./**/*.{js,ts,jsx,tsx}",
  ],
  theme: {
    extend: {
      colors: {
        brand: {
          black: '#0a0a0a', // Main App Background
          green: {
            DEFAULT: '#22c55e', // Primary Action / Success
            dark: '#15803d',
            light: '#4ade80',
            10: 'rgba(34, 197, 94, 0.1)', // Active backgrounds
            20: 'rgba(34, 197, 94, 0.2)', // Borders
          },
          orange: {
            DEFAULT: '#f97316', // Maintenance / Delays
            10: 'rgba(249, 115, 22, 0.1)',
            20: 'rgba(249, 115, 22, 0.2)',
          }
        },
        zinc: {
          950: '#09090b', // Card Backgrounds
          900: '#18181b', // Surfaces / Inputs
          800: '#27272a', // Borders
          500: '#71717a', // Secondary Text
          400: '#a1a1aa', // Muted Text
          300: '#d4d4d8', // Primary Text
        }
      },
      fontFamily: {
        sans: ['Inter', 'sans-serif'],
      },
      borderRadius: {
        'xl': '0.75rem',
        '2xl': '1rem',
      },
      animation: {
        'in': 'fade-in 0.5s ease-out',
        'zoom-in': 'zoom-in-95 0.2s ease-out',
      },
      keyframes: {
        'fade-in': {
          '0%': { opacity: '0' },
          '100%': { opacity: '1' },
        },
        'zoom-in-95': {
          '0%': { transform: 'scale(0.95)', opacity: '0' },
          '100%': { transform: 'scale(1)', opacity: '1' },
        }
      }
    },
  },
  plugins: [],
}
