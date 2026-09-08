import Combine
import Foundation
import WidgetKit

@MainActor
final class WalletStore: ObservableObject {
    @Published private(set) var items: [WalletItem] = []

    init(items: [WalletItem]? = nil) {
        self.items = RankingEngine.ordered(items ?? WalletStorage.load())
    }

    var orderedItems: [WalletItem] { items }

    var membershipItems: [WalletItem] { items.filter { $0.kind == .membership } }

    /// 전체화면으로 띄울 수 있는 맨 앞 카드. "맨 앞 카드 열기" 경로가 이걸 쓴다.
    var topBarcodeItem: WalletItem? { items.first { $0.barcode != nil } }

    func item(id: UUID) -> WalletItem? { items.first { $0.id == id } }

    func upsert(_ item: WalletItem) {
        var next = items
        if let index = next.firstIndex(where: { $0.id == item.id }) {
            next[index] = item
        } else {
            var appended = item
            appended.order = (next.map(\.order).max() ?? -1) + 1
            next.append(appended)
        }
        commit(next)
    }

    func delete(id: UUID) {
        commit(items.filter { $0.id != id })
    }

    func move(fromOffsets source: IndexSet, toOffset destination: Int) {
        var next = items
        next.move(fromOffsets: source, toOffset: destination)
        for index in next.indices { next[index].order = index }
        commit(next)
    }

    /// 실제로 꺼내 쓴 순간에만 부른다. 2차 자동 정렬의 재료가 된다.
    func markUsed(id: UUID) {
        guard let index = items.firstIndex(where: { $0.id == id }) else { return }
        var next = items
        next[index].usageCount += 1
        next[index].lastUsedAt = Date()
        commit(next)
    }

    func replaceAll(_ newItems: [WalletItem]) {
        var next = newItems
        for index in next.indices { next[index].order = index }
        commit(next)
    }

    private func commit(_ next: [WalletItem]) {
        items = RankingEngine.ordered(next)
        WalletStorage.save(items)
        WidgetCenter.shared.reloadAllTimelines()
    }
}
