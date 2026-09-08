import Foundation

/// 지갑 없이 나간 날의 기록.
///
/// 기획 메모의 프레임 전환 — "지갑을 놓고 나왔다(사고)"가 아니라
/// "지갑을 일부러 안 든다(선택)" — 을 앱 안에서 눈에 보이게 만드는 장치다.
/// 정확히는 **앱으로 카드를 꺼내 쓴 날**을 센다. 그것 말고는 앱이 알 수 있는 게 없다.
struct DayLog: Codable, Equatable {
    private(set) var days: Set<String>

    init(days: Set<String> = []) {
        self.days = days
    }

    /// 날짜를 "2026-09-08" 형태의 키로. 기기 시간대 기준이다.
    static func key(for date: Date, calendar: Calendar = .current) -> String {
        let parts = calendar.dateComponents([.year, .month, .day], from: date)
        return String(format: "%04d-%02d-%02d", parts.year ?? 0, parts.month ?? 0, parts.day ?? 0)
    }

    func contains(_ date: Date, calendar: Calendar = .current) -> Bool {
        days.contains(Self.key(for: date, calendar: calendar))
    }

    /// 오늘 처음 쓴 것이면 true. 축하 배너를 띄울지 판단하는 데 쓴다.
    @discardableResult
    mutating func record(_ date: Date = Date(), calendar: Calendar = .current) -> Bool {
        days.insert(Self.key(for: date, calendar: calendar)).inserted
    }

    var total: Int { days.count }

    /// 지금 이어지고 있는 연속 일수.
    /// 오늘 아직 안 썼어도 어제까지 이어졌다면 기록은 살아 있는 것으로 본다.
    func currentStreak(asOf date: Date = Date(), calendar: Calendar = .current) -> Int {
        var anchor = calendar.startOfDay(for: date)
        if !contains(anchor, calendar: calendar) {
            guard let yesterday = calendar.date(byAdding: .day, value: -1, to: anchor),
                  contains(yesterday, calendar: calendar) else { return 0 }
            anchor = yesterday
        }
        var count = 0
        while contains(anchor, calendar: calendar) {
            count += 1
            guard let previous = calendar.date(byAdding: .day, value: -1, to: anchor) else { break }
            anchor = previous
        }
        return count
    }

    /// 역대 최장 연속. 키가 "yyyy-MM-dd"라 문자열 정렬이 곧 날짜 정렬이다.
    func longestStreak(calendar: Calendar = .current) -> Int {
        let sorted = days.sorted().compactMap { Self.date(from: $0, calendar: calendar) }
        guard !sorted.isEmpty else { return 0 }
        var longest = 1
        var run = 1
        for index in 1..<sorted.count {
            let expected = calendar.date(byAdding: .day, value: 1, to: sorted[index - 1])
            if let expected, calendar.isDate(expected, inSameDayAs: sorted[index]) {
                run += 1
            } else {
                run = 1
            }
            longest = max(longest, run)
        }
        return longest
    }

    var firstDayKey: String? { days.min() }

    static func date(from key: String, calendar: Calendar = .current) -> Date? {
        let parts = key.split(separator: "-").compactMap { Int($0) }
        guard parts.count == 3 else { return nil }
        var components = DateComponents()
        components.year = parts[0]
        components.month = parts[1]
        components.day = parts[2]
        return calendar.date(from: components)
    }
}

enum DayLogStorage {
    private static let fileName = "walletless-days.json"

    private static var url: URL {
        let base = AppGroup.containerURL
            ?? FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        return base.appendingPathComponent(fileName)
    }

    static func load() -> DayLog {
        guard let data = try? Data(contentsOf: url),
              let log = try? JSONDecoder.wallet.decode(DayLog.self, from: data) else {
            return DayLog()
        }
        return log
    }

    static func save(_ log: DayLog) {
        guard let data = try? JSONEncoder.wallet.encode(log) else { return }
        try? FileManager.default.createDirectory(
            at: url.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        try? data.write(to: url, options: [.atomic, .completeFileProtectionUntilFirstUserAuthentication])
    }
}
