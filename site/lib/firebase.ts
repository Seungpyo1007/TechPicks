import { getApps, initializeApp, type FirebaseApp } from "firebase/app";
import { getAuth, type Auth } from "firebase/auth";
import { getFirestore, type Firestore } from "firebase/firestore";
import { getStorage, type FirebaseStorage } from "firebase/storage";

/**
 * 앱과 같은 Firebase 프로젝트(techpicks-project)의 웹 앱.
 *
 * 웹 설정은 브라우저에 그대로 내려가는 공개 값이다. 막는 것은 보안 규칙과
 * 승인된 도메인이다(`firestore.rules`, `storage.rules`).
 */
const config = {
  apiKey: "AIzaSyBuK9JbWSSj_f1F02BpkkX4GyZBEUPQnFY",
  authDomain: "techpicks-project.firebaseapp.com",
  projectId: "techpicks-project",
  storageBucket: "techpicks-project.appspot.com",
  messagingSenderId: "746932050988",
  appId: "1:746932050988:web:4203e249d3fd40b88e8589",
};

/** 브라우저에서만 부른다. 서버 렌더링 중에는 만들지 않는다. */
export function firebaseApp(): FirebaseApp {
  return getApps()[0] ?? initializeApp(config);
}

export const firebaseAuth = (): Auth => getAuth(firebaseApp());
export const firestore = (): Firestore => getFirestore(firebaseApp());
export const storage = (): FirebaseStorage => getStorage(firebaseApp());
