"use client";

import Link from "next/link";
import { initialsOf, useAuth } from "@/components/auth/auth-provider";
import { Icon } from "@/components/ui/icon";

/** 헤더 오른쪽 끝. 로그인했으면 이름 머리글자, 아니면 사람 모양. 둘 다 프로필로 간다. */
export function AccountAvatar() {
  const { user } = useAuth();
  return (
    <Link className="avatar" href="/profile" aria-label={user ? `프로필 · ${user.displayName ?? user.email ?? ""}` : "프로필 · 로그인 전"}>
      {user ? initialsOf(user) : <Icon name="user" size={18} />}
    </Link>
  );
}
