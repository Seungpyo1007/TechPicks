import Image from "next/image";
import Link from "next/link";
import { formatPrice } from "@/lib/format";
import type { PhoneListItem } from "@/lib/phone";

export function PhoneCard({ phone, rank }: { phone: PhoneListItem; rank: number }) {
  return (
    <article className="phone-card">
      <div className="rank" aria-label={`${rank}위`}>
        {String(rank).padStart(2, "0")}
      </div>
      <Link className="phone-image" href={`/phones/${phone.slug}`} tabIndex={-1} aria-hidden="true">
        {phone.imageUrl ? (
          <Image src={phone.imageUrl} alt="" width={220} height={220} unoptimized />
        ) : (
          <span>NO IMAGE</span>
        )}
      </Link>
      <div className="phone-card-copy">
        <p className="eyebrow">{phone.brandName}</p>
        <h2>
          <Link href={`/phones/${phone.slug}`}>{phone.name}</Link>
        </h2>
        <p className="summary-line">
          {phone.socName ?? "칩셋 정보 없음"} · {formatPrice(phone.priceUsd)}
        </p>
        <div className="score-line">
          <strong>{phone.overallScore?.toFixed(1) ?? "—"}</strong>
          <span>TechPicks score</span>
        </div>
      </div>
    </article>
  );
}
