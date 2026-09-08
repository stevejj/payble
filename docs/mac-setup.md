# 맥북 처음 세팅하기

아무것도 깔려 있지 않은 맥북 기준입니다.
**Xcode 다운로드가 제일 오래 걸리니(10GB 이상, 30분~1시간+) 그것부터 걸어두고
나머지를 병렬로 진행하세요.**

## 1. Xcode 설치 시작 ← 제일 먼저

App Store에서 Xcode를 검색해 설치를 누릅니다. 받는 동안 아래를 진행합니다.

## 2. Homebrew 설치

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

설치가 끝나면 `Next steps`에 PATH를 추가하라는 두 줄이 나옵니다.
**그대로 복사해서 실행하세요.** Apple Silicon에서는 이걸 하지 않으면 `brew` 명령을 못 찾습니다.
중간에 Command Line Tools도 함께 설치됩니다.

## 3. XcodeGen 설치와 코드 내려받기

```bash
brew install xcodegen
git clone https://github.com/stevejj/payble.git
cd payble
git checkout claude/conversation-app-development-3zeyyq
```

저장소가 public이라 로그인 없이 받아집니다.
**브랜치 체크아웃을 빠뜨리면 안 됩니다** — `main`에는 README만 있습니다.

## 4. Xcode 첫 실행

추가 구성요소 설치를 묻습니다. 설치 후 `Xcode > Settings > Accounts`에서
**본인 Apple ID로 로그인**합니다. 무료 계정으로 충분합니다.

## 5. 프로젝트 생성

```bash
make free PREFIX=com.본인이름.walletless
make open
```

`PREFIX`는 전 세계에서 유일해야 합니다. 본인 이름이나 도메인을 뒤집어 넣으세요.
`make free`가 하는 일은 App Groups entitlement 비우기 + 번들 ID 치환 + 프로젝트 재생성입니다.
(무료 개인 팀은 App Groups를 지원하지 않아 그대로 두면 Xcode가 서명을 거부합니다.)

## 6. 팀 선택

Xcode 왼쪽에서 프로젝트를 클릭하고, **`Walletless`와 `WalletlessWidget` 두 타겟 각각**
`Signing & Capabilities` 탭에서 Team을 본인 Personal Team으로 고릅니다.

## 7. 아이폰 연결

케이블로 연결하고 아이폰에서 "이 컴퓨터를 신뢰"를 누릅니다.
무선 디버깅도 되지만 최초 연결은 케이블이 필요합니다.

## 8. 아이폰 개발자 모드 켜기 ← 빠뜨리기 쉬움

설정 → 개인정보 보호 및 보안 → 맨 아래 **개발자 모드** → 켜기 → **재시동됩니다.**
맥에 한 번 연결한 뒤에야 이 메뉴가 나타납니다.

## 9. 실행

Xcode 상단에서 실행 대상을 본인 아이폰으로 바꾸고 ▶︎ 를 누릅니다.

## 10. 인증서 신뢰 ← 이것도 자주 막힘

설정 → 일반 → VPN 및 기기 관리 → 본인 Apple ID → 신뢰.
이걸 안 하면 앱을 눌러도 "신뢰되지 않은 개발자"라며 열리지 않습니다.

---

## 미리 확인해두면 좋은 것

- **케이블** — 아이폰 기종에 맞는 것(USB-C 또는 라이트닝)
- **macOS 버전** — `sw_vers`. 이 프로젝트는 Xcode 15 이상이 필요하고,
  그건 macOS 13.5 이상에서 돌아갑니다. 더 낮으면 macOS 업데이트가 먼저입니다.
- **디스크 여유** — Xcode와 시뮬레이터까지 20~30GB

## 무료 계정의 제약

| 확인 가능 | 확인 불가 |
|---|---|
| 앱 실행, 카드 등록, 카메라 스캔 | 위젯에 카드 **이름** 표시 |
| 전체화면 바코드 + 밝기 최대 | (App Groups가 유료 전용) |
| 딥링크 진단 | TestFlight 배포 |
| 뒷면 탭·시리·제어 센터 0탭 경로 | |
| 위젯의 "바코드 열기" 버튼 | |

무료 설치는 **7일 후 만료**되며 맥에 다시 연결해 Run 하면 갱신됩니다.
유료 가입 후에는 `make paid`로 App Groups를 복구합니다.

## 설치 후 확인할 것 (우선순위)

1. **설정 → 딥링크 진단** — 어떤 페이 앱 scheme이 살아 있는지.
   코드가 추측으로 넣은 후보들이라 여기가 가장 불확실합니다.
2. **편의점 멤버십을 등록하고 실제 계산대에서 찍어보기.**
   직접 구현한 EAN-13 인코더의 진짜 검증입니다. 이게 깨지면 나머지는 의미가 없습니다.
3. **설정 → 탭 없이 열기 → 뒷면 탭 연결**, 그다음 카카오페이 켜는 시간과 스톱워치 비교.
   설정 → 속도에 경로별 중앙값이 쌓입니다.
