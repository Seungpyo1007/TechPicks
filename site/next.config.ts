import type { NextConfig } from "next";

const nextConfig: NextConfig = {
  outputFileTracingRoot: process.cwd(),
  // 배포 빌드에서는 테스트를 타입 검사하지 않는다. 자세한 이유는 tsconfig.build.json.
  typescript: { tsconfigPath: "tsconfig.build.json" },
  images: {
    remotePatterns: [
      {
        protocol: "https",
        hostname: "cdn.jsdelivr.net",
        pathname: "/gh/GetTechAPI/images/**",
      },
    ],
  },
};

export default nextConfig;
