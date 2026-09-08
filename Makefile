.PHONY: project open clean

# XcodeGen이 없으면: brew install xcodegen
project:
	xcodegen generate

open: project
	open Walletless.xcodeproj

clean:
	rm -rf Walletless.xcodeproj build
