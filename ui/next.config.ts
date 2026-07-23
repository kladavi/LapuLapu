import type { NextConfig } from "next";
import path from "path";

const nextConfig: NextConfig = {
  /* config options here */
  reactCompiler: true,
  turbopack: {
    root: path.resolve(__dirname),
  },
  // V4.0 Sprint 26 - Quartz portal is emitted to ui/public/quartz/ as static
  // HTML with extensionless internal hrefs (e.g. ../decisions/d-40250bb7d6) and
  // relative CSS/JS refs (e.g. ./index.css). For directory-index pages the URL
  // MUST have a trailing slash so the browser resolves those relative refs
  // against the correct base; otherwise the CSS 404s and the portal renders
  // unstyled.
  //
  // trailingSlash: true tells Next.js the canonical URL form has a trailing
  // slash; it will 308 bare URLs (/quartz) to /quartz/ for us.
  trailingSlash: true,
  async rewrites() {
    return [
      // Portal root and section-index pages (serve their emitted index.html)
      { source: "/quartz/", destination: "/quartz/index.html" },
      { source: "/quartz/decisions/", destination: "/quartz/decisions/index.html" },
      { source: "/quartz/risks/", destination: "/quartz/risks/index.html" },
      { source: "/quartz/workstreams/", destination: "/quartz/workstreams/index.html" },
      { source: "/quartz/reports/", destination: "/quartz/reports/index.html" },
      { source: "/quartz/tags/", destination: "/quartz/tags/index.html" },
      // Generic extensionless leaf: /quartz/decisions/d-40250bb7d6 -> .html
      // (trailingSlash also normalizes this to /quartz/decisions/d-40250bb7d6/)
      { source: "/quartz/:path((?!.*\\.).+)/", destination: "/quartz/:path.html" },
    ];
  },
};

export default nextConfig;
