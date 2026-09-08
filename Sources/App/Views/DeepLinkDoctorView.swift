import SwiftUI
import UIKit

/// 페이 앱 URL scheme은 공식 문서가 없고 앱 업데이트로 조용히 바뀐다.
/// 그래서 추측하지 않고 기기에서 직접 확인한다. 여기서 초록불이 켜진 것만 실제로 열린다.
///
/// 다만 초록불은 "이 scheme에 응답하는 앱이 있다"까지만 말해준다.
/// 어디로 열리는지는 눌러봐야 안다 — 결제 화면일 수도, 앱 홈일 수도, 에러일 수도 있다.
/// 그래서 후보를 하나씩 눌러볼 수 있게 열어둔다.
struct DeepLinkDoctorView: View {
    @State private var openable: Set<String> = []
    @State private var checked = false

    init() {}

    var body: some View {
        List {
            ForEach(PayAppCatalog.all) { app in
                Section {
                    ForEach(app.schemeCandidates, id: \.self) { candidate in
                        candidateRow(candidate, isChosen: chosen(for: app) == candidate)
                    }
                } header: {
                    Text(app.name)
                } footer: {
                    footer(for: app)
                }
            }

            Section {
                Text("초록불은 이 scheme에 응답하는 앱이 있다는 뜻까지입니다. 어디로 열리는지는 눌러서 직접 확인해야 합니다 — 결제 화면일 수도, 앱 홈일 수도, 경로 오류일 수도 있습니다.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("딥링크 진단")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear(perform: check)
        .refreshable { check() }
    }

    private func candidateRow(_ candidate: String, isChosen: Bool) -> some View {
        Button {
            guard let url = URL(string: candidate) else { return }
            UIApplication.shared.open(url)
        } label: {
            HStack(spacing: 10) {
                Text(candidate)
                    .font(.system(.subheadline, design: .monospaced))
                    .foregroundStyle(openable.contains(candidate) ? .primary : .secondary)
                if isChosen {
                    Text("사용 중")
                        .font(.caption2.weight(.semibold))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(.tint.opacity(0.15), in: Capsule())
                }
                Spacer()
                if openable.contains(candidate) {
                    Image(systemName: "arrow.up.forward.app")
                        .foregroundStyle(.secondary)
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                } else if checked {
                    Image(systemName: "xmark.circle")
                        .foregroundStyle(.tertiary)
                }
            }
        }
        .disabled(!openable.contains(candidate))
    }

    @ViewBuilder
    private func footer(for app: PayApp) -> some View {
        if checked && chosen(for: app) == nil {
            Text("설치되어 있지 않거나 후보 scheme이 전부 바뀌었어요.")
        } else if openable.contains(where: app.schemeCandidates.contains) {
            Text("초록불이 켜진 줄을 눌러 실제로 어디로 열리는지 확인해보세요.")
        }
    }

    /// 실제로 쓰이는 것은 열리는 후보 중 첫 번째. 앱이 카드를 열 때와 같은 규칙이다.
    private func chosen(for app: PayApp) -> String? {
        app.schemeCandidates.first { openable.contains($0) }
    }

    private func check() {
        var found: Set<String> = []
        for app in PayAppCatalog.all {
            for candidate in app.schemeCandidates {
                guard let url = URL(string: candidate) else { continue }
                if UIApplication.shared.canOpenURL(url) { found.insert(candidate) }
            }
            ResolvedScheme.set(app.schemeCandidates.first { found.contains($0) }, for: app.id)
        }
        openable = found
        checked = true
    }
}
