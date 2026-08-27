"use client";

import { useEffect, useRef, useState } from "react";
import { Icon } from "@/components/ui/icon";

/**
 * 정본 헤더의 싱크 버튼. Seungpyo1007/flutter_cloudflare_dns 의 모션 언어를 그대로 쓴다.
 * 880ms 회전 → 180ms 체크 교체.
 */
const SPIN_MS = 880;
const SWAP_MS = 1400;

type State = "idle" | "syncing" | "done";

export function SyncButton() {
  const [state, setState] = useState<State>("idle");
  const timers = useRef<ReturnType<typeof setTimeout>[]>([]);

  useEffect(() => {
    const pending = timers.current;
    return () => pending.forEach(clearTimeout);
  }, []);

  function run() {
    if (state === "syncing") return;
    setState("syncing");
    timers.current.push(setTimeout(() => setState("done"), SPIN_MS));
    timers.current.push(setTimeout(() => setState("idle"), SPIN_MS + SWAP_MS));
  }

  const title =
    state === "syncing" ? "TechAPI 최신 데이터 확인 중" : state === "done" ? "최신 상태" : "데이터 동기화";

  return (
    <button className="sync-button" type="button" onClick={run} title={title} aria-label={title}>
      <span className={state === "syncing" ? "sync-spin" : state === "done" ? "sync-done" : undefined}>
        <Icon name={state === "done" ? "check" : "sync"} size={18} />
      </span>
    </button>
  );
}
