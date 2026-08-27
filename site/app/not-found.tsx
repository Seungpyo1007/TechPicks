import Link from "next/link";

export default function NotFound() {
  return (
    <div className="screen" style={{ display: "grid", placeContent: "center", minHeight: "100vh" }}>
      <div className="panel panel-pad" style={{ maxWidth: 520, padding: 32 }}>
        <span className="kicker">404 · NOT FOUND</span>
        <h1 style={{ margin: 0, fontSize: 32, lineHeight: 1.1 }}>이 제품은 카탈로그에 없습니다.</h1>
        <p style={{ margin: 0, fontSize: 13, lineHeight: 1.6 }}>
          주소가 정확한지 확인하거나 전체 랭킹에서 다시 찾아보세요.
        </p>
        <Link className="btn btn-primary" href="/phones" style={{ alignSelf: "start", height: 42 }}>
          스마트폰 랭킹으로
        </Link>
      </div>
    </div>
  );
}
