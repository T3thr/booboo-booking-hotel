import type { NextConfig } from "next";

const nextConfig: NextConfig = {
  trailingSlash: false, // Changed to false to prevent trailing slash issues with API routes
  images: {
    unoptimized: process.env.NODE_ENV === 'production',
  },
};

export default nextConfig;
