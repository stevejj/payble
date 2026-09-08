import AppIntents

/// 맨 앞 카드를 연다. 카드를 고를 필요가 없어서 가장 짧은 경로에 쓴다 —
/// 뒷면 탭, 액션 버튼, "시리야" 한 마디.
struct OpenTopBarcodeIntent: AppIntent {
    static var title: LocalizedStringResource = "바코드 열기"
    static var description = IntentDescription("맨 앞 카드의 바코드를 전체화면으로 엽니다.")
    static var openAppWhenRun = true

    @MainActor
    func perform() async throws -> some IntentResult {
        PendingRoute.shared.request(.top)
        return .result()
    }
}

/// 특정 카드를 지정해서 연다. 단축어에서 카드별로 만들어 두면
/// "편의점 바코드" 같은 문장으로 부를 수 있다.
struct OpenBarcodeIntent: AppIntent {
    static var title: LocalizedStringResource = "특정 카드 바코드 열기"
    static var description = IntentDescription("고른 카드의 바코드를 전체화면으로 엽니다.")
    static var openAppWhenRun = true

    @Parameter(title: "카드")
    var card: WalletItemEntity

    init() {}

    init(card: WalletItemEntity) {
        self.card = card
    }

    static var parameterSummary: some ParameterSummary {
        Summary("\(\.$card) 바코드 열기")
    }

    @MainActor
    func perform() async throws -> some IntentResult {
        PendingRoute.shared.request(.item(card.id))
        return .result()
    }
}

/// 사용자가 아무 설정도 하지 않아도 시리와 Spotlight에 잡히게 한다.
struct WalletlessShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: OpenTopBarcodeIntent(),
            phrases: [
                "\(.applicationName) 바코드",
                "\(.applicationName) 바코드 열기",
                "\(.applicationName) 열기"
            ],
            shortTitle: "바코드 열기",
            systemImageName: "barcode"
        )
    }
}
