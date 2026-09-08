import Foundation

/// 파일 하나에 JSON으로 저장한다. 서버도 계정도 없다.
///
/// 기획 메모의 결정: 로그인을 뺀다. 결제 관련 정보가 서버로 넘어가는 순간
/// 보안·법적 책임의 차원이 달라진다. 데이터는 기기 밖으로 나가지 않는다.
enum WalletStorage {
    private static let fileName = "wallet.json"

    private static var fileURL: URL? {
        AppGroup.containerURL?.appendingPathComponent(fileName)
    }

    /// App Group이 아직 설정되지 않았을 때를 위한 자리. 위젯은 여기를 못 읽는다.
    private static var fallbackURL: URL {
        FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent(fileName)
    }

    static var isSharedContainerAvailable: Bool { AppGroup.containerURL != nil }

    static func load() -> [WalletItem] {
        let url = fileURL ?? fallbackURL
        guard let data = try? Data(contentsOf: url) else { return [] }
        do {
            return try JSONDecoder.wallet.decode([WalletItem].self, from: data)
        } catch {
            return []
        }
    }

    @discardableResult
    static func save(_ items: [WalletItem]) -> Bool {
        let url = fileURL ?? fallbackURL
        do {
            let data = try JSONEncoder.wallet.encode(items)
            try FileManager.default.createDirectory(
                at: url.deletingLastPathComponent(),
                withIntermediateDirectories: true
            )
            // 잠금화면 위젯이 기기 잠긴 상태에서도 읽어야 하므로
            // .completeFileProtection이 아니라 첫 잠금해제 이후 접근 가능으로 둔다.
            try data.write(to: url, options: [.atomic, .completeFileProtectionUntilFirstUserAuthentication])
            return true
        } catch {
            return false
        }
    }
}

extension JSONDecoder {
    static let wallet: JSONDecoder = {
        let d = JSONDecoder()
        d.dateDecodingStrategy = .iso8601
        return d
    }()
}

extension JSONEncoder {
    static let wallet: JSONEncoder = {
        let e = JSONEncoder()
        e.dateEncodingStrategy = .iso8601
        return e
    }()
}
