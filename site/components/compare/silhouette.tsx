import type { Phone } from "@/lib/phone";

/**
 * 정본 비교 화면의 실루엣. 제품 사진 대신 TechAPI 치수에서 도형을 만든다.
 * 카메라 원의 개수·크기는 후면 렌즈 구성에서, 우하단 라벨은 두께에서 온다.
 */
const MAX_HEIGHT = 210;
const REFERENCE_HEIGHT_MM = 170;

const REAR_TYPES = ["main", "ultrawide", "telephoto", "periscope", "macro", "depth", "multispectral"];

export function Silhouette({ phone, delay }: { phone: Phone; delay: string }) {
  const height = phone.dimensions?.height_mm ?? null;
  const width = phone.dimensions?.width_mm ?? null;
  const depth = phone.dimensions?.depth_mm ?? null;

  // 치수가 없으면 도형을 그리지 않는다. 없는 값을 가정해 그리면 비교가 거짓말이 된다.
  if (!height || !width) {
    return (
      <p className="note" style={{ minHeight: MAX_HEIGHT, display: "grid", placeContent: "center" }}>
        치수 기록 없음
      </p>
    );
  }

  const scale = MAX_HEIGHT / REFERENCE_HEIGHT_MM;
  const boxHeight = Math.round(height * scale);
  const boxWidth = Math.round(width * scale);

  const lenses = (phone.cameras ?? [])
    .filter((camera) => REAR_TYPES.includes(camera.type))
    .slice(0, 4)
    .map((camera) => Math.max(9, Math.min(18, Math.round(((camera.mp ?? 12) / 200) * 18 + 9))));

  return (
    <div
      className="silhouette"
      style={{ width: boxWidth, height: boxHeight, animationDelay: delay }}
      aria-hidden="true"
    >
      {lenses.length > 0 && (
        <span className="silhouette-cams">
          {lenses.map((diameter, index) => (
            <i key={`${diameter}-${index}`} style={{ width: diameter, height: diameter }} />
          ))}
        </span>
      )}
      {depth && <span className="silhouette-depth">{depth}mm</span>}
    </div>
  );
}
