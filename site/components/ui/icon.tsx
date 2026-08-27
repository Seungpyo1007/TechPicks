/** 정본 `TechPicks Web M3.dc.html` 의 ICONS 맵. path 데이터는 그대로다. */
export const ICON_PATHS = {
  home: ["M3 10.5 12 3l9 7.5", "M5.5 9.5V21h13V9.5"],
  phone: [
    "M7 2.5h10a1.5 1.5 0 0 1 1.5 1.5v16a1.5 1.5 0 0 1-1.5 1.5H7A1.5 1.5 0 0 1 5.5 20V4A1.5 1.5 0 0 1 7 2.5Z",
    "M10.5 18.5h3",
  ],
  cpu: [
    "M7 7h10v10H7z",
    "M4.5 4.5h15v15h-15z",
    "M9 2v2.5M15 2v2.5M9 19.5V22M15 19.5V22M2 9h2.5M2 15h2.5M19.5 9H22M19.5 15H22",
  ],
  laptop: ["M4.5 5.5h15v10h-15z", "M2 18.5h20"],
  compare: ["M7 4v16", "M17 4v16", "M3.5 8.5 7 4l3.5 4.5", "M13.5 15.5 17 20l3.5-4.5"],
  scan: [
    "M3.5 8V5.5A2 2 0 0 1 5.5 3.5H8",
    "M16 3.5h2.5a2 2 0 0 1 2 2V8",
    "M20.5 16v2.5a2 2 0 0 1-2 2H16",
    "M8 20.5H5.5a2 2 0 0 1-2-2V16",
    "M3.5 12h17",
  ],
  box: ["M12 2.8 20.5 7v10L12 21.2 3.5 17V7Z", "M3.5 7 12 11.4 20.5 7", "M12 11.4V21.2"],
  user: ["M12 12a4 4 0 1 0 0-8 4 4 0 0 0 0 8Z", "M4.5 20.5c1.6-3.4 4.3-5 7.5-5s5.9 1.6 7.5 5"],
  build: [
    "M5.5 3.5h9a1.5 1.5 0 0 1 1.5 1.5v14a1.5 1.5 0 0 1-1.5 1.5h-9A1.5 1.5 0 0 1 4 19V5a1.5 1.5 0 0 1 1.5-1.5Z",
    "M7 7h6M7 10.5h6",
    "M10 14.5a1.75 1.75 0 1 0 0 3.5 1.75 1.75 0 0 0 0-3.5Z",
    "M19 8v8",
  ],
  search: ["M11 4a7 7 0 1 0 0 14 7 7 0 0 0 0-14Z", "M20 20l-3.5-3.5"],
  sync: ["M20 11a8 8 0 1 0-.6 4", "M20 5v6h-6"],
  check: ["M4.5 12.5 9.5 17.5 19.5 7"],
} as const;

export type IconName = keyof typeof ICON_PATHS;

export function Icon({ name, size = 18 }: { name: IconName; size?: number }) {
  return (
    <svg
      viewBox="0 0 24 24"
      fill="none"
      stroke="currentColor"
      strokeWidth={1.5}
      strokeLinecap="round"
      strokeLinejoin="round"
      style={{ width: size, height: size, flex: "none" }}
      aria-hidden="true"
    >
      {ICON_PATHS[name].map((d) => (
        <path key={d} d={d} />
      ))}
    </svg>
  );
}
