"use client";

import { useState } from "react";
import { useRouter } from "next/navigation";
import { compareHref } from "@/lib/compare-query";
import type { PhoneOption } from "@/lib/phone";

export function ComparePicker({
  phones,
  initial = [],
  message,
}: {
  phones: PhoneOption[];
  initial?: string[];
  message?: string;
}) {
  const router = useRouter();
  const [first, setFirst] = useState(initial[0] ?? "");
  const [second, setSecond] = useState(initial[1] ?? "");
  const duplicate = Boolean(first && second && first === second);

  function submit(event: React.FormEvent<HTMLFormElement>) {
    event.preventDefault();
    if (!first || !second || duplicate) return;
    router.push(compareHref(first, second));
  }

  return (
    <form className="compare-picker" onSubmit={submit}>
      <div className="compare-fields">
        <label>
          <span>첫 번째 스마트폰</span>
          <select value={first} onChange={(event) => setFirst(event.target.value)}>
            <option value="">제품 선택</option>
            {phones.map((phone) => (
              <option key={phone.slug} value={phone.slug} disabled={phone.slug === second}>
                {phone.name}
              </option>
            ))}
          </select>
        </label>
        <div className="versus" aria-hidden="true">VS</div>
        <label>
          <span>두 번째 스마트폰</span>
          <select value={second} onChange={(event) => setSecond(event.target.value)}>
            <option value="">제품 선택</option>
            {phones.map((phone) => (
              <option key={phone.slug} value={phone.slug} disabled={phone.slug === first}>
                {phone.name}
              </option>
            ))}
          </select>
        </label>
      </div>
      {(message || duplicate) && (
        <p className="form-message" role="status">
          {duplicate ? "서로 다른 스마트폰을 골라주세요." : message}
        </p>
      )}
      <button className="primary-button" type="submit" disabled={!first || !second || duplicate}>
        비교 결과 보기
      </button>
    </form>
  );
}
