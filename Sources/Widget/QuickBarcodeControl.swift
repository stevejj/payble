import AppIntents
import SwiftUI
import WidgetKit

/// 제어 센터 버튼. 잠금 상태에서 위에서 아래로 쓸어내려 바로 누를 수 있다.
///
/// 어떤 카드인지는 앱이 열리면서 스스로 고른다(맨 앞 카드).
/// 덕분에 이 컨트롤은 앱 데이터를 읽을 필요가 없어 App Group 없이도 동작한다.
@available(iOS 18.0, *)
struct QuickBarcodeControl: ControlWidget {
    var body: some ControlWidgetConfiguration {
        StaticControlConfiguration(kind: "QuickBarcodeControl") {
            ControlWidgetButton(action: OpenURLIntent(DeepLink.topBarcode(from: .control))) {
                Label("바코드", systemImage: "barcode")
            }
        }
        .displayName("바코드 열기")
        .description("맨 앞 카드의 바코드를 전체화면으로 엽니다.")
    }
}
