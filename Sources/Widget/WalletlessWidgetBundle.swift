import SwiftUI
import WidgetKit

@main
struct WalletlessWidgetBundle: WidgetBundle {
    var body: some Widget {
        QuickAccessWidget()
        LockScreenWidget()
        if #available(iOS 18.0, *) {
            QuickBarcodeControl()
        }
    }
}
