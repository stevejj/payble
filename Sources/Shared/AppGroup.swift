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
    enum Source: String, Codable, Sendable {
        case app
        case widget
        case lockScreen

        var label: String {
            switch self {
            case .app: return "앱 아이콘"
            case .widget: return "홈 위젯"
            case .lockScreen: return "잠금화면"
            }
        }
    }

    static func barcode(_ id: UUID, from source: Source = .widget) -> URL {
        var components = URLComponents()
        components.scheme = scheme
        components.host = "barcode"
        components.path = "/\(id.uuidString)"
        components.queryItems = [URLQueryItem(name: "from", value: source.rawValue)]
        return components.url!
    }

    static let home = URL(string: "\(scheme)://home")!

    enum Route: Equatable {
        case barcode(UUID, Source)
        case home
    }

    static func route(for url: URL) -> Route? {
        guard url.scheme == scheme else { return nil }
        switch url.host {
        case "barcode", "item":
            let raw = url.pathComponents.first { $0 != "/" }
            guard let raw, let id = UUID(uuidString: raw) else { return nil }
            let rawSource = URLComponents(url: url, resolvingAgainstBaseURL: false)?
                .queryItems?.first { $0.name == "from" }?.value
            return .barcode(id, rawSource.flatMap(Source.init(rawValue:)) ?? .widget)
        case "home":
            return .home
        default:
            return nil
        }
    }
}
