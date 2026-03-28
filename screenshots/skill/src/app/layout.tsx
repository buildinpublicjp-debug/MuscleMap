import type { Metadata } from "next";
import "./globals.css";

export const metadata: Metadata = {
  title: "MuscleMap Screenshot Generator",
  description: "App Store screenshot generator for MuscleMap",
};

export default function RootLayout({
  children,
}: Readonly<{ children: React.ReactNode }>) {
  return (
    <html lang="ja">
      <body className="bg-black min-h-screen">{children}</body>
    </html>
  );
}
