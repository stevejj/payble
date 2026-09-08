import SwiftUI

/// 이탈이 가장 많은 구간. 3단계 안에 끝나고, 전부 건너뛸 수 있어야 한다.
struct OnboardingView: View {
    @EnvironmentObject private var store: WalletStore
    @EnvironmentObject private var router: AppRouter

    @State private var step = 0
    @State private var selectedPlaces: [PlaceCategory] = []
    @State private var selectedApps: Set<String> = []
    @State private var pendingCard: PendingCard?

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
        .sheet(item: $pendingCard) { card in
            ItemEditorView(
                item: nil,
                initialName: card.name,
                initialPlaces: card.places,
                autoScan: true
            )
        }
    }

    private var placeStep: some View {
        OnboardingStep(
            title: "어디에 자주 가세요?",
            subtitle: "고른 곳이 카드에 그대로 적혀서, 나중에 언제 꺼내야 할지 헷갈리지 않습니다"
        ) {
            ChipGrid(
                items: PlaceCategory.allCases.map(\.chip),
                isSelected: { chip in
                    PlaceCategory.from(chip: chip).map(selectedPlaces.contains) ?? false
                },
                onTap: { chip in
                    guard let place = PlaceCategory.from(chip: chip) else { return }
                    if let index = selectedPlaces.firstIndex(of: place) {
                        selectedPlaces.remove(at: index)
                    } else {
                        selectedPlaces.append(place)
                    }
                }
            )
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
                ChipGrid(
                    items: suggestions.map { ChipItem(id: $0.rawValue, title: $0.suggestedCardName) },
                    isSelected: { _ in false },
                    onTap: { chip in
                        guard let place = PlaceCategory(rawValue: chip.id) else { return }
                        pendingCard = PendingCard(name: place.suggestedCardName, places: [place])
                    }
                )
                Button {
                    pendingCard = PendingCard(name: "", places: [])
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

    /// 1단계에서 고른 곳이 있으면 그것만, 없으면 흔한 것 몇 개.
    private var suggestions: [PlaceCategory] {
        selectedPlaces.isEmpty ? [.convenience, .cafe, .mart] : selectedPlaces
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

/// sheet(item:)에 물리기 위한 얇은 래퍼.
private struct PendingCard: Identifiable {
    let id = UUID()
    let name: String
    let places: [PlaceCategory]
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
