import SwiftUI

/// 실질적인 최종 화면. 여기까지 오는 데 걸린 시간이 이 앱의 존재 이유다.
/// 검은 배경 + 흰 카드 + 최대 밝기 — 매장 스캐너가 가장 잘 읽는 조합.
struct BarcodeStageView: View {
    let item: WalletItem

    @EnvironmentObject private var store: WalletStore
    @Environment(\.dismiss) private var dismiss

    init(item: WalletItem) {
        self.item = item
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 28) {
                Text(item.name)
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(.white)

                if let barcode = item.barcode {
                    VStack(spacing: 16) {
                        BarcodeView(barcode: barcode, height: 150)
                        Text(barcode.groupedValue)
                            .font(.system(.title3, design: .monospaced).weight(.medium))
                            .foregroundStyle(.black)
                            .textSelection(.enabled)
                    }
                    .padding(24)
                    .background(.white, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
                    .padding(.horizontal, 20)
                }

                Text("화면 밝기를 최대로 올렸어요")
                    .font(.footnote)
                    .foregroundStyle(.white.opacity(0.45))
            }
        }
        .maxBrightnessWhileVisible()
        .overlay(alignment: .topTrailing) {
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.6))
                    .padding(16)
            }
            .accessibilityLabel("닫기")
        }
        .statusBarHidden()
        .persistentSystemOverlays(.hidden)
        .onAppear {
            SpeedMetrics.shared.recordBarcodeShown()
            store.markUsed(id: item.id)
        }
    }
}
