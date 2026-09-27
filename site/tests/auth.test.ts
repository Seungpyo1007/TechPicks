import { describe, expect, it } from "vitest";
import { initialsOf } from "@/components/auth/auth-provider";
import { authMessage, failureOf, looksLikeEmail } from "@/lib/auth-errors";

describe("auth errors", () => {
  it("treats closing the popup as a cancel, not an error", () => {
    expect(failureOf("auth/popup-closed-by-user")).toBe("canceled");
    expect(authMessage({ code: "auth/cancelled-popup-request" })).toBeNull();
  });

  it("uses the app's wording for common failures", () => {
    expect(authMessage({ code: "auth/invalid-credential" })).toBe("메일 주소나 비밀번호가 맞지 않습니다.");
    expect(authMessage({ code: "auth/email-already-in-use" })).toBe("이미 가입된 메일입니다. 로그인해 주세요.");
    expect(failureOf("auth/unauthorized-domain")).toBe("notConfigured");
    expect(failureOf("auth/popup-blocked")).toBe("popupBlocked");
  });

  it("falls back to a generic line for anything else", () => {
    expect(failureOf("auth/something-new")).toBe("unknown");
    expect(authMessage(new Error("boom"))).toBe("로그인하지 못했습니다. 잠시 뒤에 다시 해 주세요.");
  });
});

describe("email shape", () => {
  it("matches the app's rule", () => {
    expect(looksLikeEmail("a@b.com")).toBe(true);
    expect(looksLikeEmail("  a@b.co.kr ")).toBe(true);
    for (const bad of ["a@b", "@b.com", "a@", "a b@c.com", "a@.com", ""]) {
      expect(looksLikeEmail(bad), bad).toBe(false);
    }
  });
});

describe("avatar initials", () => {
  it("prefers the name, then the mailbox", () => {
    expect(initialsOf({ displayName: "seungpyo", email: null })).toBe("SE");
    expect(initialsOf({ displayName: null, email: "kim@example.com" })).toBe("KI");
    expect(initialsOf({ displayName: "  ", email: null })).toBe("");
  });
});
