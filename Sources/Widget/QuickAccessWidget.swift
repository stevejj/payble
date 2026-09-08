import SwiftUI
import WidgetKit

/// 홈 화면 → 바코드. 탭 한 번.
/// 이 경로가 앱 아이콘 경로보다 빨라야 이 앱이 존재할 이유가 생긴다.
struct QuickAccessWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "QuickAccessWidget", provider: WalletProvider()) { entry in
            QuickAccessView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("바로 꺼내기")
        .description("탭 한 번에 바코드가 전체화면으로 열립니다.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

struct QuickAccessView: View {
    @Environment(\.widgetFamily) private var family
    let entry: WalletEntry

    var body: some View {
        if entry.items.isEmpty {
            emptyState
        } else if family == .systemSmall {
            small(entry.items[0])
                .widgetURL(DeepLink.barcode(entry.items[0].id, from: .widget))
        } else {
            medium
        }
    }

    private func small(_ item: WalletItem) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: "barcode")
                .font(.title2)
                .foregroundStyle(Color(hex: item.tintHex))
            Spacer(minLength: 0)
            Text(item.name)
                .font(.headline)
                .lineLimit(2)
                .minimumScaleFactor(0.7)
            Text("탭하면 바코드")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
    }

    private var medium: some View {
        VStack(spacing: 6) {
            ForEach(entry.items.prefix(3)) { item in
                Link(destination: DeepLink.barcode(item.id, from: .widget)) {
                    HStack(spacing: 10) {
                        Circle()
                            .fill(Color(hex: item.tintHex))
                            .frame(width: 8, height: 8)
                        Text(item.name)
                            .font(.subheadline.weight(.medium))
                            .lineLimit(1)
                        Spacer()
                        Image(systemName: "barcode")
                            .foregroundStyle(.secondary)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .background(.background.opacity(0.5), in: RoundedRectangle(cornerRadius: 10))
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    /// 카드를 읽지 못하는 상태에서도 위젯은 여전히 최단 경로여야 한다.
    /// 이름을 못 띄울 뿐, 맨 앞 카드를 여는 것은 앱이 스스로 할 수 있다.
    private var emptyState: some View {
        VStack(spacing: 6) {
            Image(systemName: "barcode")
                .font(.title2)
            Text(entry.sharedContainerAvailable ? "카드를 먼저 등록하세요" : "바코드 열기")
                .font(.caption)
                .multilineTextAlignment(.center)
        }
        .foregroundStyle(.secondary)
        .widgetURL(entry.sharedContainerAvailable ? DeepLink.home : DeepLink.topBarcode(from: .widget))
    }
}
