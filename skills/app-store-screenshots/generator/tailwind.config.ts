import type { Config } from 'tailwindcss';

const config: Config = {
  content: ['./src/**/*.{ts,tsx}'],
  theme: {
    extend: {
      colors: {
        mm: {
          bg: '#070A07',
          green: '#00FFB3',
          blue: '#00D4FF',
          gold: '#FFD700',
          card: '#1C1C1E',
          secondary: '#2C2C2E',
        },
      },
      fontFamily: {
        ja: ['Noto Sans JP', 'Hiragino Sans', 'sans-serif'],
        en: ['Inter', 'SF Pro Display', 'sans-serif'],
      },
    },
  },
  plugins: [],
};

export default config;
