import SwiftUI
import UIKit

/// 페이 앱 URL scheme은 공식 문서가 없고 앱 업데이트로 조용히 바뀐다.
/// 그래서 추측하지 않고 기기에서 직접 확인한다. 여기서 초록불이 켜진 것만 실제로 열린다.
struct DeepLinkDoctorView: View {
    @State private var results: [String: String?] = [:]

    init() {}

    var body: some View {
        List {
            ForEach(PayAppCatalog.all) { app in
                Section {
                    ForEach(app.schemeCandidates, id: \.self) { candidate in
                        HStack {
                            Text(candidate)
                                .font(.system(.subheadline, design: .monospaced))
                            Spacer()
                            if let resolved = results[app.id], resolved == candidate {
                                Label("열림", systemImage: "checkmark.circle.fill")
                                    .labelStyle(.iconOnly)
                                    .foregroundStyle(.green)
                            }
                        }
                    }
                    if let resolved = results[app.id] {
                        if resolved == nil {
                            Label("설치되어 있지 않거나 scheme이 바뀌었어요", systemImage: "xmark.circle")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }
                    }
                } header: {
                    Text(app.name)
                }
            }
        }
        .navigationTitle("딥링크 진단")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear(perform: check)
        .refreshable { check() }
    }

    private func check() {
        var next: [String: String?] = [:]
        for app in PayAppCatalog.all {
            let found = PayAppLauncher.installedScheme(for: app)
            next[app.id] = found
            ResolvedScheme.set(found, for: app.id)
        }
        results = next
    }
}
