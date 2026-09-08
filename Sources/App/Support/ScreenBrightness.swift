import SwiftUI
import UIKit

/// 바코드를 띄우는 동안 화면을 최대 밝기로. 매장 스캐너가 못 읽는 가장 흔한 이유가 어두운 화면이다.
@MainActor
final class ScreenBrightness {
    static let shared = ScreenBrightness()

    private var saved: CGFloat?

    private var screen: UIScreen? {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first { $0.activationState == .foregroundActive }?
            .screen
    }

    func boost() {
        guard let screen else { return }
        if saved == nil { saved = screen.brightness }
        screen.brightness = 1.0
        UIApplication.shared.isIdleTimerDisabled = true
    }

    func restore() {
        if let saved, let screen { screen.brightness = saved }
        saved = nil
        UIApplication.shared.isIdleTimerDisabled = false
    }
}

private struct MaxBrightnessModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .onAppear { ScreenBrightness.shared.boost() }
            .onDisappear { ScreenBrightness.shared.restore() }
    }
}

extension View {
    /// 이 화면이 보이는 동안만 밝기를 올리고, 사라지면 원래대로 돌려놓는다.
    func maxBrightnessWhileVisible() -> some View {
        modifier(MaxBrightnessModifier())
    }
}
