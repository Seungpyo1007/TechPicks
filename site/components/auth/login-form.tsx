"use client";

import Link from "next/link";
import { useRouter } from "next/navigation";
import { useEffect, useState } from "react";
import { useAuth } from "@/components/auth/auth-provider";
import { appleEnabled, sendReset, signInWith, signInWithEmail, signUpWithEmail } from "@/lib/auth";
import { PASSWORD_MIN, authMessage, looksLikeEmail } from "@/lib/auth-errors";

type Mode = "signIn" | "signUp" | "reset";
type Busy = "email" | "google" | "apple" | null;

/** 로그인 화면 오른쪽. 앱과 같은 세 방법 — Apple · Google · 이메일(로그인·가입·재설정). */
export function LoginForm() {
  const router = useRouter();
  const { user, ready } = useAuth();
  const [mode, setMode] = useState<Mode>("signIn");
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [busy, setBusy] = useState<Busy>(null);
  const [error, setError] = useState<string | null>(null);
  const [notice, setNotice] = useState<string | null>(null);

  // 이미 들어와 있으면 여기 머물 이유가 없다.
  useEffect(() => {
    if (ready && user) router.replace("/profile");
  }, [ready, user, router]);

  function switchTo(next: Mode) {
    setMode(next);
    setError(null);
    setNotice(null);
  }

  async function run(kind: Exclude<Busy, null>, action: () => Promise<unknown>) {
    setBusy(kind);
    setError(null);
    try {
      await action();
    } catch (caught) {
      setError(authMessage(caught));
    } finally {
      setBusy(null);
    }
  }

  function submit(event: React.FormEvent) {
    event.preventDefault();
    if (!looksLikeEmail(email)) return setError("이메일 주소 형식이 아닙니다.");
    if (mode === "reset") {
      return run("email", async () => {
        await sendReset(email);
        setNotice("메일을 보냈습니다. 받은편지함을 확인해 주세요.");
      });
    }
    if (password.length < PASSWORD_MIN) return setError("비밀번호는 6자 이상입니다.");
    return run("email", () => (mode === "signUp" ? signUpWithEmail : signInWithEmail)(email, password));
  }

  const title = mode === "signUp" ? "계정 만들기" : mode === "reset" ? "비밀번호 재설정" : "계정으로 계속하기";
  const primary = mode === "signUp" ? "가입하기" : mode === "reset" ? "재설정 메일 보내기" : "로그인";

  return (
    <form className="login-form-fields" onSubmit={submit} noValidate>
      <h2>{title}</h2>
      {mode === "reset" && <p className="note login-lead">새 비밀번호를 정할 링크를 메일로 보내 드립니다.</p>}

      <div className="login-field">
        <label htmlFor="tp-email">이메일</label>
        <input
          id="tp-email"
          className="input"
          type="email"
          autoComplete="email"
          placeholder="name@example.com"
          value={email}
          onChange={(event) => setEmail(event.target.value)}
          style={{ minHeight: 50 }}
        />
      </div>
      {mode !== "reset" && (
        <div className="login-field">
          <label htmlFor="tp-pw">비밀번호</label>
          <input
            id="tp-pw"
            className="input"
            type="password"
            autoComplete={mode === "signUp" ? "new-password" : "current-password"}
            placeholder={mode === "signUp" ? "6자 이상" : "••••••••"}
            value={password}
            onChange={(event) => setPassword(event.target.value)}
            style={{ minHeight: 50 }}
          />
        </div>
      )}

      {error && (
        <p className="login-error" role="alert">
          {error}
        </p>
      )}
      {notice && (
        <p className="login-notice" role="status">
          {notice}
        </p>
      )}

      <div className="login-actions">
        <button className="btn btn-primary" type="submit" style={{ height: 46 }} disabled={busy !== null}>
          {busy === "email" ? "잠시만요…" : primary}
        </button>

        {mode === "signIn" && (
          <div className="login-links">
            <button type="button" className="link-button" onClick={() => switchTo("signUp")}>
              계정 만들기
            </button>
            <button type="button" className="link-button" onClick={() => switchTo("reset")}>
              비밀번호를 잊으셨나요?
            </button>
          </div>
        )}
        {mode !== "signIn" && (
          <div className="login-links">
            <button type="button" className="link-button" onClick={() => switchTo("signIn")}>
              로그인으로 돌아가기
            </button>
          </div>
        )}

        {mode !== "reset" && (
          <>
            <div className="login-or" aria-hidden="true">
              또는
            </div>
            <div className="login-social" data-count={appleEnabled ? 2 : 1}>
              <button
                className="btn btn-secondary"
                type="button"
                style={{ height: 44 }}
                disabled={busy !== null}
                onClick={() => run("google", () => signInWith("google"))}
              >
                {busy === "google" ? "잠시만요…" : "Google로 계속"}
              </button>
              {appleEnabled && (
                <button
                  className="btn btn-secondary"
                  type="button"
                  style={{ height: 44 }}
                  disabled={busy !== null}
                  onClick={() => run("apple", () => signInWith("apple"))}
                >
                  {busy === "apple" ? "잠시만요…" : "Apple로 계속"}
                </button>
              )}
            </div>
          </>
        )}

        <Link className="btn btn-ghost" href="/">
          로그인 없이 둘러보기
        </Link>
      </div>

      <p className="note login-legal">
        계속하면 <Link href="/terms">이용약관</Link>과 <Link href="/privacy">개인정보 처리방침</Link>에
        동의합니다.
      </p>
    </form>
  );
}
