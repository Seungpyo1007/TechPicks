import {
  AuthErrorCodes,
  EmailAuthProvider,
  GoogleAuthProvider,
  OAuthProvider,
  createUserWithEmailAndPassword,
  deleteUser,
  reauthenticateWithCredential,
  reauthenticateWithPopup,
  sendEmailVerification,
  sendPasswordResetEmail,
  signInWithEmailAndPassword,
  signInWithPopup,
  signOut as firebaseSignOut,
  updateProfile,
  type AuthProvider,
  type User,
} from "firebase/auth";
import { deleteObject, ref } from "firebase/storage";
import { doc, writeBatch } from "firebase/firestore";
import { firebaseAuth, firestore, storage } from "@/lib/firebase";

/**
 * 브라우저에서 쓰는 로그인 동작. 앱(`FirebaseAuthService`)과 같은 흐름을 Firebase 팝업으로 한다.
 */
export type Method = "email" | "google" | "apple";

/**
 * 웹의 Apple 로그인은 Apple Services ID 와 키를 Firebase 에 넣어야 돈다.
 * 넣은 뒤 `NEXT_PUBLIC_APPLE_SIGN_IN=true` 로 버튼을 켠다.
 */
export const appleEnabled = process.env.NEXT_PUBLIC_APPLE_SIGN_IN === "true";

function provider(method: Exclude<Method, "email">): AuthProvider {
  if (method === "google") {
    const google = new GoogleAuthProvider();
    // 안 붙이면 방금 쓴 계정으로 고르지도 않고 들어간다.
    google.setCustomParameters({ prompt: "select_account" });
    return google;
  }
  const apple = new OAuthProvider("apple.com");
  apple.addScope("email");
  apple.addScope("name");
  return apple;
}

export async function signInWith(method: Exclude<Method, "email">): Promise<User> {
  return (await signInWithPopup(firebaseAuth(), provider(method))).user;
}

export async function signInWithEmail(email: string, password: string): Promise<User> {
  return (await signInWithEmailAndPassword(firebaseAuth(), email.trim(), password)).user;
}

/** 가입하고 확인 메일을 보낸다. 메일이 안 나가도 가입은 된 것이다. */
export async function signUpWithEmail(email: string, password: string): Promise<User> {
  const { user } = await createUserWithEmailAndPassword(firebaseAuth(), email.trim(), password);
  await sendEmailVerification(user).catch(() => undefined);
  return user;
}

/**
 * 재설정 메일. 없는 계정이라고 알려 주면 가입한 메일을 캐는 데 쓰이니, 그 경우도 보낸 것처럼 둔다.
 */
export async function sendReset(email: string): Promise<void> {
  try {
    await sendPasswordResetEmail(firebaseAuth(), email.trim());
  } catch (error) {
    const code = (error as { code?: string }).code;
    if (code === AuthErrorCodes.USER_DELETED || code === AuthErrorCodes.INVALID_LOGIN_CREDENTIALS) return;
    throw error;
  }
}

export async function resendVerification(user: User): Promise<void> {
  await sendEmailVerification(user);
}

export async function rename(user: User, name: string): Promise<void> {
  await updateProfile(user, { displayName: name.trim() });
  await user.reload();
}

export function methodOf(user: User): Method | null {
  for (const info of user.providerData) {
    if (info.providerId === "apple.com") return "apple";
    if (info.providerId === "google.com") return "google";
    if (info.providerId === "password") return "email";
  }
  return null;
}

export async function signOut(): Promise<void> {
  await firebaseSignOut(firebaseAuth());
}

/**
 * 계정 삭제. 민감한 일이라 먼저 같은 방법으로 다시 확인하고, 앱과 같은 곳을 지운다:
 * `users/{uid}`, `users/{uid}/state/{shortlist,weights,recents}`, `profile_images/{uid}`.
 */
export async function deleteAccount(user: User, password?: string): Promise<void> {
  const method = methodOf(user);
  if (method === "email") {
    if (!password) throw Object.assign(new Error("password"), { code: "auth/invalid-credential" });
    await reauthenticateWithCredential(user, EmailAuthProvider.credential(user.email ?? "", password));
  } else if (method) {
    await reauthenticateWithPopup(user, provider(method));
  }

  const db = firestore();
  const batch = writeBatch(db);
  for (const name of ["shortlist", "weights", "recents"]) {
    batch.delete(doc(db, "users", user.uid, "state", name));
  }
  batch.delete(doc(db, "users", user.uid));
  await batch.commit();

  try {
    await deleteObject(ref(storage(), `profile_images/${user.uid}`));
  } catch (error) {
    // 사진을 올린 적이 없으면 없는 게 맞다.
    if ((error as { code?: string }).code !== "storage/object-not-found") throw error;
  }

  await deleteUser(user);
}
