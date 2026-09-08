import SwiftUI

@main
struct WalletlessApp: App {
    @StateObject private var store = WalletStore()
    @StateObject private var router = AppRouter()
    @StateObject private var metrics = SpeedMetrics.shared
    @StateObject private var pendingRoute = PendingRoute.shared
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            HomeView()
                .environmentObject(store)
                .environmentObject(router)
                .environmentObject(metrics)
                .environmentObject(pendingRoute)
                .onOpenURL { router.handle($0, store: store) }
                .preferredColorScheme(.dark)
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { SpeedMetrics.shared.beginSession() }
        }
    }
}
