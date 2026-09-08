import Combine
import Foundation
import WidgetKit

@MainActor
final class WalletStore: ObservableObject {
    @Published private(set) var items: [WalletItem] = []
    @Published private(set) var dayLog: DayLog = DayLogStorage.load()
    /// 오늘 처음 꺼내 쓴 순간에만 채워진다. 홈에서 잠깐 보여주고 지운다.
    @Published var newDayStreak: Int?

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
        recordToday()
    }

    /// 오늘 날짜를 기록에 남긴다. 하루에 한 번만 새로 잡힌다.
    private func recordToday() {
        var log = dayLog
        guard log.record() else { return }
        dayLog = log
        DayLogStorage.save(log)
        newDayStreak = log.currentStreak()
    }

    var currentStreak: Int { dayLog.currentStreak() }

    /// 장소 묶기를 켜고 끈다. 저장된 순서 값은 건드리지 않는다 —
    /// 묶기는 저장이 아니라 보여줄 때의 변환이라, 끄면 원래 손으로 정한 순서로 돌아온다.
    func setPlaceGrouping(_ enabled: Bool) {
        PlaceGrouping.isEnabled = enabled
        items = RankingEngine.ordered(items)
        WidgetCenter.shared.reloadAllTimelines()
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
