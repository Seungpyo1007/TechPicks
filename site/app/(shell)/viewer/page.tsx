import type { Metadata } from "next";
import { getCatalogPhones, rankPhones } from "@/lib/catalog";
import { dimensionLabel } from "@/lib/phone-spec";

export const metadata: Metadata = {
  title: "3D 뷰어",
  description: "제품 외형을 회전하며 확인하는 화면입니다.",
  robots: { index: false, follow: true },
};

/** 정본 3D 뷰어. 정본에서도 `지원 예정` 자리표시용 와이어프레임이다. */
export default async function ViewerPage() {
  const phones = rankPhones(await getCatalogPhones());
  const phone = phones[0];

  return (
    <div className="tool-grid">
      <div className="panel panel-pad">
        <div className="viewer-stage">
          <div className="viewer-box">
            <i className="viewer-face-front" />
            <i className="viewer-face-back" />
            <i className="viewer-face-side" />
            <i className="viewer-face-top" />
          </div>
        </div>
      </div>

      <div className="panel panel-pad">
        <div className="section-head">
          <h2>3D 모델 뷰어</h2>
          <span className="tag tag-outline">지원 예정</span>
        </div>
        <p style={{ margin: 0, fontSize: 13, lineHeight: 1.6 }}>
          제품 외형을 회전·확대하며 확인하는 화면입니다. 지금은 자리표시용 와이어프레임이며, 실제 모델
          파일이 들어오면 같은 프레임 안에서 교체됩니다.
        </p>
        <dl className="laptop-rows">
          <div className="laptop-row">
            <dt>대상</dt>
            <dd>{phone?.name ?? "—"}</dd>
          </div>
          <div className="laptop-row">
            <dt>치수</dt>
            <dd>{phone ? dimensionLabel(phone) : "—"}</dd>
          </div>
          <div className="laptop-row">
            <dt>무게</dt>
            <dd>{phone?.weight_g ? `${phone.weight_g}g` : "—"}</dd>
          </div>
        </dl>
        <button className="btn btn-secondary" type="button" style={{ alignSelf: "start" }} disabled>
          모델 불러오기
        </button>
      </div>
    </div>
  );
}
