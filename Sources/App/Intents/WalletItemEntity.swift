import AppIntents
import Foundation

/// 단축어·시리에서 "어느 카드?"를 고르게 하기 위한 표현.
struct WalletItemEntity: AppEntity {
    static var typeDisplayRepresentation: TypeDisplayRepresentation = "카드"
    static var defaultQuery = WalletItemQuery()

    var id: UUID
    var name: String

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(name)")
    }
}

struct WalletItemQuery: EntityQuery {
    func entities(for identifiers: [UUID]) async throws -> [WalletItemEntity] {
        available().filter { identifiers.contains($0.id) }
    }

    func suggestedEntities() async throws -> [WalletItemEntity] {
        available()
    }

    /// 바코드가 있는 카드만. 페이 앱 바로가기는 전체화면으로 띄울 것이 없다.
    private func available() -> [WalletItemEntity] {
        RankingEngine.ordered(WalletStorage.load())
            .filter { $0.barcode != nil }
            .map { WalletItemEntity(id: $0.id, name: $0.name) }
    }
}
