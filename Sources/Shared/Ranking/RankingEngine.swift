import Foundation

/// 같은 장소에서 쓰는 카드를 붙여둘지에 대한 설정.
enum PlaceGrouping {
    private static let key = "groupCardsByPlace"

    static var isEnabled: Bool {
        get { AppGroup.defaults.object(forKey: key) as? Bool ?? true }
        set { AppGroup.defaults.set(newValue, forKey: key) }
    }
}

/// 홈에서 카드를 어떤 순서로 쌓을지 정한다.
///
/// 1차에서는 위치 기반 자동 판단을 넣지 않는다. 기획 메모대로,
/// 위치 추론은 데이터 없이는 정확도가 안 나오고 틀리면 그냥 느린 앱이 된다.
/// 지금 정렬 신호는 "사용자가 정한 순서" 하나뿐이고, 사용 기록만 조용히 쌓아둔다.
enum RankingEngine {
    static func ordered(_ items: [WalletItem]) -> [WalletItem] {
        let manual = items.sorted { lhs, rhs in
            if lhs.order != rhs.order { return lhs.order < rhs.order }
            return lhs.createdAt < rhs.createdAt
        }
        guard PlaceGrouping.isEnabled else { return manual }
        return groupedByPlace(manual)
    }

    /// 같은 장소 카드를 붙여서 내보낸다.
    ///
    /// 편의점 카드가 1번·5번·8번에 흩어져 있으면 계산대 앞에서 세 번을 찾아 헤맨다.
    /// 붙여두면 첫 장이 편의점 카드일 때 아래로 한 번만 밀어 다음 편의점 카드가 나온다.
    ///
    /// 사용자 순서를 갈아엎지 않는 것이 중요하다. 그래서 순서를 새로 만들지 않고
    /// **사용자 순서에서 파생**시킨다 —
    /// - 장소 묶음의 순서 = 그 장소의 첫 카드가 사용자 순서에서 나온 자리
    /// - 묶음 안의 순서 = 사용자 순서 그대로
    ///
    /// 그래서 맨 앞 카드는 절대 바뀌지 않는다. 탭 0회 경로가 여는 것이 그 카드다.
    /// 이미 묶인 목록에 다시 적용해도 결과가 같다(멱등).
    private static func groupedByPlace(_ items: [WalletItem]) -> [WalletItem] {
        var groupOrder: [String] = []
        var buckets: [String: [WalletItem]] = [:]

        for item in items {
            // 여러 장소를 고른 카드는 첫 번째 장소를 따른다. 사용자가 먼저 누른 것이다.
            let key = item.places.first?.rawValue ?? ""
            if buckets[key] == nil {
                groupOrder.append(key)
                buckets[key] = []
            }
            buckets[key]?.append(item)
        }
        return groupOrder.flatMap { buckets[$0] ?? [] }
    }

    /// 2차 후보: 여기서 위치·시간 신호를 섞는다.
    /// 자동 정렬을 켜기 전에 필요한 것 —
    /// (1) 사용 기록이 충분히 쌓였는지, (2) 자동 순서가 수동 순서보다 실제로 빨랐는지.
    static func hasEnoughUsageForAutoRanking(_ items: [WalletItem]) -> Bool {
        items.reduce(0) { $0 + $1.usageCount } >= 30
    }
}
