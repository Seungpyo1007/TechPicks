"use client";

import Link from "next/link";
import { useRouter } from "next/navigation";
import { useState } from "react";
import { initialsOf, useAuth } from "@/components/auth/auth-provider";
import { deleteAccount, methodOf, rename, resendVerification, sendReset, signOut, type Method } from "@/lib/auth";
import { authMessage } from "@/lib/auth-errors";

const METHOD_LABEL: Record<Method, string> = { apple: "Apple", google: "Google", email: "이메일" };

/** 프로필 위쪽 계정 카드. 로그인 전이면 로그인으로 가는 한 줄, 뒤면 앱의 계정 화면과 같은 일. */
export function AccountPanel() {
  const router = useRouter();
  const { user, ready, refresh } = useAuth();
  const [editing, setEditing] = useState(false);
  const [name, setName] = useState("");
  const [deleting, setDeleting] = useState(false);
  const [password, setPassword] = useState("");
  const [busy, setBusy] = useState(false);
  const [notice, setNotice] = useState<string | null>(null);
  const [error, setError] = useState<string | null>(null);

  if (!ready) return <section className="panel panel-pad" aria-busy="true" style={{ minHeight: 140 }} />;

  if (!user) {
    return (
      <section className="panel panel-pad">
        <div className="profile-id">
          <span className="profile-avatar" aria-hidden="true">
            ?
          </span>
          <div style={{ display: "flex", flexDirection: "column", gap: 3 }}>
            <span style={{ fontFamily: "var(--font-heading)", fontSize: 22, lineHeight: 1 }}>로그인 전</span>
            <span className="note">앱과 같은 계정으로 로그인할 수 있습니다.</span>
          </div>
        </div>
        <Link className="btn btn-primary" href="/login" style={{ height: 40, alignSelf: "flex-start" }}>
          로그인
        </Link>
      </section>
    );
  }

  const method = methodOf(user);
  const unverified = method === "email" && !user.emailVerified;

  async function act(action: () => Promise<void>, done?: string) {
    setBusy(true);
    setError(null);
    setNotice(null);
    try {
      await action();
      if (done) setNotice(done);
    } catch (caught) {
      setError(authMessage(caught) ?? null);
    } finally {
      setBusy(false);
    }
  }

  return (
    <section className="panel panel-pad">
      <div className="profile-id">
        <span className="profile-avatar">{initialsOf(user)}</span>
        <div style={{ display: "flex", flexDirection: "column", gap: 3, minWidth: 0 }}>
          <span style={{ fontFamily: "var(--font-heading)", fontSize: 22, lineHeight: 1 }}>
            {user.displayName || "이름 없음"}
          </span>
          <span className="note">
            {user.email}
            {method && ` · ${METHOD_LABEL[method]}`}
          </span>
        </div>
      </div>

      {unverified && (
        <div className="account-warn">
          <span>메일 주소를 확인해 주세요</span>
          <button
            type="button"
            className="link-button"
            disabled={busy}
            onClick={() => act(() => resendVerification(user), "확인 메일을 다시 보냈습니다.")}
          >
            다시 보내기
          </button>
        </div>
      )}

      {editing ? (
        <form
          className="account-inline"
          onSubmit={(event) => {
            event.preventDefault();
            if (!name.trim()) return;
            void act(async () => {
              await rename(user, name);
              setEditing(false);
              refresh();
            });
          }}
        >
          <input
            className="input"
            aria-label="이름"
            value={name}
            maxLength={40}
            autoFocus
            onChange={(event) => setName(event.target.value)}
          />
          <button className="btn btn-primary" type="submit" style={{ height: 38 }} disabled={busy || !name.trim()}>
            저장
          </button>
          <button className="btn btn-ghost" type="button" style={{ height: 38 }} onClick={() => setEditing(false)}>
            취소
          </button>
        </form>
      ) : (
        <div style={{ display: "flex", gap: 8, marginTop: 4, flexWrap: "wrap" }}>
          <button
            className="btn btn-secondary"
            type="button"
            style={{ height: 38 }}
            onClick={() => {
              setName(user.displayName ?? "");
              setEditing(true);
            }}
          >
            이름 바꾸기
          </button>
          {method === "email" && user.email && (
            <button
              className="btn btn-secondary"
              type="button"
              style={{ height: 38 }}
              disabled={busy}
              onClick={() =>
                act(() => sendReset(user.email!), `${user.email} 로 비밀번호 재설정 링크를 보냈습니다.`)
              }
            >
              비밀번호 변경
            </button>
          )}
          <button
            className="btn btn-secondary"
            type="button"
            style={{ height: 38 }}
            disabled={busy}
            onClick={() =>
              act(async () => {
                await signOut();
                router.push("/");
              })
            }
          >
            로그아웃
          </button>
        </div>
      )}

      {notice && (
        <p className="login-notice" role="status">
          {notice}
        </p>
      )}
      {error && (
        <p className="login-error" role="alert">
          {error}
        </p>
      )}

      <div className="account-danger">
        {deleting ? (
          <form
            className="account-inline"
            onSubmit={(event) => {
              event.preventDefault();
              void act(async () => {
                await deleteAccount(user, method === "email" ? password : undefined);
                router.push("/");
              });
            }}
          >
            <p className="note" style={{ margin: 0, flexBasis: "100%" }}>
              계정과 관심 목록·가중치·최근 검색을 모두 지웁니다. 되돌릴 수 없습니다.
              {method === "email" ? " 계속하려면 비밀번호를 입력하세요." : ` ${METHOD_LABEL[method ?? "email"]} 로 한 번 더 확인합니다.`}
            </p>
            {method === "email" && (
              <input
                className="input"
                type="password"
                aria-label="비밀번호"
                autoComplete="current-password"
                value={password}
                onChange={(event) => setPassword(event.target.value)}
              />
            )}
            <button className="btn btn-danger" type="submit" style={{ height: 38 }} disabled={busy}>
              삭제
            </button>
            <button className="btn btn-ghost" type="button" style={{ height: 38 }} onClick={() => setDeleting(false)}>
              취소
            </button>
          </form>
        ) : (
          <button type="button" className="link-button link-danger" onClick={() => setDeleting(true)}>
            계정 삭제
          </button>
        )}
      </div>
    </section>
  );
}
