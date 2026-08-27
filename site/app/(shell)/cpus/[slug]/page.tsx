import type { Metadata } from "next";
import { notFound } from "next/navigation";
import { CpuDetail } from "@/components/cpus/cpu-detail";
import { CpuTable } from "@/components/cpus/cpu-table";
import { getCatalogCpu, getCatalogCpus, rankCpus } from "@/lib/catalog";
import { canonicalUrl, isPreviewDeployment } from "@/lib/seo";

type Params = { params: Promise<{ slug: string }> };

export async function generateStaticParams() {
  const cpus = await getCatalogCpus();
  return cpus.map((cpu) => ({ slug: cpu.slug }));
}

export async function generateMetadata({ params }: Params): Promise<Metadata> {
  const { slug } = await params;
  const cpu = await getCatalogCpu(slug);
  if (!cpu) return { title: "찾을 수 없는 프로세서" };

  const description = [
    cpu.name,
    cpu.architecture,
    cpu.cores ? `${cpu.cores}코어` : null,
    cpu.boost_clock_ghz ? `최대 ${cpu.boost_clock_ghz}GHz` : null,
  ]
    .filter(Boolean)
    .join(" · ");

  return {
    title: `${cpu.name} 사양·점수`,
    description: `${description}. TechPicks 가 TechAPI 데이터로 채점한 결과입니다.`,
    alternates: { canonical: canonicalUrl(`/cpus/${cpu.slug}`) },
    robots: isPreviewDeployment() ? { index: false, follow: false } : undefined,
  };
}

export default async function CpuPage({ params }: Params) {
  const { slug } = await params;
  const cpu = await getCatalogCpu(slug);
  if (!cpu) notFound();

  const cpus = rankCpus(await getCatalogCpus());

  return (
    <div className="stack">
      <CpuDetail cpu={cpu} />
      <CpuTable cpus={cpus} activeSlug={cpu.slug} />
    </div>
  );
}
