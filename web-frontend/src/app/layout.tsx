import type { Metadata } from "next";
import "./globals.css";
import { Toaster } from "@/components/ui/sonner";

export const metadata: Metadata = {
  title: "悪魔的しりとり",
  description: "悪魔と言葉の勝負を挑め。汝の語彙力、試されるがよい。",
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="ja">
      <head>
        <link
          href="https://fonts.googleapis.com/css2?family=Cinzel:wght@400;600;700&family=Noto+Serif+JP:wght@400;500;700&display=swap"
          rel="stylesheet"
        />
      </head>
      <body className="bg-demon-black min-h-screen">
        {/* 背景の魔法陣 */}
        <div className="fixed inset-0 overflow-hidden pointer-events-none z-0">
          <div className="absolute top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 w-[800px] h-[800px] opacity-10">
            <svg
              viewBox="0 0 200 200"
              className="w-full h-full animate-rotate-slow"
            >
              <defs>
                <linearGradient
                  id="goldGradient"
                  x1="0%"
                  y1="0%"
                  x2="100%"
                  y2="100%"
                >
                  <stop offset="0%" stopColor="#D4AF37" />
                  <stop offset="50%" stopColor="#8B7124" />
                  <stop offset="100%" stopColor="#D4AF37" />
                </linearGradient>
              </defs>
              {/* 外側の円 */}
              <circle
                cx="100"
                cy="100"
                r="95"
                fill="none"
                stroke="url(#goldGradient)"
                strokeWidth="1"
              />
              <circle
                cx="100"
                cy="100"
                r="85"
                fill="none"
                stroke="url(#goldGradient)"
                strokeWidth="0.5"
              />
              {/* 六芒星 */}
              <polygon
                points="100,15 120,65 175,65 130,95 145,150 100,120 55,150 70,95 25,65 80,65"
                fill="none"
                stroke="url(#goldGradient)"
                strokeWidth="0.8"
              />
              {/* 内側の円 */}
              <circle
                cx="100"
                cy="100"
                r="50"
                fill="none"
                stroke="url(#goldGradient)"
                strokeWidth="0.5"
              />
              {/* ルーン文字風の装飾 */}
              <text
                x="100"
                y="100"
                textAnchor="middle"
                dominantBaseline="middle"
                fill="url(#goldGradient)"
                fontSize="8"
                fontFamily="serif"
                opacity="0.5"
              >
                ᚠᚢᚦᚨᚱᚲᚷᚹᚺᚾᛁᛃᛈᛇᛉᛊᛏᛒᛖᛗᛚᛜᛞᛟ
              </text>
            </svg>
          </div>
          {/* 追加の装飾円 */}
          <div className="absolute top-20 left-20 w-32 h-32 border border-demon-gold/20 rounded-full animate-pulse-glow" />
          <div
            className="absolute bottom-20 right-20 w-48 h-48 border border-demon-gold/10 rounded-full animate-pulse-glow"
            style={{ animationDelay: "1s" }}
          />
        </div>

        <main className="relative z-10 min-h-screen">{children}</main>
        <Toaster closeButton />
      </body>
    </html>
  );
}
