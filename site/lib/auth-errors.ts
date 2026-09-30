/**
 * Firebase 오류 코드 → 화면 문구. 앱(`AuthFailure`·`authMessage`)과 같은 분류, 같은 말.
 *
 * `null` 은 사용자가 스스로 닫은 것이라 아무것도 안 띄운다.
 */
export type AuthFailure =
  | "canceled"
  | "badCredentials"
  | "emailInUse"
  | "weakPassword"
  | "invalidEmail"
  | "network"
  | "tooMany"
  | "otherProvider"
  | "requiresRecentLogin"
  | "disabled"
  | "notConfigured"
  | "popupBlocked"
  | "unknown";

export function failureOf(code: string | undefined): AuthFailure {
  switch ((code ?? "").replace(/^auth\//, "")) {
    case "popup-closed-by-user":
    case "cancelled-popup-request":
    case "user-cancelled":
      return "canceled";
    case "wrong-password":
    case "user-not-found":
    case "invalid-credential":
    case "invalid-login-credentials":
    case "INVALID_LOGIN_CREDENTIALS":
      return "badCredentials";
    case "email-already-in-use":
      return "emailInUse";
    case "weak-password":
      return "weakPassword";
    case "invalid-email":
      return "invalidEmail";
    case "network-request-failed":
      return "network";
    case "too-many-requests":
      return "tooMany";
    case "account-exists-with-different-credential":
    case "credential-already-in-use":
      return "otherProvider";
    case "requires-recent-login":
      return "requiresRecentLogin";
    case "user-disabled":
      return "disabled";
    case "operation-not-allowed":
    case "configuration-not-found":
    case "unauthorized-domain":
    case "invalid-oauth-client-id":
      return "notConfigured";
    case "popup-blocked":
      return "popupBlocked";
    default:
      return "unknown";
  }
}

const MESSAGES: Record<Exclude<AuthFailure, "canceled">, string> = {
  badCredentials: "메일 주소나 비밀번호가 맞지 않습니다.",
  emailInUse: "이미 가입된 메일입니다. 로그인해 주세요.",
  weakPassword: "더 긴 비밀번호를 써 주세요.",
  invalidEmail: "이메일 주소 형식이 아닙니다.",
  network: "인터넷에 연결되지 않았습니다. 확인하고 다시 해 주세요.",
  tooMany: "시도가 너무 많습니다. 잠시 뒤에 다시 해 주세요.",
  otherProvider: "이 메일은 Apple 이나 Google 로 가입돼 있습니다.",
  requiresRecentLogin: "계속하려면 다시 로그인해 주세요.",
  disabled: "사용이 중지된 계정입니다.",
  notConfigured: "이 로그인 방법은 아직 준비 중입니다.",
  popupBlocked: "브라우저가 로그인 창을 막았습니다. 팝업을 허용하고 다시 눌러 주세요.",
  unknown: "로그인하지 못했습니다. 잠시 뒤에 다시 해 주세요.",
};

export function authMessage(error: unknown): string | null {
  const code = typeof error === "object" && error && "code" in error ? String(error.code) : undefined;
  const failure = failureOf(code);
  return failure === "canceled" ? null : MESSAGES[failure];
}

/** 앱의 `LoginScreen.looksLikeEmail` 과 같은 규칙. */
export function looksLikeEmail(value: string): boolean {
  return /^[^\s@]+@[^\s@.]+(\.[^\s@.]+)+$/.test(value.trim());
}

export const PASSWORD_MIN = 6;
