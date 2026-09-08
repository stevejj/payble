import SwiftUI

/// 이탈이 가장 많은 구간. 3단계 안에 끝나고, 전부 건너뛸 수 있어야 한다.
struct OnboardingView: View {
    @EnvironmentObject private var store: WalletStore
    @EnvironmentObject private var router: AppRouter

    @State private var step = 0
    @State private var selectedPlaces: Set<PlaceType> = []
    @State private var selectedApps: Set<String> = []
    @State private var pendingName: PendingName?

    init() {}

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                TabView(selection: $step) {
                    placeStep.tag(0)
                    payAppStep.tag(1)
                    barcodeStep.tag(2)
                }
                .tabViewStyle(.page(indexDisplayMode: .always))

                Button(action: advance) {
                    Text(step == 2 ? "시작하기" : "다음")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .padding(20)
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("건너뛰기") { finish() }
                }
            }
        }
        .sheet(item: $pendingName) { name in
            ItemEditorView(item: nil, initialName: name.value, autoScan: true)
        }
    }

    private var placeStep: some View {
        OnboardingStep(
            title: "어디에 자주 가세요?",
            subtitle: "고른 곳에 맞춰 등록할 카드를 추천해드려요"
        ) {
            FlowChips(items: PlaceType.allCases.map(\.title)) { title in
                guard let place = PlaceType.allCases.first(where: { $0.title == title }) else { return false }
                return selectedPlaces.contains(place)
            } onTap: { title in
                guard let place = PlaceType.allCases.first(where: { $0.title == title }) else { return }
                if selectedPlaces.contains(place) {
                    selectedPlaces.remove(place)
                } else {
                    selectedPlaces.insert(place)
                }
            }
        }
    }

    private var payAppStep: some View {
        OnboardingStep(
            title: "어떤 페이 앱을 쓰세요?",
            subtitle: "결제 화면까지 한 번에 넘어가는 바로가기를 만들어요"
        ) {
            VStack(spacing: 10) {
                ForEach(PayAppCatalog.all) { app in
                    Button {
                        if selectedApps.contains(app.id) {
                            selectedApps.remove(app.id)
                        } else {
                            selectedApps.insert(app.id)
                        }
                    } label: {
                        HStack {
                            Circle().fill(Color(hex: app.tintHex)).frame(width: 12, height: 12)
                            Text(app.name)
                            Spacer()
                            Image(systemName: selectedApps.contains(app.id) ? "checkmark.circle.fill" : "circle")
                                .foregroundStyle(selectedApps.contains(app.id) ? Color.accentColor : .secondary)
                        }
                        .padding()
                        .background(.quaternary.opacity(0.5), in: RoundedRectangle(cornerRadius: 12))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var barcodeStep: some View {
        OnboardingStep(
            title: "멤버십 바코드를 하나만 넣어볼까요?",
            subtitle: "카드 뒷면을 카메라로 비추면 끝이에요"
        ) {
            VStack(spacing: 12) {
                FlowChips(items: suggestedNames) { _ in false } onTap: { name in
                    pendingName = PendingName(value: name)
                }
                Button {
                    pendingName = PendingName(value: "")
                } label: {
                    Label("직접 등록하기", systemImage: "barcode.viewfinder")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
                .padding(.top, 8)
            }
        }
    }

    private var suggestedNames: [String] {
        let places = selectedPlaces.isEmpty ? Set(PlaceType.allCases) : selectedPlaces
        return PlaceType.allCases.filter(places.contains).flatMap(\.suggestions)
    }

    private func advance() {
        if step < 2 {
            step += 1
        } else {
            finish()
        }
    }

    private func finish() {
        for id in selectedApps {
            guard let app = PayAppCatalog.app(id: id) else { continue }
            let alreadyAdded = store.items.contains { $0.payAppID == id }
            guard !alreadyAdded else { continue }
            store.upsert(WalletItem(kind: .payApp, name: app.name, payAppID: id, tintHex: app.tintHex))
        }
        router.finishOnboarding()
    }
}

/// sheet(item:)에 문자열을 물리기 위한 얇은 래퍼.
private struct PendingName: Identifiable {
    let value: String
    var id: String { value }
}

private struct OnboardingStep<Content: View>: View {
    let title: String
    let subtitle: String
    @ViewBuilder var content: Content

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                Text(title)
                    .font(.title.bold())
                Text(subtitle)
                    .foregroundStyle(.secondary)
                content
                    .padding(.top, 12)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(24)
        }
    }
}

private struct FlowChips: View {
    let items: [String]
    let isSelected: (String) -> Bool
    let onTap: (String) -> Void

    private let columns = [GridItem(.adaptive(minimum: 100), spacing: 8)]

    var body: some View {
        LazyVGrid(columns: columns, alignment: .leading, spacing: 8) {
            ForEach(items, id: \.self) { item in
                // 배경까지 탭 영역에 들어오도록 label 안에서 꾸민다.
                Button {
                    onTap(item)
                } label: {
                    Text(item)
                        .font(.subheadline.weight(.medium))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .frame(maxWidth: .infinity)
                        .background(
                            isSelected(item) ? Color.accentColor.opacity(0.2) : Color.secondary.opacity(0.12),
                            in: Capsule()
                        )
                        .contentShape(Capsule())
                }
                .buttonStyle(.plain)
            }
        }
    }
}

enum PlaceType: String, CaseIterable, Identifiable {
    case convenience, cafe, mart, transit, walk

    var id: String { rawValue }

    var title: String {
        switch self {
        case .convenience: return "편의점"
        case .cafe: return "카페"
        case .mart: return "마트"
        case .transit: return "대중교통"
        case .walk: return "러닝 · 산책"
        }
    }

    /// 카드 이름 추천. 정확한 브랜드 목록이 아니라 입력을 줄여주는 힌트일 뿐이다.
    var suggestions: [String] {
        switch self {
        case .convenience: return ["편의점 멤버십"]
        case .cafe: return ["카페 적립"]
        case .mart: return ["마트 포인트"]
        case .transit: return ["교통 관련"]
        case .walk: return ["동네 적립"]
        }
    }
}
