import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var store: WalletStore
    @EnvironmentObject private var router: AppRouter
    @EnvironmentObject private var metrics: SpeedMetrics
    @Environment(\.dismiss) private var dismiss

    init() {}

    var body: some View {
        NavigationStack {
            List {
                speedSection

                Section {
                    NavigationLink("순서 정하기") { ReorderView() }
                    NavigationLink("딥링크 진단") { DeepLinkDoctorView() }
                }

                Section {
                    Text("홈 화면을 길게 눌러 위젯을 추가하면 탭 한 번에 바코드까지 갑니다. 잠금화면 위젯도 같은 경로예요.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                } header: {
                    Text("위젯")
                }

                if !WalletStorage.isSharedContainerAvailable {
                    Section {
                        Label(
                            "App Group이 설정되지 않아 위젯이 카드를 읽지 못합니다. AppGroup.identifier와 entitlements를 확인하세요.",
                            systemImage: "exclamationmark.triangle.fill"
                        )
                        .font(.footnote)
                        .foregroundStyle(.orange)
                    }
                }

                Section {
                    Button("온보딩 다시 보기") {
                        dismiss()
                        router.resetOnboarding()
                    }
                    Button("속도 기록 지우기", role: .destructive) { metrics.reset() }
                } footer: {
                    Text("카드와 바코드는 이 기기에만 저장됩니다. 계정도 서버도 없습니다.")
                }
            }
            .navigationTitle("설정")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("완료") { dismiss() }
                }
            }
        }
    }

    /// 이 앱이 답해야 하는 단 하나의 질문에 대한 답.
    private var speedSection: some View {
        Section {
            if let median = metrics.medianSeconds {
                LabeledContent("실행 → 바코드 (중앙값)", value: String(format: "%.1f초", median))
            }
            if let taps = metrics.averageTaps {
                LabeledContent("평균 탭 횟수", value: String(format: "%.1f회", taps))
                if taps > 2 {
                    Label("탭이 2회를 넘으면 사용자는 원래 쓰던 앱을 켭니다", systemImage: "exclamationmark.triangle")
                        .font(.footnote)
                        .foregroundStyle(.orange)
                }
            }
            ForEach([DeepLink.Source.app, .widget, .lockScreen], id: \.rawValue) { entry in
                if let median = metrics.medianSeconds(for: entry) {
                    LabeledContent(entry.label) {
                        Text(String(format: "%.1f초 · %d회", median, metrics.count(for: entry)))
                            .foregroundStyle(.secondary)
                    }
                }
            }
            if metrics.records.isEmpty {
                Text("아직 기록이 없어요. 바코드를 한 번 꺼내보세요.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        } header: {
            Text("속도")
        } footer: {
            Text("1차 버전의 목표는 매출도 사용자 수도 아니라, 이 숫자가 카카오페이를 켜는 것보다 작은지입니다.")
        }
    }
}
