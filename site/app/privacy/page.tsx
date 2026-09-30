import type { Metadata } from "next";
import { CONTACT_EMAIL, EFFECTIVE_EN, EFFECTIVE_KO, LegalPage } from "@/components/legal/legal-page";

export const metadata: Metadata = {
  title: "개인정보 처리방침",
  description: "TechPicks 가 모으는 정보와 다루는 방법.",
};

/** 앱(로그인 화면·정보 화면)과 사이트가 함께 가리키는 개인정보 처리방침. */
export default function PrivacyPage() {
  return (
    <LegalPage>
      <p className="note">
        <a href="#en">English</a>
      </p>
      <h1>개인정보 처리방침</h1>
      <p className="note">시행일 {EFFECTIVE_KO}</p>
      <p>
        TechPicks(앱과 웹, 이하 &quot;서비스&quot;)가 어떤 정보를 왜 모으고 어떻게 다루는지 적습니다. 로그인하지
        않아도 모든 기능을 쓸 수 있고, 이때는 계정 정보를 모으지 않습니다.
      </p>

      <h2>1. 모으는 정보</h2>
      <ul>
        <li>
          <b>계정</b>: 로그인할 때 이메일, 이름, 프로필 사진, 로그인 방식(Apple·Google·이메일). Apple 로그인에서
          이메일 가리기를 고르면 Apple 이 준 중계 주소만 받습니다.
        </li>
        <li>
          <b>계정 데이터</b>: 앱에서 로그인한 경우 관심 목록, 가중치, 최근 검색. 다른 기기에서 이어 쓰기 위해
          저장합니다.
        </li>
        <li>
          <b>사용 기록</b>: 가중치 변경, 관심 목록 추가·삭제, 비교, 공유, 링크 열기 같은 앱 안 동작. 누가 했는지
          알 수 없는 형태로 모으며 화면 조회 수는 세지 않습니다.
        </li>
        <li>
          <b>오류 기록</b>: 앱이 멈추거나 오류가 났을 때 기기 종류, OS 버전, 오류 내용.
        </li>
        <li>
          <b>AI 질문</b>: 앱의 AI 엔진을 &quot;클라우드&quot;나 &quot;자동&quot;으로 두고 질문하면 질문 내용과 기기
          목록이 Google Gemini 로 전송됩니다. &quot;이 기기 안에서만&quot;을 고르면 질문이 기기 밖으로 나가지
          않습니다. 질문 원문은 사용 기록에 남기지 않습니다.
        </li>
        <li>
          <b>웹 설정</b>: 다크 모드 같은 웹 설정은 이 브라우저에만 저장됩니다.
        </li>
      </ul>

      <h2>2. 쓰는 곳</h2>
      <ul>
        <li>로그인과 계정 유지, 기기 간 동기화</li>
        <li>AI 질문에 대한 답변</li>
        <li>기능 개선과 오류 수정</li>
      </ul>
      <p>광고에 쓰지 않고, 파는 일도 없습니다.</p>

      <h2>3. 맡기는 곳</h2>
      <ul>
        <li>
          <b>Google Firebase</b>: 로그인, 계정 데이터·사진 저장, 사용·오류 기록, AI 답변(Gemini)
        </li>
        <li>
          <b>Apple</b>: Apple 로 로그인
        </li>
        <li>
          <b>Vercel</b>: 웹 사이트 호스팅
        </li>
        <li>
          <b>ExchangeRate-API</b>: 환율 조회. 개인정보는 보내지 않습니다.
        </li>
      </ul>

      <h2>4. 보관과 삭제</h2>
      <ul>
        <li>계정 정보와 계정 데이터는 계정을 삭제할 때까지 보관합니다.</li>
        <li>
          앱의 내 정보 &gt; 계정 &gt; 계정 삭제, 또는 웹의 프로필 &gt; 계정 삭제에서 바로 지울 수 있습니다. 로그인
          정보, 저장한 데이터, 프로필 사진이 함께 지워집니다.
        </li>
        <li>로그아웃하면 그 기기에 남은 계정 데이터를 지웁니다.</li>
      </ul>

      <h2>5. 문의</h2>
      <p>
        개인정보에 관한 문의는 <a href={`mailto:${CONTACT_EMAIL}`}>{CONTACT_EMAIL}</a> 로 보내 주세요.
      </p>

      <h2>6. 바뀔 때</h2>
      <p>이 방침이 바뀌면 이 페이지에 시행일과 함께 알립니다.</p>

      <hr id="en" />
      <div lang="en">
        <h1>Privacy Policy</h1>
        <p className="note">Effective {EFFECTIVE_EN}</p>
        <p>
          This explains what TechPicks (the app and the web, &quot;the service&quot;) collects, why, and how it is
          handled. Every feature works without signing in, and no account information is collected in that case.
        </p>

        <h2>1. What we collect</h2>
        <ul>
          <li>
            <b>Account</b>: when you sign in, your email, name, profile photo and sign-in method (Apple, Google or
            email). If you hide your email with Sign in with Apple, we only receive Apple&apos;s relay address.
          </li>
          <li>
            <b>Account data</b>: if signed in on the app, your shortlist, weights and recent searches, so you can
            continue on another device.
          </li>
          <li>
            <b>Usage events</b>: in-app actions such as changing weights, adding or removing from the shortlist,
            comparing, sharing and opening links. They are not tied to your identity, and screen views are not
            counted.
          </li>
          <li>
            <b>Crash reports</b>: device model, OS version and error details when the app crashes or errors.
          </li>
          <li>
            <b>AI questions</b>: with the app&apos;s AI engine set to &quot;Cloud&quot; or &quot;Auto&quot;, your
            question and the device list are sent to Google Gemini. With &quot;On this device only&quot;, questions
            never leave the device. Question text is never recorded in usage events.
          </li>
          <li>
            <b>Web settings</b>: settings such as dark mode are stored only in your browser.
          </li>
        </ul>

        <h2>2. How we use it</h2>
        <ul>
          <li>Signing in, keeping your account and syncing across devices</li>
          <li>Answering AI questions</li>
          <li>Improving features and fixing errors</li>
        </ul>
        <p>We do not use it for advertising and we do not sell it.</p>

        <h2>3. Service providers</h2>
        <ul>
          <li>
            <b>Google Firebase</b>: sign-in, account data and photo storage, usage and crash reports, AI answers
            (Gemini)
          </li>
          <li>
            <b>Apple</b>: Sign in with Apple
          </li>
          <li>
            <b>Vercel</b>: website hosting
          </li>
          <li>
            <b>ExchangeRate-API</b>: exchange rates. No personal data is sent.
          </li>
        </ul>

        <h2>4. Retention and deletion</h2>
        <ul>
          <li>Account information and data are kept until you delete your account.</li>
          <li>
            You can delete it any time in the app under You &gt; Account &gt; Delete account, or on the web under
            Profile &gt; Delete account. Your sign-in, saved data and profile photo are removed together.
          </li>
          <li>Signing out clears account data left on that device.</li>
        </ul>

        <h2>5. Contact</h2>
        <p>
          For privacy questions, email <a href={`mailto:${CONTACT_EMAIL}`}>{CONTACT_EMAIL}</a>.
        </p>

        <h2>6. Changes</h2>
        <p>If this policy changes, we will post it here with a new effective date.</p>
      </div>
    </LegalPage>
  );
}
