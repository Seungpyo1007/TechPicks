import type { Metadata } from "next";
import { CpuTable } from "@/components/cpus/cpu-table";
import { getCatalogCpus, rankCpus } from "@/lib/catalog";
import { canonicalUrl } from "@/lib/seo";

export const metadata: Metadata = {
  title: "CPU 랭킹",
  description: "TechAPI 채점 기준 CPU 랭킹. 코어 구성·부스트 클럭·싱글/멀티 지수·TDP·가격을 한 표에서 봅니다.",
  alternates: { canonical: canonicalUrl("/cpus") },
};

export default async function CpusPage() {
  const cpus = rankCpus(await getCatalogCpus());

  return (
    <div className="stack">
      <CpuTable cpus={cpus} />
      <p className="note">
        멀티코어 지수 내림차순 · 총 {cpus.length}종 · Cinebench R23 기록에서 산출한 0–100 정규화 값
      </p>
    </div>
  );
}
