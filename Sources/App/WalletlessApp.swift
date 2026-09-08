import SwiftUI

@main
struct WalletlessApp: App {
    @StateObject private var store = WalletStore()
    @StateObject private var router = AppRouter()
    @StateObject private var metrics = SpeedMetrics.shared
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            HomeView()
                .environmentObject(store)
                .environmentObject(router)
                .environmentObject(metrics)
                .onOpenURL { router.handle($0) }
                .preferredColorScheme(.dark)
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { SpeedMetrics.shared.beginSession() }
        }
    }
}
