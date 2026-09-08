import SwiftUI

/// 홈에서 화면을 가득 채우는 카드 한 장.
/// 목록이 아니라 한 장이어야 한다 — 계산대 앞에서 고르게 만들면 실패다.
struct ItemCardView: View {
    let item: WalletItem
    let action: () -> Void

    private var tint: Color { Color(hex: item.tintHex) }
    private var foreground: Color { .readableForeground(on: item.tintHex) }

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 20) {
                HStack {
                    Label(
                        item.kind == .membership ? "멤버십" : "결제",
                        systemImage: item.kind == .membership ? "barcode" : "creditcard"
                    )
                    .font(.subheadline.weight(.semibold))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(foreground.opacity(0.15), in: Capsule())
                    Spacer()
                }

                Spacer(minLength: 0)

                VStack(alignment: .leading, spacing: 8) {
                    Text(item.name)
                        .font(.system(size: 44, weight: .bold))
                        .minimumScaleFactor(0.5)
                        .lineLimit(2)
                    Text(item.subtitle)
                        .font(.title3)
                        .opacity(0.75)
                }

                Spacer(minLength: 0)

                footer
            }
            .foregroundStyle(foreground)
            .padding(28)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
            .background(
                LinearGradient(
                    colors: [tint, tint.opacity(0.78)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 32, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private var footer: some View {
        if let barcode = item.barcode {
            VStack(spacing: 12) {
                BarcodeView(barcode: barcode, height: 56)
                    .padding(12)
                    .background(.white, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                Text("탭하면 전체화면 · 밝기 최대")
                    .font(.footnote.weight(.medium))
                    .opacity(0.8)
            }
        } else {
            HStack(spacing: 8) {
                Text(item.kind == .payApp ? "탭하면 앱이 열려요" : "탭해서 바코드를 등록하세요")
                Image(systemName: "arrow.up.right")
            }
            .font(.headline)
            .padding(.vertical, 14)
            .frame(maxWidth: .infinity)
            .background(foreground.opacity(0.15), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
    }
}
