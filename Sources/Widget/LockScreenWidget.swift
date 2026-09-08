import SwiftUI
import WidgetKit

/// 잠금화면 → 바코드. 지갑 없이 나온 날 가장 짧은 경로다.
struct LockScreenWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "LockScreenWidget", provider: WalletProvider()) { entry in
            LockScreenView(entry: entry)
                .containerBackground(.clear, for: .widget)
        }
        .configurationDisplayName("잠금화면 바코드")
        .description("잠금화면에서 바로 첫 번째 카드를 엽니다.")
        .supportedFamilies([.accessoryCircular, .accessoryRectangular])
    }
}

struct LockScreenView: View {
    @Environment(\.widgetFamily) private var family
    let entry: WalletEntry

    var body: some View {
        content
            .widgetURL(destination)
    }

    @ViewBuilder
    private var content: some View {
        switch family {
        case .accessoryCircular:
            ZStack {
                AccessoryWidgetBackground()
                Image(systemName: "barcode")
                    .font(.title3)
            }
        default:
            HStack(spacing: 8) {
                Image(systemName: "barcode")
                VStack(alignment: .leading, spacing: 2) {
                    Text(entry.items.first?.name ?? "지갑 없는 날")
                        .font(.headline)
                        .lineLimit(1)
                    Text(entry.items.isEmpty ? "카드 등록하기" : "탭하면 바코드")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var destination: URL {
        guard let first = entry.items.first else { return DeepLink.home }
        return DeepLink.barcode(first.id, from: .lockScreen)
    }
}
