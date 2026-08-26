# TechPicks

기기를 고를 때 숫자 하나로 답을 주는 앱. 성능·카메라·화면·배터리·가성비에
매긴 점수를 **사용자가 정한 비중**으로 합쳐 TP Index 를 낸다. 같은 기기라도
카메라를 중요하게 보는 사람과 배터리를 중요하게 보는 사람의 점수가 다르다.

Flutter 로 만들고 iOS·Android 를 함께 지원한다.

## 화면

| 화면 | 하는 일 |
|---|---|
| 홈 | 관심 목록에서 지금의 결론 하나, 그 근거, 이번 주 순위 변동 |
| 랭킹 | 폰·프로세서를 지수·배터리·카메라·가성비·가격 축으로 세운다 |
| 비교 | 두 기기를 한 표에 놓고 줄마다 이긴 쪽을 표시한다 |
| 상세 | 스펙 표와 다섯 축 점수, 관심 목록 담기, 3D 보기 |
| 상담 | 예산과 중요한 조건을 말하면 기기 하나와 4줄 표로 답한다 |
| 내 정보 | 가중치 슬라이더. 움직이면 앱 전체 지수가 다시 계산된다 |
| 스캔 | 뒷면 모델명을 읽어 카탈로그와 맞춘다 |

## 데이터

기기 정보는 [TechAPI](https://github.com/GetTechAPI/TechAPI) 를 쓴다 (CC-BY-SA 4.0).

목록 인덱스에는 점수가 없고 전체 목록은 19MB 라 앱에서 그대로 못 쓴다. 그래서
빌드 시점에 큐레이션한 기기만 받아 애셋으로 굽는다.

```
dart tool/build_catalog.dart      # assets/catalog/v1.json 을 다시 만든다
dart tool/smoke_techapi.dart      # 원격 왕복 확인
```

## 디자인

두 플랫폼의 크롬이 다르다. iOS 는 반투명 유리에 블러를, Android M3 는 불투명한
톤 단계를 쓴다. 화면 코드는 플랫폼 분기를 갖지 않고 토큰만 갈아 끼운다.
명세와 다르게 간 곳은 이유를 코드 주석에 남겼다.

## 개발

```
flutter pub get
dart run build_runner build --delete-conflicting-outputs   # freezed / json
flutter run
```

```
flutter analyze
flutter test
```

Firebase 설정이 없어도 앱은 뜬다. 로그인만 안 되고 랭킹·비교·상담은 다 된다.

## 라이선스

[Apache License 2.0](LICENSE). 기기 데이터는 TechAPI 의 CC-BY-SA 4.0 을 따른다.
