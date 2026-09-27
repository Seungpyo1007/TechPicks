import type { Metadata } from "next";
import Link from "next/link";
import { CONTACT_EMAIL, EFFECTIVE_EN, EFFECTIVE_KO, LegalPage } from "@/components/legal/legal-page";

export const metadata: Metadata = {
  title: "이용약관",
  description: "TechPicks 이용약관.",
};

/** 앱(로그인 화면·정보 화면)과 사이트가 함께 가리키는 이용약관. */
export default function TermsPage() {
  return (
    <LegalPage>
      <p className="note">
        <a href="#en">English</a>
      </p>
      <h1>이용약관</h1>
      <p className="note">시행일 {EFFECTIVE_KO}</p>

      <h2>1. 서비스</h2>
      <p>
        TechPicks(앱과 웹, 이하 &quot;서비스&quot;)는 기기 사양을 모아 보여 주고, 사용자가 정한 가중치로 점수를
        매기고, 비교와 AI 질문을 돕습니다. 로그인하지 않아도 쓸 수 있습니다.
      </p>

      <h2>2. 정보의 정확성</h2>
      <ul>
        <li>
          기기 사양은 <a href="https://github.com/GetTechAPI/TechAPI">TechAPI</a> 에서 가져오며 CC BY-SA 4.0 으로
          제공됩니다. 틀리거나 오래된 값이 있을 수 있습니다.
        </li>
        <li>가격과 환율은 참고용입니다. 실제 판매 가격과 다를 수 있습니다.</li>
        <li>점수와 AI 답변은 판단을 돕는 참고 자료입니다. 구매 결정은 사용자의 몫입니다.</li>
      </ul>

      <h2>3. 계정</h2>
      <ul>
        <li>계정은 본인만 써야 하고, 계정 정보는 직접 관리해야 합니다.</li>
        <li>언제든 앱의 내 정보 &gt; 계정, 또는 웹의 프로필에서 계정을 삭제할 수 있습니다.</li>
        <li>서비스를 방해하거나 법을 어기는 방식으로 쓰면 계정 이용을 막을 수 있습니다.</li>
      </ul>

      <h2>4. 개인정보</h2>
      <p>
        개인정보는 <Link href="/privacy">개인정보 처리방침</Link>대로 다룹니다.
      </p>

      <h2>5. 책임의 한계</h2>
      <p>
        서비스는 있는 그대로 제공됩니다. 법이 허용하는 범위에서, 서비스의 정보나 AI 답변을 믿고 한 결정으로 생긴
        손해에 책임지지 않습니다.
      </p>

      <h2>6. 바뀔 때</h2>
      <p>
        약관이 바뀌면 이 페이지에 시행일과 함께 알립니다. 바뀐 뒤에도 서비스를 쓰면 바뀐 약관에 동의한 것으로 봅니다.
      </p>

      <h2>7. 문의</h2>
      <p>
        <a href={`mailto:${CONTACT_EMAIL}`}>{CONTACT_EMAIL}</a>
      </p>

      <hr id="en" />
      <div lang="en">
        <h1>Terms of Use</h1>
        <p className="note">Effective {EFFECTIVE_EN}</p>

        <h2>1. The service</h2>
        <p>
          TechPicks (the app and the web, &quot;the service&quot;) collects device specifications, scores them with
          weights you choose, and helps you compare devices and ask AI questions. You can use it without signing in.
        </p>

        <h2>2. Accuracy</h2>
        <ul>
          <li>
            Device specifications come from <a href="https://github.com/GetTechAPI/TechAPI">TechAPI</a> under CC
            BY-SA 4.0 and may be wrong or out of date.
          </li>
          <li>Prices and exchange rates are for reference only and may differ from actual retail prices.</li>
          <li>Scores and AI answers are aids to your judgement. Purchase decisions are yours.</li>
        </ul>

        <h2>3. Accounts</h2>
        <ul>
          <li>Your account is for you alone, and you are responsible for keeping it secure.</li>
          <li>You can delete your account at any time in the app under You &gt; Account, or on the web under Profile.</li>
          <li>We may restrict accounts used to disrupt the service or break the law.</li>
        </ul>

        <h2>4. Privacy</h2>
        <p>
          Personal data is handled as described in the <Link href="/privacy#en">Privacy Policy</Link>.
        </p>

        <h2>5. Limitation of liability</h2>
        <p>
          The service is provided as is. To the extent permitted by law, we are not liable for losses from decisions
          made relying on its information or AI answers.
        </p>

        <h2>6. Changes</h2>
        <p>
          If these terms change, we will post them here with a new effective date. Continuing to use the service
          after a change means you accept the updated terms.
        </p>

        <h2>7. Contact</h2>
        <p>
          <a href={`mailto:${CONTACT_EMAIL}`}>{CONTACT_EMAIL}</a>
        </p>
      </div>
    </LegalPage>
  );
}
