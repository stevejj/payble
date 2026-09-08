import SwiftUI

/// 지갑 없이 나간 날의 기록.
/// 기획서의 프레임 전환("사고"가 아니라 "선택")을 눈에 보이게 만드는 화면이다.
struct RecordView: View {
    @EnvironmentObject private var store: WalletStore
    @Environment(\.dismiss) private var dismiss

    @State private var monthOffset = 0

    init() {}

    private var log: DayLog { store.dayLog }
    private let calendar = Calendar.current

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 28) {
                    headline
                    stats
                    monthGrid
                    footnote
                }
                .padding(20)
            }
            .navigationTitle("기록")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("완료") { dismiss() }
                }
            }
        }
    }

    private var headline: some View {
        VStack(spacing: 6) {
            if log.total == 0 {
                Text("아직 기록이 없어요")
                    .font(.title2.weight(.semibold))
                Text("바코드를 한 번 꺼내면 오늘이 첫 날로 기록됩니다")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            } else {
                Text("지갑 없이")
                    .font(.headline)
                    .foregroundStyle(.secondary)
                Text("\(store.currentStreak)일째")
                    .font(.system(size: 56, weight: .bold, design: .rounded))
                    .contentTransition(.numericText())
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
    }

    private var stats: some View {
        HStack(spacing: 12) {
            StatTile(label: monthOffset == 0 ? "이번 달" : "이 달", value: "\(markedDaysInMonth)일")
            StatTile(label: "최장 연속", value: "\(log.longestStreak())일")
            StatTile(label: "전체", value: "\(log.total)일")
        }
    }

    private var monthGrid: some View {
        VStack(spacing: 12) {
            HStack {
                Button {
                    monthOffset -= 1
                } label: {
                    Image(systemName: "chevron.left")
                }
                Spacer()
                Text(monthTitle)
                    .font(.headline)
                Spacer()
                Button {
                    monthOffset += 1
                } label: {
                    Image(systemName: "chevron.right")
                }
                .disabled(monthOffset >= 0)
            }
            .padding(.horizontal, 4)

            HStack(spacing: 0) {
                ForEach(weekdaySymbols, id: \.self) { symbol in
                    Text(symbol)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity)
                }
            }

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 4), count: 7), spacing: 6) {
                ForEach(monthCells) { cell in
                    DayCell(cell: cell)
                }
            }
        }
        .padding(16)
        .background(.quaternary.opacity(0.4), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var footnote: some View {
        Text("앱으로 카드를 꺼내 쓴 날을 셉니다. 지갑을 놓고 나온 날이 아니라, 지갑 없이도 됐던 날의 기록입니다.")
            .font(.footnote)
            .foregroundStyle(.secondary)
            .multilineTextAlignment(.center)
            .padding(.horizontal, 8)
    }

    // MARK: - 달력 계산

    private var displayedMonth: Date {
        let base = calendar.startOfDay(for: Date())
        let firstOfThisMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: base)) ?? base
        return calendar.date(byAdding: .month, value: monthOffset, to: firstOfThisMonth) ?? firstOfThisMonth
    }

    private var monthTitle: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = "yyyy년 M월"
        return formatter.string(from: displayedMonth)
    }

    private var weekdaySymbols: [String] {
        let symbols = ["일", "월", "화", "수", "목", "금", "토"]
        let first = calendar.firstWeekday - 1
        return Array(symbols[first...] + symbols[..<first])
    }

    private var monthCells: [DayCellModel] {
        guard let range = calendar.range(of: .day, in: .month, for: displayedMonth) else { return [] }
        let leading = (calendar.component(.weekday, from: displayedMonth) - calendar.firstWeekday + 7) % 7
        let today = calendar.startOfDay(for: Date())

        var cells = (0..<leading).map { DayCellModel(id: "pad-\($0)", day: nil, marked: false, isToday: false) }
        for day in range {
            guard let date = calendar.date(byAdding: .day, value: day - 1, to: displayedMonth) else { continue }
            cells.append(
                DayCellModel(
                    id: DayLog.key(for: date, calendar: calendar),
                    day: day,
                    marked: log.contains(date, calendar: calendar),
                    isToday: calendar.isDate(date, inSameDayAs: today)
                )
            )
        }
        return cells
    }

    private var markedDaysInMonth: Int {
        monthCells.filter(\.marked).count
    }
}

struct DayCellModel: Identifiable {
    let id: String
    let day: Int?
    let marked: Bool
    let isToday: Bool
}

private struct DayCell: View {
    let cell: DayCellModel

    var body: some View {
        ZStack {
            if cell.marked {
                Circle().fill(Color.accentColor)
            } else if cell.isToday {
                Circle().stroke(Color.accentColor.opacity(0.5), lineWidth: 1.5)
            }
            if let day = cell.day {
                Text("\(day)")
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(cell.marked ? Color.white : .primary)
            }
        }
        .frame(height: 32)
    }
}

private struct StatTile: View {
    let label: String
    let value: String

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title3.weight(.semibold))
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(.quaternary.opacity(0.4), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}
