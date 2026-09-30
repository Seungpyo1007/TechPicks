"use client";

import { onIdTokenChanged, type User } from "firebase/auth";
import { createContext, useContext, useEffect, useState } from "react";
import { firebaseAuth } from "@/lib/firebase";

type AuthState = {
  user: User | null;
  /** 첫 확인이 끝났는가. 그 전에는 로그인 전으로 그리지 않는다(깜빡임). */
  ready: boolean;
  /** 이름 바꾸기·메일 확인처럼 같은 사용자 안에서 바뀐 것을 다시 그린다. */
  refresh: () => void;
};

const AuthContext = createContext<AuthState>({ user: null, ready: false, refresh: () => {} });

export function AuthProvider({ children }: { children: React.ReactNode }) {
  const [user, setUser] = useState<User | null>(null);
  const [ready, setReady] = useState(false);
  const [, setVersion] = useState(0);

  useEffect(
    () =>
      // 토큰이 바뀔 때마다(로그인·로그아웃·메일 확인 후 새로고침) 온다.
      onIdTokenChanged(firebaseAuth(), (next) => {
        setUser(next);
        setReady(true);
        setVersion((value) => value + 1);
      }),
    [],
  );

  return (
    <AuthContext.Provider value={{ user, ready, refresh: () => setVersion((value) => value + 1) }}>
      {children}
    </AuthContext.Provider>
  );
}

export const useAuth = () => useContext(AuthContext);

/** 아바타 글자. 이름 앞 두 글자, 없으면 메일 앞 두 글자. */
export function initialsOf(user: Pick<User, "displayName" | "email">): string {
  const source = user.displayName?.trim() || user.email?.split("@")[0] || "";
  return source.slice(0, 2).toUpperCase();
}
