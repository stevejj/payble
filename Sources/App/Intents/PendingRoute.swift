import Combine
import Foundation

/// 시리·단축어·제어 센터가 앱을 열면서 남기는 요청.
///
/// 인텐트는 앱보다 먼저 실행될 수 있어서 화면에 바로 손댈 수 없다.
/// 그래서 요청만 여기 남기고, 화면이 준비되면 그때 집어간다.
@MainActor
final class PendingRoute: ObservableObject {
    static let shared = PendingRoute()

    enum Request: Equatable {
        case top
        case item(UUID)
    }

    @Published var pending: Request?

    private init() {}

    func request(_ request: Request) {
        pending = request
    }

    /// 한 번만 처리되도록 집어가면서 비운다.
    func take() -> Request? {
        defer { pending = nil }
        return pending
    }
}
