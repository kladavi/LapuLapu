import type { NextConfig } from "next";
import path from "path";

const nextConfig: NextConfig = {
  /* config options here */
  reactCompiler: true,
  turbopack: {
    root: path.resolve(__dirname),
  },
  // V4.0 Sprint 26 - Quartz portal is emitted to ui/public/quartz/ as static
  // HTML with extensionless internal hrefs (e.g. ../decisions/d-40250bb7d6).
  // These rewrites map extensionless and trailing-slash URLs to the actual
  // .html files that Next.js serves out of public/.
  async rewrites() {
    return [
      // Portal root
      { source: "/quartz", destination: "/quartz/index.html" },
      // Section-index pages (directories that have index.html but no sibling .html)
      { source: "/quartz/decisions", destination: "/quartz/decisions/index.html" },
      { source: "/quartz/risks", destination: "/quartz/risks/index.html" },
      { source: "/quartz/workstreams", destination: "/quartz/workstreams/index.html" },
      { source: "/quartz/reports", destination: "/quartz/reports/index.html" },
      // Generic extensionless: /quartz/decisions/d-40250bb7d6 -> .html
      { source: "/quartz/:path((?!.*\\.).+)", destination: "/quartz/:path.html" },
    ];
  },
};

export default nextConfig;
