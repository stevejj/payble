import WidgetKit

struct WalletEntry: TimelineEntry {
    let date: Date
    let items: [WalletItem]

    /// 위젯은 "탭 한 번에 바코드"만 약속한다.
    /// 페이 앱 카드는 앱을 거쳐야 해서 홉이 하나 늘기 때문에 여기 올리지 않는다.
    static func current() -> WalletEntry {
        let items = RankingEngine.ordered(WalletStorage.load())
            .filter { $0.barcode != nil }
        return WalletEntry(date: Date(), items: items)
    }

    static let placeholder = WalletEntry(
        date: Date(),
        items: [
            WalletItem(
                kind: .membership,
                name: "편의점 멤버십",
                barcode: Barcode(value: "8801062636112", symbology: .ean13),
                tintHex: "#3B5BDB"
            )
        ]
    )
}

struct WalletProvider: TimelineProvider {
    func placeholder(in context: Context) -> WalletEntry {
        .placeholder
    }

    func getSnapshot(in context: Context, completion: @escaping (WalletEntry) -> Void) {
        completion(context.isPreview ? .placeholder : .current())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<WalletEntry>) -> Void) {
        // 시간이 아니라 카드가 바뀔 때만 갱신된다. (앱에서 reloadAllTimelines 호출)
        completion(Timeline(entries: [.current()], policy: .never))
    }
}
