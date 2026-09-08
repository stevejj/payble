import WidgetKit
import SwiftUI

@main
struct WalletlessWidgetBundle: WidgetBundle {
    var body: some Widget {
        QuickAccessWidget()
        LockScreenWidget()
    }
}
