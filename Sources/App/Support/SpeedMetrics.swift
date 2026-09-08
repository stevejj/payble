import Foundation

/// 이 앱의 최우선 지표: **앱 실행 → 바코드 표시까지 걸린 시간과 탭 횟수.**
///
/// 기획 메모의 1차 목표가 "카카오페이 켜는 것보다 빠른가"이므로
/// 그 질문에 숫자로 답할 수 있어야 한다. 기록은 기기 안에만 남는다.
@MainActor
final class SpeedMetrics: ObservableObject {
    static let shared = SpeedMetrics()

    typealias Entry = DeepLink.Source

    struct Record: Codable, Identifiable {
        var id: UUID = UUID()
        var entry: Entry
        var seconds: Double
        var taps: Int
        var at: Date
    }

    @Published private(set) var records: [Record] = []

    private let launchedAt = monotonicNow()
    private var hasActivatedOnce = false
    private var sessionStart: CFTimeInterval?
    private var entry: Entry = .app
    private var entryOverriddenAt: CFTimeInterval?
    private var taps = 0
    private let key = "speedRecords"
    private let limit = 100

    private init() {
        if let data = AppGroup.defaults.data(forKey: key),
           let decoded = try? JSONDecoder.wallet.decode([Record].self, from: data) {
            records = decoded
        }
    }

    /// 앱이 화면에 올라온 순간. 여기서부터 스톱워치가 돈다.
    ///
    /// 콜드 런치에서는 프로세스가 시작된 시점부터 재야 실제 체감과 맞는다.
    /// 위젯 링크가 scenePhase 변화보다 먼저 도착하는 경우가 있어,
    /// 방금 지정된 진입점과 탭 수는 지우지 않는다.
    func beginSession() {
        let now = monotonicNow()
        let hasFreshEntry = entryOverriddenAt.map { now - $0 < 2 } ?? false
        if !hasFreshEntry {
            entry = .app
            taps = 0
        }
        sessionStart = hasActivatedOnce ? now : launchedAt
        hasActivatedOnce = true
    }

    /// 위젯·잠금화면에서 들어온 경우 진입점을 덮어쓴다.
    func setEntry(_ newEntry: Entry) {
        entry = newEntry
        entryOverriddenAt = monotonicNow()
    }

    /// 바코드로 가는 길목의 탭. 이 숫자가 2를 넘으면 설계가 실패한 것이다.
    func countTap() {
        taps += 1
    }

    /// 바코드가 실제로 화면을 채운 순간.
    func recordBarcodeShown() {
        guard let start = sessionStart else { return }
        sessionStart = nil
        entryOverriddenAt = nil
        let record = Record(entry: entry, seconds: monotonicNow() - start, taps: taps, at: Date())
        records = Array((records + [record]).suffix(limit))
        persist()
    }

    func reset() {
        records = []
        persist()
    }

    var medianSeconds: Double? { median(of: records) }

    var averageTaps: Double? {
        guard !records.isEmpty else { return nil }
        return Double(records.map(\.taps).reduce(0, +)) / Double(records.count)
    }

    func medianSeconds(for entry: Entry) -> Double? {
        median(of: records.filter { $0.entry == entry })
    }

    func count(for entry: Entry) -> Int {
        records.filter { $0.entry == entry }.count
    }

    private func median(of records: [Record]) -> Double? {
        let values = records.map(\.seconds).sorted()
        guard !values.isEmpty else { return nil }
        return values[values.count / 2]
    }

    private func persist() {
        guard let data = try? JSONEncoder.wallet.encode(records) else { return }
        AppGroup.defaults.set(data, forKey: key)
    }
}

/// 시스템 시계 변경에 영향받지 않는 단조 시간.
private func monotonicNow() -> CFTimeInterval {
    ProcessInfo.processInfo.systemUptime
}
