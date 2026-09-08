import Foundation

/// 앱 본체와 위젯이 같은 데이터를 보려면 App Group이 필요하다.
/// 팀 계정에 맞게 이 값 하나만 바꾸면 된다. (entitlements 두 개도 같이 수정)
enum AppGroup {
    static let identifier = "group.com.example.walletless"

    /// 저장 파일이 들어갈 공유 컨테이너. App Group 설정이 빠지면 nil이 된다.
    static var containerURL: URL? {
        FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: identifier)
    }

    static var defaults: UserDefaults {
        UserDefaults(suiteName: identifier) ?? .standard
    }
}

/// 위젯 → 앱 직행 경로. 탭 한 번에 바코드까지 가는 링크.
enum DeepLink {
    static let scheme = "walletless"

    /// 어디서 들어왔는지. 진입 경로별 속도를 따로 재기 위해 링크에 실어 보낸다.
    enum Source: String, Codable, Sendable, CaseIterable {
        case app
        case widget
        case lockScreen
        case shortcut     // 시리 · 단축어 · 뒷면 탭 · 액션 버튼 · Spotlight
        case control      // 제어 센터

        var label: String {
            switch self {
            case .app: return "앱 아이콘"
            case .widget: return "홈 위젯"
            case .lockScreen: return "잠금화면"
            case .shortcut: return "시리 · 뒷면 탭"
            case .control: return "제어 센터"
            }
        }

        /// 탭 없이 도달하는 경로인지. 이 앱이 노리는 것은 이쪽이다.
        var isTapless: Bool {
            self == .shortcut || self == .control
        }
    }

    /// 어떤 카드인지 모르는 쪽(제어 센터, App Group 없는 위젯)에서 쓰는 링크.
    /// 앱이 열릴 때 맨 앞 카드를 스스로 골라 연다 — 데이터 공유가 필요 없다.
    static func topBarcode(from source: Source = .widget) -> URL {
        url(path: topKeyword, source: source)
    }

    static func barcode(_ id: UUID, from source: Source = .widget) -> URL {
        url(path: id.uuidString, source: source)
    }

    private static let topKeyword = "top"

    private static func url(path: String, source: Source) -> URL {
        var components = URLComponents()
        components.scheme = scheme
        components.host = "barcode"
        components.path = "/\(path)"
        components.queryItems = [URLQueryItem(name: "from", value: source.rawValue)]
        return components.url!
    }

    static let home = URL(string: "\(scheme)://home")!

    enum Route: Equatable {
        case barcode(UUID, Source)
        /// 맨 앞 카드. 링크를 만든 쪽이 카드 목록을 모를 때 쓴다.
        case topBarcode(Source)
        case home
    }

    static func route(for url: URL) -> Route? {
        guard url.scheme == scheme else { return nil }
        switch url.host {
        case "barcode", "item":
            guard let raw = url.pathComponents.first(where: { $0 != "/" }) else { return nil }
            let rawSource = URLComponents(url: url, resolvingAgainstBaseURL: false)?
                .queryItems?.first { $0.name == "from" }?.value
            let source = rawSource.flatMap(Source.init(rawValue:)) ?? .widget
            if raw == topKeyword { return .topBarcode(source) }
            guard let id = UUID(uuidString: raw) else { return nil }
            return .barcode(id, source)
        case "home":
            return .home
        default:
            return nil
        }
    }
}
