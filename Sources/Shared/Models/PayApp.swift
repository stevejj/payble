import Foundation

/// 페이 앱 딥링크 카탈로그.
///
/// 중요: URL scheme은 각 앱이 비공개로 바꿀 수 있고 공식 문서도 없다.
/// 그래서 후보를 여러 개 들고 다니며 기기에서 `canOpenURL`로 확인한 뒤
/// 실제로 열리는 것을 골라 저장한다. (설정 > 딥링크 진단)
/// 확인 전까지는 어떤 scheme도 "된다"고 가정하지 않는다.
struct PayApp: Identifiable, Hashable, Sendable {
    let id: String
    let name: String
    /// 우선순위 순. 앞에서부터 열리는 것을 쓴다.
    let schemeCandidates: [String]
    let tintHex: String
    /// scheme이 하나도 안 열릴 때 보낼 곳. 앱 ID를 지어내지 않으려고 검색 링크를 쓴다.
    var appStoreSearchURL: URL {
        var c = URLComponents(string: "https://apps.apple.com/kr/search")!
        c.queryItems = [URLQueryItem(name: "term", value: name)]
        return c.url!
    }
}

enum PayAppCatalog {
    static let all: [PayApp] = [
        // 2026-09-08 실기기 확인:
        //   kakaotalk://kakaopay/home  화면이 정상적으로 열림 (결제 화면까지는 못 감)
        //   kakaopay://                "연결할 수 없는 화면입니다" 오류
        // 그래서 오류가 나는 쪽을 뒤로 뺐다. 순서는 추측이 아니라 기기에서 본 결과다.
        PayApp(
            id: "kakaopay",
            name: "카카오페이",
            schemeCandidates: ["kakaotalk://kakaopay/home", "kakaopay://", "kakaotalk://"],
            tintHex: "#FEE500"
        ),
        PayApp(
            id: "naverpay",
            name: "네이버페이",
            schemeCandidates: ["naverpayapp://", "naverpay://", "navercorp.naverpay://"],
            tintHex: "#03C75A"
        ),
        PayApp(
            id: "hyundaicard",
            name: "현대카드",
            schemeCandidates: ["hyundaicard://", "hdcard://", "hyundaicardappcard://"],
            tintHex: "#1A1A1A"
        ),
        PayApp(
            id: "payco",
            name: "페이코",
            schemeCandidates: ["payco://", "paycoapp://"],
            tintHex: "#FF2D55"
        )
    ]

    static func app(id: String) -> PayApp? {
        all.first { $0.id == id }
    }

    /// Info.plist의 LSApplicationQueriesSchemes에 들어가야 할 목록.
    /// (여기에 없으면 canOpenURL이 무조건 false를 돌려준다)
    static var allSchemeHosts: [String] {
        var seen = Set<String>()
        return all.flatMap(\.schemeCandidates).compactMap { candidate in
            guard let scheme = candidate.components(separatedBy: ":").first, !scheme.isEmpty else { return nil }
            return seen.insert(scheme).inserted ? scheme : nil
        }
    }
}

/// 기기에서 확인된 scheme을 기록해 둔다. 진단 화면이 무엇이 쓰이는지 보여줄 때 쓴다.
///
/// 여는 순서를 여기에 맡기지는 않는다. 한 번 저장된 값이 계속 앞에 서면,
/// 나중에 더 나은 후보를 1순위로 올려도 옛 선택이 이겨 버린다.
enum ResolvedScheme {
    private static let key = "resolvedSchemes"

    static func get(_ payAppID: String) -> String? {
        (AppGroup.defaults.dictionary(forKey: key) as? [String: String])?[payAppID]
    }

    static func set(_ scheme: String?, for payAppID: String) {
        var map = (AppGroup.defaults.dictionary(forKey: key) as? [String: String]) ?? [:]
        map[payAppID] = scheme
        AppGroup.defaults.set(map, forKey: key)
    }
}
