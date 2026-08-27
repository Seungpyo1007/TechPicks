import { describe, expect, it } from "vitest";
import { axisValues, AXES, percent, radarPoints, radarRings } from "@/lib/score";
import { parsePhone } from "@/lib/phone";
import validPhone from "../../shared/contracts/fixtures/valid-phone.json";

const phone = parsePhone(validPhone);

describe("score axes", () => {
  it("keeps the five axes the original design draws", () => {
    expect(AXES.map((axis) => axis.label)).toEqual(["성능", "카메라", "화면", "배터리", "가치"]);
  });

  it("rounds catalog scores into the axis values", () => {
    const axes = axisValues(phone);
    expect(axes).toHaveLength(5);
    expect(axes.every((axis) => Number.isInteger(axis.value))).toBe(true);
  });
});

describe("radar geometry", () => {
  it("puts a full score on the top vertex, matching the original coordinates", () => {
    const points = radarPoints(AXES.map((axis) => ({ ...axis, value: 100 })));
    expect(points.split(" ")[0]).toBe("160.0,40.0");
    expect(points.split(" ")).toHaveLength(5);
  });

  it("clamps a zero axis to the floor so the shape stays visible", () => {
    const points = radarPoints([
      { key: "performance", label: "성능", value: 0 },
      { key: "camera", label: "카메라", value: 0 },
      { key: "display", label: "화면", value: 0 },
      { key: "battery", label: "배터리", value: 0 },
      { key: "value", label: "가치", value: 0 },
    ]);
    // 하한 20% → 반지름 22px. 중심(160,150)에서 22 만큼 위.
    expect(points.split(" ")[0]).toBe("160.0,128.0");
  });

  it("draws five background rings", () => {
    expect(radarRings()).toHaveLength(5);
  });
});

describe("percent", () => {
  it("normalises against a max and clamps to the bar", () => {
    expect(percent(50)).toBe("50%");
    expect(percent(120)).toBe("100%");
    expect(percent(null)).toBe("0%");
    expect(percent(5, 10)).toBe("50%");
  });
});
