/**
 * 실행 중인 사이트를 돌며 글자 대비가 WCAG AA(본문 4.5:1, 큰 글자 3:1) 미만인 곳을 찾는다.
 *
 * CSS 만 읽어서는 알 수 없다 — 정본 팔레트가 `color-mix` 와 테마별 토큰 뒤집기를 쓰기 때문에
 * 실제로 합성된 색을 브라우저에서 재야 한다. 그래서 브라우저 콘솔에 붙여 넣어 쓰는 스크립트다.
 *
 *   1. pnpm build && pnpm start
 *   2. 검사할 화면을 열고 개발자도구 콘솔에 이 파일의 AUDIT 함수를 붙여 넣는다
 *   3. 라이트·다크를 모두 확인한다 (프로필 화면의 다크 모드 토글 또는 OS 설정)
 *
 * 통과 기준은 빈 배열이다.
 */
export const AUDIT = `(() => {
  const parse = (value) => {
    const parts = value.match(/[\\d.]+/g).map(Number);
    const scale = value.startsWith('color(') ? 255 : 1;
    return { r: parts[0] * scale, g: parts[1] * scale, b: parts[2] * scale, a: parts[3] ?? 1 };
  };
  const luminance = ({ r, g, b }) => {
    const f = (v) => { v /= 255; return v <= 0.03928 ? v / 12.92 : Math.pow((v + 0.055) / 1.055, 2.4); };
    return 0.2126 * f(r) + 0.7152 * f(g) + 0.0722 * f(b);
  };
  const over = (fg, bg) => ({
    r: fg.r * fg.a + bg.r * (1 - fg.a),
    g: fg.g * fg.a + bg.g * (1 - fg.a),
    b: fg.b * fg.a + bg.b * (1 - fg.a),
    a: 1,
  });
  const backdrop = (el) => {
    let node = el, stack = null;
    while (node && node !== document.documentElement) {
      const color = parse(getComputedStyle(node).backgroundColor);
      if (color.a > 0) { stack = stack ? over(stack, color) : color; if (color.a > 0.999) return stack; }
      node = node.parentElement;
    }
    const root = parse(getComputedStyle(document.body).backgroundColor);
    return stack ? over(stack, root) : root;
  };

  const failures = [];
  document.querySelectorAll('body *').forEach((el) => {
    const hasOwnText = [...el.childNodes].some((n) => n.nodeType === 3 && n.textContent.trim().length > 1);
    if (!hasOwnText) return;
    const style = getComputedStyle(el);
    if (style.visibility === 'hidden' || style.display === 'none' || Number(style.opacity) === 0) return;

    const bg = backdrop(el);
    const fg = over(parse(style.color), bg);
    const a = luminance(fg), b = luminance(bg);
    const ratio = (Math.max(a, b) + 0.05) / (Math.min(a, b) + 0.05);

    const size = parseFloat(style.fontSize);
    const weight = parseInt(style.fontWeight) || 400;
    const isLarge = size >= 24 || (size >= 18.66 && weight >= 700);
    const required = isLarge ? 3 : 4.5;

    if (ratio < required) {
      failures.push({
        selector: typeof el.className === 'string' && el.className ? el.className : el.tagName,
        fontSize: style.fontSize,
        ratio: Math.round(ratio * 100) / 100,
        required,
        sample: el.textContent.trim().slice(0, 24),
      });
    }
  });

  const seen = new Set();
  return failures
    .filter((f) => { const key = f.selector + '|' + f.fontSize; if (seen.has(key)) return false; seen.add(key); return true; })
    .sort((x, y) => x.ratio - y.ratio);
})()`;

console.log(AUDIT);
