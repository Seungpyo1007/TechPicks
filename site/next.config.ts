import type { NextConfig } from "next";

const nextConfig: NextConfig = {
  outputFileTracingRoot: process.cwd(),
  // 배포 빌드에서는 테스트를 타입 검사하지 않는다. 자세한 이유는 tsconfig.build.json.
  typescript: { tsconfigPath: "tsconfig.build.json" },
  // 스냅샷은 경로를 실행 중에 만들어 읽기 때문에 Next 의 파일 추적이 잡아내지 못한다.
  // 명시하지 않으면 /build 와 /compare 같은 동적 화면이 서버리스에서 ENOENT 로 죽는다.
  outputFileTracingIncludes: { "/**": ["./data/*.json"] },
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
