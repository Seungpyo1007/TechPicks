"use client";

import { useCallback, useSyncExternalStore } from "react";

/**
 * 정본 프로필 화면의 다크 모드 토글과 알림 스위치.
 *
 * 값이 없으면 시스템 설정을 따른다(토큰이 `prefers-color-scheme` 에도 정의되어 있다).
 * 한 번 고르면 `data-theme` 로 고정되고 localStorage 에 남는다.
 *
 * 저장소는 React 바깥의 상태이므로 `useSyncExternalStore` 로 읽는다. 효과 안에서
 * setState 를 부르면 하이드레이션 직후 한 번 더 렌더가 돈다.
 */
export const THEME_STORAGE_KEY = "techpicks-theme";
export const NOTIFICATION_STORAGE_KEY = "techpicks-notifications";

export type Theme = "light" | "dark";

/** 첫 페인트 전에 실행되어 테마 깜빡임을 막는 스크립트. */
export const THEME_BOOTSTRAP_SCRIPT = `try{var t=localStorage.getItem(${JSON.stringify(
  THEME_STORAGE_KEY,
)});if(t==="light"||t==="dark"){document.documentElement.setAttribute("data-theme",t)}}catch(e){}`;

/** 같은 탭 안에서 스위치를 눌렀을 때 구독자에게 알리는 이벤트. */
const CHANGE_EVENT = "techpicks:settings";

function readStorage(key: string): string | null {
  try {
    return localStorage.getItem(key);
  } catch {
    return null;
  }
}

function writeStorage(key: string, value: string) {
  try {
    localStorage.setItem(key, value);
  } catch {
    // 사생활 보호 모드 등에서 저장이 막혀도 화면 전환 자체는 동작해야 한다.
  }
  window.dispatchEvent(new Event(CHANGE_EVENT));
}

function subscribe(onChange: () => void): () => void {
  window.addEventListener(CHANGE_EVENT, onChange);
  window.addEventListener("storage", onChange);
  const media = window.matchMedia("(prefers-color-scheme: dark)");
  media.addEventListener("change", onChange);
  return () => {
    window.removeEventListener(CHANGE_EVENT, onChange);
    window.removeEventListener("storage", onChange);
    media.removeEventListener("change", onChange);
  };
}

function readTheme(): Theme {
  const stored = readStorage(THEME_STORAGE_KEY);
  if (stored === "dark" || stored === "light") return stored;
  return window.matchMedia("(prefers-color-scheme: dark)").matches ? "dark" : "light";
}

export function useTheme(): [Theme, (next: Theme) => void] {
  const theme = useSyncExternalStore<Theme>(subscribe, readTheme, () => "light");

  const setTheme = useCallback((next: Theme) => {
    document.documentElement.setAttribute("data-theme", next);
    writeStorage(THEME_STORAGE_KEY, next);
  }, []);

  return [theme, setTheme];
}

export function useNotifications(): [boolean, (next: boolean) => void] {
  const enabled = useSyncExternalStore(
    subscribe,
    () => readStorage(NOTIFICATION_STORAGE_KEY) !== "off",
    () => true,
  );

  const setEnabled = useCallback((next: boolean) => {
    writeStorage(NOTIFICATION_STORAGE_KEY, next ? "on" : "off");
  }, []);

  return [enabled, setEnabled];
}

/** 정본의 52×32 알약 스위치. */
export function Switch({
  checked,
  onChange,
  label,
}: {
  checked: boolean;
  onChange: (next: boolean) => void;
  label: string;
}) {
  return (
    <button
      type="button"
      role="switch"
      className="switch"
      aria-checked={checked}
      aria-label={label}
      onClick={() => onChange(!checked)}
    >
      <span />
    </button>
  );
}
