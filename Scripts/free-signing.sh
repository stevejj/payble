#!/bin/bash
#
# 무료 Apple ID(개인 팀)로 실기기 테스트할 때 쓰는 설정.
#
# 무료 개인 팀은 App Groups capability를 지원하지 않는다.
# entitlement가 남아 있으면 Xcode가 서명 단계에서 거부하므로 비운다.
# 앱은 App Group이 없으면 자동으로 앱 내부 저장소로 넘어가도록 만들어져 있어
# (WalletStorage.fallbackURL) 본체 기능은 그대로 동작한다. 위젯만 데이터를 못 읽는다.
#
# 되돌리기: make paid
#
set -euo pipefail

cd "$(dirname "$0")/.."

PREFIX="${1:-}"
TEAM_ID="${2:-}"

if ! command -v xcodegen >/dev/null 2>&1; then
  echo "XcodeGen이 필요합니다. 먼저 실행하세요: brew install xcodegen"
  exit 1
fi

if [ -z "$PREFIX" ]; then
  cat <<'USAGE'
사용법: Scripts/free-signing.sh <번들ID접두사> [팀ID]

  번들ID접두사  전 세계에서 유일해야 한다. 보통 본인 도메인을 뒤집어 쓴다.
                예: com.jjong.walletless
  팀ID          선택. 생략하면 Xcode에서 직접 고르면 된다.
                Xcode > Settings > Accounts에서 확인할 수 있다.

예: Scripts/free-signing.sh com.jjong.walletless
USAGE
  exit 1
fi

python3 - "$PREFIX" "$TEAM_ID" <<'PY'
import sys, pathlib

prefix, team = sys.argv[1], sys.argv[2]

EMPTY_ENTITLEMENTS = '''<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<!-- 무료 개인 팀은 App Groups를 지원하지 않아 비워 둔다. 되돌리려면 make paid -->
</dict>
</plist>
'''

for path in [
    "Sources/App/Resources/Walletless.entitlements",
    "Sources/Widget/WalletlessWidget.entitlements",
]:
    pathlib.Path(path).write_text(EMPTY_ENTITLEMENTS)
    print(f"  비움  {path}")

spec = pathlib.Path("project.yml")
text = spec.read_text()

# 긴 것부터 바꿔야 위젯 번들 ID가 앞쪽 치환에 먹히지 않는다.
replacements = [
    ("com.example.walletless.widget", f"{prefix}.widget"),
    ("com.example.walletless", prefix),
]
for old, new in replacements:
    if old not in text:
        raise SystemExit(
            f"project.yml에서 '{old}' 를 찾지 못했습니다. "
            "이미 바꿨거나 파일 구조가 달라졌습니다. make paid 로 원복한 뒤 다시 시도하세요."
        )
    text = text.replace(old, new)
    print(f"  번들ID  {old} → {new}")

if team:
    old_team = 'DEVELOPMENT_TEAM: ""'
    if old_team not in text:
        raise SystemExit("project.yml에서 DEVELOPMENT_TEAM 줄을 찾지 못했습니다.")
    text = text.replace(old_team, f'DEVELOPMENT_TEAM: "{team}"')
    print(f"  팀ID    {team}")

spec.write_text(text)
PY

echo ""
xcodegen generate

cat <<'NEXT'

준비됐습니다. 이제 Xcode에서:

  1. make open  (또는 Walletless.xcodeproj 열기)
  2. 두 타겟(Walletless, WalletlessWidget) 각각
     Signing & Capabilities > Team 에서 본인 Apple ID의 Personal Team 선택
     (팀ID를 인자로 넘겼다면 이미 선택되어 있다)
  3. 아이폰을 케이블로 연결하고 실행 대상으로 선택 후 Run
  4. 아이폰 > 설정 > 일반 > VPN 및 기기 관리 에서 본인 개발자 인증서 신뢰

알아둘 것:
  - 무료 설치는 7일 후 만료된다. 맥에 다시 연결해 Run 하면 갱신된다.
  - 위젯은 카드가 비어 보인다. App Groups가 없어 앱 데이터를 읽지 못하기 때문이며,
    유료 프로그램에 가입하면 make paid 후 정상 동작한다.
  - 앱 안의 설정 화면에도 같은 경고가 표시된다.
NEXT
