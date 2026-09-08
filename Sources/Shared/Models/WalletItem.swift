import Foundation

/// 홈에서 한 장씩 넘겨보는 카드 하나.
/// 멤버십(바코드를 앱이 직접 그림) 또는 페이 앱(딥링크로 넘김) 중 하나다.
struct WalletItem: Identifiable, Codable, Hashable, Sendable {
    enum Kind: String, Codable, Sendable {
        case membership   // 멤버십·포인트 — 앱 안에서 바코드까지 끝난다
        case payApp       // 결제 — 각 페이 앱으로 넘긴다
    }

    var id: UUID
    var kind: Kind
    var name: String
    var memo: String
    var barcode: Barcode?
    /// PayAppCatalog의 키. kind == .payApp일 때만 값이 있다.
    var payAppID: String?
    var tintHex: String
    /// 사용자가 직접 정한 순서. 낮을수록 앞. (1차에서는 이게 유일한 정렬 신호)
    var order: Int
    var usageCount: Int
    var lastUsedAt: Date?
    var createdAt: Date

    init(
        id: UUID = UUID(),
        kind: Kind,
        name: String,
        memo: String = "",
        barcode: Barcode? = nil,
        payAppID: String? = nil,
        tintHex: String = "#3B5BDB",
        order: Int = 0,
        usageCount: Int = 0,
        lastUsedAt: Date? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.kind = kind
        self.name = name
        self.memo = memo
        self.barcode = barcode
        self.payAppID = payAppID
        self.tintHex = tintHex
        self.order = order
        self.usageCount = usageCount
        self.lastUsedAt = lastUsedAt
        self.createdAt = createdAt
    }

    var payApp: PayApp? {
        guard let payAppID else { return nil }
        return PayAppCatalog.app(id: payAppID)
    }

    /// 카드에 적히는 한 줄. 계산대 앞에서 읽을 수 있어야 하므로 짧게.
    var subtitle: String {
        if !memo.isEmpty { return memo }
        switch kind {
        case .membership:
            return barcode?.symbology.displayName ?? "바코드 없음"
        case .payApp:
            return payApp.map { "\($0.name) 열기" } ?? "앱 열기"
        }
    }
}
