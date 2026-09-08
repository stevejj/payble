import Foundation

/// 홈에서 카드를 어떤 순서로 쌓을지 정한다.
///
/// 1차에서는 자동 판단을 넣지 않는다. 기획 메모대로,
/// 위치 기반 추론은 데이터 없이는 정확도가 안 나오고 틀리면 그냥 느린 앱이 된다.
/// 지금은 "사용자가 정한 순서"가 전부이고, 사용 기록만 조용히 쌓아둔다.
enum RankingEngine {
    static func ordered(_ items: [WalletItem]) -> [WalletItem] {
        items.sorted { lhs, rhs in
            if lhs.order != rhs.order { return lhs.order < rhs.order }
            return lhs.createdAt < rhs.createdAt
        }
    }

    /// 2차 후보: 여기서 위치·시간 신호를 섞는다.
    /// 자동 정렬을 켜기 전에 필요한 것 —
    /// (1) 사용 기록이 충분히 쌓였는지, (2) 자동 순서가 수동 순서보다 실제로 빨랐는지.
    static func hasEnoughUsageForAutoRanking(_ items: [WalletItem]) -> Bool {
        items.reduce(0) { $0 + $1.usageCount } >= 30
    }
}
