import type { Metadata } from 'next';
import './globals.css';

export const metadata: Metadata = {
  title: 'MuscleMap Screenshot Generator',
};

export default function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <html lang="ja">
      <head>
        <link
          href="https://fonts.googleapis.com/css2?family=Noto+Sans+JP:wght@500;900&family=Inter:wght@500;700;900&display=swap"
          rel="stylesheet"
        />
      </head>
      <body className="bg-neutral-950 text-white">{children}</body>
    </html>
  );
}
