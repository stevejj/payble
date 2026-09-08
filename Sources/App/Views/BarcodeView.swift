import SwiftUI

/// 바코드 그림 한 장. 보간을 끄지 않으면 막대 경계가 뭉개져 스캐너가 못 읽는다.
struct BarcodeView: View {
    let barcode: Barcode
    var height: CGFloat = 120

    var body: some View {
        if let image = BarcodeImageRenderer.image(for: barcode) {
            Image(decorative: image, scale: 1)
                .resizable()
                .interpolation(.none)
                .modifier(BarcodeShape(isSquare: barcode.symbology.isSquare, height: height))
        } else {
            VStack(spacing: 6) {
                Image(systemName: "exclamationmark.triangle")
                Text("바코드를 만들 수 없는 값이에요")
                    .font(.footnote)
            }
            .foregroundStyle(.secondary)
            .frame(height: height)
        }
    }
}

private struct BarcodeShape: ViewModifier {
    let isSquare: Bool
    let height: CGFloat

    func body(content: Content) -> some View {
        if isSquare {
            content.aspectRatio(1, contentMode: .fit)
        } else {
            content.frame(maxWidth: .infinity).frame(height: height)
        }
    }
}
