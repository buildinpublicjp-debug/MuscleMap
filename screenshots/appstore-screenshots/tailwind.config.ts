import type { Config } from 'tailwindcss';

const config: Config = {
  content: ['./src/**/*.{js,ts,jsx,tsx,mdx}'],
  theme: {
    extend: {
      colors: {
        mm: {
          bg: '#070A07',
          green: '#00FFB3',
          blue: '#00D4FF',
          gold: '#FFD700',
        },
      },
      fontFamily: {
        jp: ['Noto Sans JP', 'Hiragino Sans', 'sans-serif'],
        en: ['Inter', 'SF Pro Display', 'sans-serif'],
      },
    },
  },
  plugins: [],
};

export default config;
