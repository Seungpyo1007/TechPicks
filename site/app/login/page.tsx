import type { Metadata } from "next";
import Image from "next/image";
import Link from "next/link";
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
 * 게이트가 아니다 — 랭킹·상세·비교는 로그인 없이 열린다. 인증 백엔드는 아직 붙지 않아
 * 폼은 동작하지 않는 상태로 두고, 그 사실을 화면에 적었다.
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

        <h2>계정으로 계속하기</h2>

        <div className="login-field">
          <label htmlFor="tp-email">이메일</label>
          <input id="tp-email" className="input" type="email" placeholder="you@techpicks.app" style={{ minHeight: 50 }} />
        </div>
        <div className="login-field">
          <label htmlFor="tp-pw">비밀번호</label>
          <input id="tp-pw" className="input" type="password" placeholder="••••••••" style={{ minHeight: 50 }} />
        </div>

        <p className="note" style={{ margin: 0 }}>
          인증 연동은 아직 준비 중입니다. 랭킹 · 상세 · 비교는 로그인 없이 볼 수 있습니다.
        </p>

        <div style={{ display: "flex", flexDirection: "column", gap: 10 }}>
          <button className="btn btn-primary" type="button" style={{ height: 46 }} disabled>
            로그인
          </button>
          <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr", gap: 10 }}>
            <button className="btn btn-secondary" type="button" style={{ height: 44 }} disabled>
              Google
            </button>
            <button className="btn btn-secondary" type="button" style={{ height: 44 }} disabled>
              Apple
            </button>
          </div>
          <Link className="btn btn-ghost" href="/">
            익명으로 둘러보기
          </Link>
        </div>
      </section>
    </div>
  );
}
