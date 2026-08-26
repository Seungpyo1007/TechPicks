import Image from "next/image";
import { formatOptional, formatPrice } from "@/lib/format";
import type { Phone } from "@/lib/phone";

type Row = { label: string; values: [string, string] };

export function ComparisonTable({ phones }: { phones: [Phone, Phone] }) {
  const rows: Row[] = [
    { label: "종합 점수", values: phones.map((phone) => formatOptional(phone.score?.overall)) as [string, string] },
    { label: "출시 가격", values: phones.map((phone) => formatPrice(phone.msrp_usd)) as [string, string] },
    { label: "칩셋", values: phones.map((phone) => formatOptional(phone.soc?.name)) as [string, string] },
    { label: "RAM", values: phones.map((phone) => formatOptional(phone.ram_gb, "GB")) as [string, string] },
    {
      label: "저장 공간",
      values: phones.map((phone) =>
        phone.storage_options_gb.length ? phone.storage_options_gb.map((value) => `${value}GB`).join(" / ") : "—",
      ) as [string, string],
    },
    { label: "화면", values: phones.map((phone) => formatOptional(phone.display?.size_inch, '″')) as [string, string] },
    { label: "주사율", values: phones.map((phone) => formatOptional(phone.display?.refresh_hz, "Hz")) as [string, string] },
    { label: "배터리", values: phones.map((phone) => formatOptional(phone.battery_mah, "mAh")) as [string, string] },
    { label: "유선 충전", values: phones.map((phone) => formatOptional(phone.charging_wired_w, "W")) as [string, string] },
    { label: "무게", values: phones.map((phone) => formatOptional(phone.weight_g, "g")) as [string, string] },
    { label: "방수·방진", values: phones.map((phone) => formatOptional(phone.ip_rating)) as [string, string] },
  ];

  return (
    <div className="comparison-scroll">
      <table className="comparison-table">
        <thead>
          <tr>
            <th scope="col">비교 항목</th>
            {phones.map((phone) => (
              <th key={phone.slug} scope="col">
                <span className="compare-product">
                  {phone.image_url && <Image src={phone.image_url} alt="" width={128} height={128} />}
                  <span>{phone.brand.name}</span>
                  <strong>{phone.name}</strong>
                </span>
              </th>
            ))}
          </tr>
        </thead>
        <tbody>
          {rows.map((row) => (
            <tr key={row.label}>
              <th scope="row">{row.label}</th>
              <td>{row.values[0]}</td>
              <td>{row.values[1]}</td>
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  );
}
