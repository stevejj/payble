.PHONY: project open clean free paid

# XcodeGen이 없으면: brew install xcodegen
project:
	xcodegen generate

open: project
	open Walletless.xcodeproj

clean:
	rm -rf Walletless.xcodeproj build

# 무료 Apple ID(개인 팀)로 실기기에 올릴 때. App Groups를 빼고 번들 ID를 바꾼다.
#   make free PREFIX=com.jjong.walletless
#   make free PREFIX=com.jjong.walletless TEAM=ABCD123456
free:
	@test -n "$(PREFIX)" || (echo "PREFIX가 필요합니다. 예: make free PREFIX=com.jjong.walletless"; exit 1)
	./Scripts/free-signing.sh "$(PREFIX)" "$(TEAM)"

# make free가 고친 파일을 원래대로 되돌린다. (유료 프로그램 가입 후 App Groups 복구)
paid:
	git checkout -- project.yml Sources/App/Resources/Walletless.entitlements Sources/Widget/WalletlessWidget.entitlements
	xcodegen generate
	@echo "App Groups 설정을 복구했습니다. Xcode에서 팀을 다시 선택하세요."
