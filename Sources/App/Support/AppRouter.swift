import SwiftUI
import UIKit

@MainActor
final class AppRouter: ObservableObject {
    /// 전체화면 바코드로 띄울 항목. 위젯에서 들어오면 앱이 뜨자마자 채워진다.
    @Published var stagedItemID: UUID?
    @Published var showsOnboarding = false
    @Published var showsSettings = false
    @Published var showsRecord = false
    @Published var editingItem: WalletItem?
    @Published var isAddingItem = false

    private let onboardedKey = "hasCompletedOnboarding"

    init() {
        showsOnboarding = !AppGroup.defaults.bool(forKey: onboardedKey)
    }

    func finishOnboarding() {
        AppGroup.defaults.set(true, forKey: onboardedKey)
        showsOnboarding = false
    }

    func resetOnboarding() {
        AppGroup.defaults.set(false, forKey: onboardedKey)
        showsOnboarding = true
    }

    func handle(_ url: URL, store: WalletStore) {
        switch DeepLink.route(for: url) {
        case .barcode(let id, let source):
            enter(source)
            stagedItemID = id
        case .topBarcode(let source):
            // 링크를 만든 쪽은 카드가 뭔지 모른다. 여기서 맨 앞 카드를 고른다.
            enter(source)
            stagedItemID = store.topBarcodeItem?.id
        case .home, .none:
            break
        }
    }

    /// 시리·단축어·제어 센터가 남긴 요청을 화면이 준비된 뒤 집어간다.
    func open(_ request: PendingRoute.Request, store: WalletStore) {
        enter(.shortcut)
        switch request {
        case .top:
            stagedItemID = store.topBarcodeItem?.id
        case .item(let id):
            stagedItemID = id
        }
    }

    private func enter(_ source: DeepLink.Source) {
        SpeedMetrics.shared.setEntry(source)
        // 탭 없이 도달하는 경로는 탭을 세지 않는다. 그게 이 경로의 존재 이유다.
        if !source.isTapless {
            SpeedMetrics.shared.countTap()
        }
    }

    /// 카드를 눌렀을 때. 멤버십은 앱 안에서 끝나고, 페이 앱은 밖으로 넘긴다.
    func activate(_ item: WalletItem, store: WalletStore) {
        SpeedMetrics.shared.countTap()
        switch item.kind {
        case .membership:
            guard item.barcode != nil else {
                editingItem = item
                return
            }
            stagedItemID = item.id
        case .payApp:
            store.markUsed(id: item.id)
            guard let app = item.payApp else { return }
            PayAppLauncher.open(app)
        }
    }
}

enum PayAppLauncher {
    /// 확인된 scheme이 있으면 그것부터. 없으면 후보를 차례로 시도하고,
    /// 성공한 scheme을 기억해 다음부터 바로 쓴다.
    static func open(_ app: PayApp) {
        var candidates = app.schemeCandidates
        if let resolved = ResolvedScheme.get(app.id) {
            candidates = [resolved] + candidates.filter { $0 != resolved }
        }
        for candidate in candidates {
            guard let url = URL(string: candidate), UIApplication.shared.canOpenURL(url) else { continue }
            ResolvedScheme.set(candidate, for: app.id)
            UIApplication.shared.open(url)
            return
        }
        // 하나도 못 열면 설치 안 된 것으로 본다.
        ResolvedScheme.set(nil, for: app.id)
        UIApplication.shared.open(app.appStoreSearchURL)
    }

    static func installedScheme(for app: PayApp) -> String? {
        app.schemeCandidates.first { candidate in
            guard let url = URL(string: candidate) else { return false }
            return UIApplication.shared.canOpenURL(url)
        }
    }
}
