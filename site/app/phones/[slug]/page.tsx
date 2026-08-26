import type { Metadata } from "next";
import Image from "next/image";
import Link from "next/link";
import { notFound } from "next/navigation";
import { ScoreRing } from "@/components/score-ring";
import { getCatalogPhones } from "@/lib/catalog";
import { formatDate, formatOptional, formatPrice } from "@/lib/format";
import { phoneMetadata, productJsonLd } from "@/lib/seo";
import { getPhone } from "@/lib/techapi";

type PhonePageProps = { params: Promise<{ slug: string }> };

export async function generateStaticParams() {
  const phones = await getCatalogPhones();
  return phones.map((phone) => ({ slug: phone.slug }));
}

export async function generateMetadata({ params }: PhonePageProps): Promise<Metadata> {
  const { slug } = await params;
  const phone = await getPhone(slug);
  return phone ? phoneMetadata(phone) : {};
}

export default async function PhoneDetailPage({ params }: PhonePageProps) {
  const { slug } = await params;
  const phone = await getPhone(slug);
  if (!phone) notFound();

  const jsonLd = productJsonLd(phone);
  const scoreRows = [
    ["성능", phone.score?.performance],
    ["카메라", phone.score?.camera],
    ["배터리", phone.score?.battery],
    ["디스플레이", phone.score?.display],
    ["가치", phone.score?.value],
  ] as const;

  const specs = [
    ["칩셋", phone.soc?.name ?? "—"],
    ["RAM", formatOptional(phone.ram_gb, "GB")],
    ["저장 공간", phone.storage_options_gb.length ? phone.storage_options_gb.map((value) => `${value}GB`).join(" / ") : "—"],
    ["화면", [formatOptional(phone.display?.size_inch, '″'), phone.display?.type, formatOptional(phone.display?.refresh_hz, "Hz")].filter((value) => value !== "—" && value).join(" · ") || "—"],
    ["해상도", formatOptional(phone.display?.resolution)],
    ["배터리", formatOptional(phone.battery_mah, "mAh")],
    ["충전", `${formatOptional(phone.charging_wired_w, "W 유선")} · ${formatOptional(phone.charging_wireless_w, "W 무선")}`],
    ["크기", phone.dimensions ? `${formatOptional(phone.dimensions.height_mm)} × ${formatOptional(phone.dimensions.width_mm)} × ${formatOptional(phone.dimensions.depth_mm)}mm` : "—"],
    ["무게", formatOptional(phone.weight_g, "g")],
    ["방수·방진", formatOptional(phone.ip_rating)],
    ["운영체제", [phone.os, phone.os_version].filter(Boolean).join(" ") || "—"],
  ];

  return (
    <div className="shell page-stack detail-page">
      <script
        type="application/ld+json"
        dangerouslySetInnerHTML={{ __html: JSON.stringify(jsonLd).replaceAll("<", "\\u003c") }}
      />
      <div className="breadcrumb">
        <Link href="/phones">스마트폰 랭킹</Link><span>/</span><span>{phone.name}</span>
      </div>
      <section className="product-hero">
        <div className="product-visual">
          {phone.image_url ? (
            <Image src={phone.image_url} alt={`${phone.name} 제품 이미지`} width={520} height={520} priority />
          ) : (
            <span>이미지 준비 중</span>
          )}
        </div>
        <div className="product-intro">
          <p className="eyebrow">{phone.brand.name} · {phone.verified ? "VERIFIED" : "CATALOG"}</p>
          <h1>{phone.name}</h1>
          <p className="product-subline">{phone.soc?.name ?? "칩셋 정보 없음"}</p>
          <div className="product-facts">
            <span><small>출시</small>{formatDate(phone.release_date)}</span>
            <span><small>출시 가격</small>{formatPrice(phone.msrp_usd)}</span>
          </div>
          <div className="product-actions">
            <Link className="primary-button" href={`/compare?type=phone&ids=${phone.slug}`}>
              다른 제품과 비교
            </Link>
            <a className="secondary-button" href={`techpicks://device/${phone.slug}`}>앱에서 열기</a>
          </div>
        </div>
        <ScoreRing score={phone.score?.overall} />
      </section>

      <section className="detail-grid">
        <article className="panel score-panel">
          <p className="eyebrow">TECHPICKS SCORE</p>
          <h2>한눈에 보는 균형</h2>
          <div className="score-bars">
            {scoreRows.map(([label, value]) => (
              <div className="score-bar" key={label}>
                <span>{label}</span>
                <div><i style={{ width: `${value ?? 0}%` }} /></div>
                <strong>{value?.toFixed(1) ?? "—"}</strong>
              </div>
            ))}
          </div>
        </article>
        <article className="panel">
          <p className="eyebrow">SPECIFICATIONS</p>
          <h2>핵심 사양</h2>
          <dl className="spec-list">
            {specs.map(([label, value]) => (
              <div key={label}><dt>{label}</dt><dd>{value}</dd></div>
            ))}
          </dl>
        </article>
      </section>

      <section className="source-panel">
        <div><p className="eyebrow">SOURCES</p><h2>근거를 함께 봅니다.</h2></div>
        <ul>
          {phone.source_urls.length ? phone.source_urls.map((source) => (
            <li key={source}><a href={source} rel="noreferrer">{new URL(source).hostname} ↗</a></li>
          )) : <li>TechAPI 카탈로그</li>}
        </ul>
      </section>
    </div>
  );
}
