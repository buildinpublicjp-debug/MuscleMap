import type { Config } from 'tailwindcss';

const config: Config = {
  content: ['./src/**/*.{js,ts,jsx,tsx,mdx}'],
  theme: {
    extend: {
      colors: {
        mm: {
          bg: '#070A07',
          card: '#111411',
          brand: '#00FFB3',
          gold: '#FFD700',
          blue: '#00D4FF',
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
