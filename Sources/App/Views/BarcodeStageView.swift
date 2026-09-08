import SwiftUI

/// 실질적인 최종 화면. 여기까지 오는 데 걸린 시간이 이 앱의 존재 이유다.
/// 검은 배경 + 흰 카드 + 최대 밝기 — 매장 스캐너가 가장 잘 읽는 조합.
struct BarcodeStageView: View {
    let item: WalletItem

    @EnvironmentObject private var store: WalletStore
    @Environment(\.dismiss) private var dismiss

    /// 아래로 쓸어내려 닫기. 손가락을 따라 내려가야 닫히는 중이라는 게 보인다.
    @State private var dragOffset: CGFloat = 0

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
            // 배경은 검은 채로 두고 내용만 따라 내려간다. 뒤가 비치면 계산대에서 산만하다.
            .offset(y: dragOffset)
            .opacity(1 - Double(min(dragOffset / 400, 0.5)))
        }
        .contentShape(Rectangle())
        .gesture(dismissDrag)
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

    /// 엑스 버튼은 그대로 두고, 아래로 쓸어내리는 길을 하나 더 낸다.
    /// 위로는 끌리지 않는다 — 닫는 방향이 하나여야 헷갈리지 않는다.
    private var dismissDrag: some Gesture {
        DragGesture(minimumDistance: 12)
            .onChanged { value in
                dragOffset = max(0, value.translation.height)
            }
            .onEnded { value in
                let travel = value.translation.height + value.predictedEndTranslation.height * 0.3
                if travel > 140 {
                    dismiss()
                } else {
                    withAnimation(.snappy(duration: 0.28)) { dragOffset = 0 }
                }
            }
    }
}
