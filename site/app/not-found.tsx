import Link from "next/link";

export default function NotFound() {
  return (
    <div className="shell not-found">
      <p className="eyebrow">404 · NOT FOUND</p>
      <h1>이 제품은 카탈로그에 없습니다.</h1>
      <p>주소가 정확한지 확인하거나 전체 스마트폰 목록에서 다시 찾아보세요.</p>
      <Link className="primary-button" href="/phones">스마트폰 랭킹으로</Link>
    </div>
  );
}
