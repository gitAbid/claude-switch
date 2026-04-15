# ClaudeSwitch Landing Page Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Create a modern, dark-mode landing page for ClaudeSwitch featuring a hero section, features list, screenshot, GitHub release download button, and author credits.

**Architecture:** Next.js 14 App Router, Tailwind CSS for styling, Framer Motion for smooth entrance animations, and standard Lucide-React icons. The app uses a dark Apple-style aesthetic (Slate-950 background, Inter/Space Grotesk typography). It dynamically fetches the latest DMG download URL from the GitHub repository via the GitHub REST API.

**Tech Stack:** Next.js, Tailwind CSS, Framer Motion, Lucide React

---

### Task 1: Setup Next.js Workspace & Dependencies

**Files:**
- Create: `website/package.json` (auto-generated)
- Create: `website/tailwind.config.ts` (auto-generated)

- [ ] **Step 1: Initialize Next.js app in non-interactive mode**

```bash
npx create-next-app website --ts --eslint --tailwind --app --src-dir --import-alias "@/*" --use-npm --yes
```

- [ ] **Step 2: Install required UI dependencies**

```bash
cd website && npm install framer-motion lucide-react clsx tailwind-merge
```

- [ ] **Step 3: Configure static export for GitHub Pages**

Update `website/next.config.mjs` to enable static SPA export:
```js
/** @type {import('next').NextConfig} */
const nextConfig = {
  output: "export",
  images: {
    unoptimized: true
  }
};

export default nextConfig;
```

- [ ] **Step 4: Commit the initial setup**

```bash
git add website
git commit -m "chore: initialize Next.js landing page workspace for static export"
```

---

### Task 2: Configure Global Styles and Fonts

**Files:**
- Modify: `website/src/app/layout.tsx`
- Modify: `website/src/app/globals.css`

- [ ] **Step 1: Update globals.css for dark mode base**

Replace the contents of `website/src/app/globals.css` with:
```css
@tailwind base;
@tailwind components;
@tailwind utilities;

@layer base {
  body {
    @apply bg-slate-950 text-slate-50 antialiased selection:bg-blue-600/30 selection:text-blue-100;
  }
}
```

- [ ] **Step 2: Setup Inter and Space Grotesk fonts in layout**

Replace the contents of `website/src/app/layout.tsx` with:
```tsx
import type { Metadata } from "next";
import { Inter, Space_Grotesk } from "next/font/google";
import "./globals.css";

const inter = Inter({ subsets: ["latin"], variable: "--font-inter" });
const space = Space_Grotesk({ subsets: ["latin"], variable: "--font-space" });

export const metadata: Metadata = {
  title: "ClaudeSwitch | macOS Menu Bar App",
  description: "A fast, native macOS menu bar app for managing AI model profiles.",
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="en" className="dark">
      <body className={`${inter.variable} ${space.variable} font-sans min-h-screen flex flex-col`}>
        {children}
      </body>
    </html>
  );
}
```

- [ ] **Step 3: Commit layout changes**

```bash
git add website/src/app/layout.tsx website/src/app/globals.css
git commit -m "style: configure dark mode base and typography"
```

---

### Task 3: Build GitHub Release Download Button Component

**Files:**
- Create: `website/src/components/DownloadButton.tsx`

- [ ] **Step 1: Create the animated client component**

```tsx
"use client";

import { useEffect, useState } from "react";
import { motion } from "framer-motion";
import { Download, Loader2 } from "lucide-react";

export default function DownloadButton() {
  const [downloadUrl, setDownloadUrl] = useState<string>("https://github.com/gitAbid/claude-switch/releases/latest");
  const [version, setVersion] = useState<string>("...");
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    async function fetchLatestRelease() {
      try {
        const res = await fetch("https://api.github.com/repos/gitAbid/claude-switch/releases/latest");
        const data = await res.json();
        
        if (data.tag_name) {
          setVersion(data.tag_name);
        }
        
        const asset = data.assets?.find((a: any) => a.name.endsWith(".dmg"));
        if (asset?.browser_download_url) {
          setDownloadUrl(asset.browser_download_url);
        }
      } catch (error) {
        console.error("Failed to fetch release:", error);
      } finally {
        setLoading(false);
      }
    }
    fetchLatestRelease();
  }, []);

  return (
    <motion.a
      href={downloadUrl}
      whileHover={{ scale: 1.05 }}
      whileTap={{ scale: 0.95 }}
      className="inline-flex items-center gap-3 bg-blue-600 hover:bg-blue-500 text-white px-8 py-4 rounded-full font-semibold transition-colors shadow-lg shadow-blue-900/20"
    >
      {loading ? (
        <Loader2 className="w-5 h-5 animate-spin" />
      ) : (
        <Download className="w-5 h-5" />
      )}
      <span>Download for macOS</span>
      {!loading && (
        <span className="text-blue-200 text-sm font-normal border-l border-blue-400 pl-3">
          {version}
        </span>
      )}
    </motion.a>
  );
}
```

- [ ] **Step 2: Commit download component**

```bash
git add website/src/components/DownloadButton.tsx
git commit -m "feat: add dynamic GitHub release download button"
```

---

### Task 4: Assemble the Landing Page

**Files:**
- Modify: `website/src/app/page.tsx`
- Copy Image: Screenshot needs to be copied into `website/public/screenshot.png` (assuming a screenshot exists or can be generated/placed later).

- [ ] **Step 1: Replace page.tsx with the landing structure**

```tsx
"use client";

import { motion } from "framer-motion";
import { Monitor, Zap, Shield, Cpu, Github } from "lucide-react";
import DownloadButton from "@/components/DownloadButton";

const features = [
  {
    icon: <Cpu className="w-6 h-6 text-blue-400" />,
    title: "Native Execution",
    desc: "Built with Swift for blazing fast performance on macOS."
  },
  {
    icon: <Zap className="w-6 h-6 text-blue-400" />,
    title: "Instant Switching",
    desc: "Change AI model profiles in just two clicks directly from the menu bar."
  },
  {
    icon: <Shield className="w-6 h-6 text-blue-400" />,
    title: "Local & Secure",
    desc: "Your API keys and tokens are securely stored locally on your machine."
  }
];

export default function Home() {
  return (
    <main className="flex-1">
      {/* Hero Section */}
      <section className="relative px-6 pt-32 pb-20 text-center max-w-5xl mx-auto">
        <div className="absolute top-0 inset-x-0 h-96 bg-gradient-to-b from-blue-900/20 border-b border-transparent mask-image-b" />
        
        <motion.div 
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.5 }}
          className="relative z-10"
        >
          <div className="inline-flex items-center gap-2 px-3 py-1 rounded-full bg-slate-900 border border-slate-800 text-sm text-slate-300 mb-8">
            <span className="flex h-2 w-2 rounded-full bg-blue-500"></span>
            v0.0.1 Now Available
          </div>
          
          <h1 className="text-5xl md:text-7xl font-bold tracking-tight mb-8 font-space text-transparent bg-clip-text bg-gradient-to-br from-white to-slate-400">
            Control your AI models <br className="hidden md:block" />
            from the menu bar.
          </h1>
          
          <p className="text-xl text-slate-400 mb-12 max-w-2xl mx-auto leading-relaxed">
            ClaudeSwitch is a swift-native macOS menubar app designed to easily switch connections, manage API keys, and map models for AI APIs like Gemini, Claude, and more.
          </p>
          
          <div className="flex flex-col sm:flex-row items-center justify-center gap-4">
            <DownloadButton />
            <a 
              href="https://github.com/gitAbid/claude-switch" 
              target="_blank" 
              rel="noopener noreferrer"
              className="inline-flex items-center gap-2 px-8 py-4 rounded-full font-semibold text-slate-300 bg-slate-900 border border-slate-800 hover:bg-slate-800 transition-colors"
            >
              <Github className="w-5 h-5" />
              View Source
            </a>
          </div>
        </motion.div>
      </section>

      {/* Screenshot Section */}
      <section className="px-6 pb-24">
        <motion.div 
          initial={{ opacity: 0, y: 40 }}
          whileInView={{ opacity: 1, y: 0 }}
          viewport={{ once: true }}
          transition={{ duration: 0.7 }}
          className="max-w-4xl mx-auto rounded-xl p-2 bg-slate-800/50 border border-slate-700/50 shadow-2xl backdrop-blur-sm"
        >
          {/* We use a placeholder div that users can replace with an actual img tag later */}
          <div className="aspect-[16/10] bg-slate-900 rounded-lg flex items-center justify-center border border-slate-800 overflow-hidden relative">
            <Monitor className="w-16 h-16 text-slate-700" />
            <p className="absolute text-slate-500 mt-24">ClaudeSwitch Interface</p>
          </div>
        </motion.div>
      </section>

      {/* Features List */}
      <section className="bg-slate-900/50 border-y border-slate-800 px-6 py-24">
        <div className="max-w-6xl mx-auto">
          <div className="grid md:grid-cols-3 gap-12">
            {features.map((feature, idx) => (
              <motion.div 
                key={idx}
                initial={{ opacity: 0, y: 20 }}
                whileInView={{ opacity: 1, y: 0 }}
                viewport={{ once: true }}
                transition={{ duration: 0.5, delay: idx * 0.1 }}
              >
                <div className="w-12 h-12 rounded-lg bg-blue-900/20 border border-blue-800/30 flex items-center justify-center mb-6">
                  {feature.icon}
                </div>
                <h3 className="text-xl font-bold mb-3 font-space">{feature.title}</h3>
                <p className="text-slate-400 leading-relaxed">
                  {feature.desc}
                </p>
              </motion.div>
            ))}
          </div>
        </div>
      </section>

      {/* Author & Footer */}
      <footer className="px-6 py-12 text-center text-slate-500 text-sm">
        <p>
          Built with precision by{" "}
          <a 
            href="https://abidhasan.tech/" 
            target="_blank" 
            rel="noopener noreferrer" 
            className="text-blue-400 hover:text-blue-300 hover:underline transition-colors"
          >
            Abid Hasan
          </a>
        </p>
      </footer>
    </main>
  );
}
```

- [ ] **Step 2: Commit page changes**

```bash
git add website/src/app/page.tsx
git commit -m "feat: assemble landing page UI with Hero, Features, and Footer"
```

---

### Task 5: Verify the Build

- [ ] **Step 1: Run the build locally to ensure no TS or Tailwind errors**

```bash
cd website && npm run build
```
Expected: successful build output with generated static/server routes.

- [ ] **Step 2: Add script to run site locally in README**

```bash
echo -e "\n## Website\nTo develop the landing page locally:\n\`\`\`bash\ncd website\nnpm install\nnpm run dev\n\`\`\`" >> README.md
git add README.md
git commit -m "docs: add instructions for running the website"
```
