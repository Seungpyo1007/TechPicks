import type { Metadata } from "next";
import Image from "next/image";
import { LoginForm } from "@/components/auth/login-form";
import { LoginPreview, type PreviewCategory } from "@/components/shell/login-preview";
import { getCatalogCpus, getCatalogPhones, rankCpus, rankPhones } from "@/lib/catalog";
import { formatPrice } from "@/lib/format";
import { getLaptops } from "@/lib/laptop";
import { overallScore, percent } from "@/lib/score";

export const metadata: Metadata = {
  title: "로그인",
  description: "TechPicks 계정으로 계속하기.",
  // 로그인은 공개 화면의 관문이 아니다. 색인할 이유가 없다.
  robots: { index: false, follow: false },
};

/**
 * 정본 로그인 화면(`login-c.dc.html` 스타일).
 *
 * 게이트가 아니다 — 랭킹·상세·비교는 로그인 없이 열린다. 계정은 앱과 같은 Firebase 프로젝트라
 * 앱에서 만든 계정으로 그대로 들어온다.
 */
export default async function LoginPage() {
  const [phones, cpus, laptops] = await Promise.all([
    getCatalogPhones().then(rankPhones),
    getCatalogCpus().then(rankCpus),
    getLaptops(),
  ]);

  const maxMulti = Math.max(1, ...cpus.map((cpu) => cpu.score?.multi?.index ?? 0));
  const maxPrice = Math.max(1, ...laptops.map((laptop) => laptop.msrp_usd ?? 0));

  const categories: PreviewCategory[] = [
    {
      label: "스마트폰 상위 3",
      rows: phones.slice(0, 3).map((phone, index) => {
        const total = overallScore(phone);
        return {
          rank: String(index + 1),
          name: phone.name,
          percent: percent(total),
          value: String(total ?? "—"),
        };
      }),
    },
    {
      label: "CPU 멀티코어 상위 3",
      rows: cpus.slice(0, 3).map((cpu, index) => ({
        rank: String(index + 1),
        name: cpu.name,
        percent: percent(cpu.score?.multi?.index ?? null, maxMulti),
        value: cpu.score?.multi?.index ? String(Math.round(cpu.score.multi.index)) : "—",
      })),
    },
    {
      label: "노트북 구성",
      rows: laptops.slice(0, 3).map((laptop, index) => ({
        rank: String(index + 1),
        name: laptop.name,
        percent: percent(laptop.msrp_usd ?? null, maxPrice),
        value: formatPrice(laptop.msrp_usd),
      })),
    },
  ];

  return (
    <div className="login">
      <section className="login-stage">
        <div className="login-blobs" aria-hidden="true">
          <i />
          <i />
        </div>

        <div className="login-intro">
          <span className="kicker">이번 주 랭킹 · 2026</span>
          <h1>
            스펙으로
            <br />
            고르는 전자기기
          </h1>
        </div>

        <LoginPreview categories={categories} />

        <p className="note" style={{ position: "relative" }}>
          점수는 TechAPI 원본 스펙(성능·카메라·화면·배터리)에서 산출됩니다.{" "}
          <a href="https://github.com/GetTechAPI/TechAPI" target="_blank" rel="noreferrer">
            TechAPI · CC-BY-SA 4.0
          </a>
        </p>
      </section>

      <section className="login-form">
        <div className="sidebar-brand">
          <span className="brand-mark">
            <Image src="/brand/NBlogo.png" alt="" width={21} height={21} priority />
          </span>
          <span className="brand-name">TechPicks</span>
        </div>

        <LoginForm />
      </section>
    </div>
  );
}
