import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var store: WalletStore
    @EnvironmentObject private var router: AppRouter
    @EnvironmentObject private var pendingRoute: PendingRoute

    /// 지금 맨 앞에 있는 카드. 끝없이 커지거나 작아지는 값이고, 실제 카드는 나머지 연산으로 고른다.
    /// 그래서 3장이면 1 → 2 → 3 → 1 로 끝없이 돈다.
    @State private var focused = 0
    @GestureState private var dragAmount: CGFloat = 0

    init() {}

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                if store.orderedItems.isEmpty {
                    EmptyStateView { router.isAddingItem = true }
                } else {
                    cardStack
                }
            }
            .toolbar { toolbar }
            .toolbarBackground(.hidden, for: .navigationBar)
            .overlay(alignment: .top) { newDayBanner }
            .animation(.snappy, value: store.newDayStreak)
        }
        // 시리·단축어·제어 센터로 들어온 요청은 화면이 뜬 뒤에 집어간다.
        .onAppear(perform: consumePendingRoute)
        .onChange(of: pendingRoute.pending) { _, _ in consumePendingRoute() }
        // 카드가 늘거나 줄면 자리 계산이 어긋난다. 맨 앞으로 되돌린다.
        .onChange(of: store.orderedItems.count) { _, _ in focused = 0 }
        .fullScreenCover(item: stagedItem) { item in
            BarcodeStageView(item: item)
        }
        .fullScreenCover(isPresented: $router.showsOnboarding) {
            OnboardingView()
        }
        .sheet(isPresented: $router.showsSettings) {
            SettingsView()
        }
        .sheet(isPresented: $router.showsRecord) {
            RecordView()
        }
        .sheet(isPresented: $router.isAddingItem) {
            ItemEditorView(item: nil)
        }
        .sheet(item: $router.editingItem) { item in
            ItemEditorView(item: item)
        }
    }

    /// 세로로 한 장씩. 아래로 밀면 다음 후보.
    /// 바코드가 떠 있는 동안에는 띄우지 않는다. 계산대 앞에서 방해가 된다.
    @ViewBuilder
    private var newDayBanner: some View {
        if router.stagedItemID == nil, let streak = store.newDayStreak {
            NewDayBanner(streak: streak) {
                store.newDayStreak = nil
                router.showsRecord = true
            }
            .transition(.move(edge: .top).combined(with: .opacity))
            .task(id: streak) {
                try? await Task.sleep(for: .seconds(3))
                store.newDayStreak = nil
            }
        }
    }

    /// 애플 월렛처럼 겹쳐 쌓는다. 위아래로 밀면 다음 카드가 올라오고, 끝에서 처음으로 이어진다.
    ///
    /// 목록이 아니라 여전히 "한 장"이다 — 손이 닿는 것은 맨 앞 카드 하나이고,
    /// 뒤 카드는 더 있다는 사실만 알려주는 정도로만 드러난다.
    private var cardStack: some View {
        GeometryReader { proxy in
            let metrics = DeckMetrics(cardHeight: min(max(proxy.size.height * 0.62, 300), 560))
            let progress = max(-1, min(1, -dragAmount / metrics.advance))

            ZStack(alignment: .bottom) {
                ForEach(visibleSlots, id: \.self) { slot in
                    card(at: slot, progress: progress, metrics: metrics)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
            .padding(.horizontal, 16)
            .padding(.bottom, 40)
            .contentShape(Rectangle())
            .gesture(deckDrag(metrics: metrics))
        }
        .overlay(alignment: .bottom) {
            if store.orderedItems.count > 1 {
                Label("위아래로 밀면 다음 카드", systemImage: "chevron.up.chevron.down")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.white.opacity(0.45))
                    .padding(.bottom, 6)
                    .allowsHitTesting(false)
            }
        }
    }

    @ViewBuilder
    private func card(at slot: Int, progress: CGFloat, metrics: DeckMetrics) -> some View {
        let item = item(at: focused + slot)
        let place = metrics.place(CGFloat(slot) - progress)

        ItemCardView(item: item) {
            if slot == 0 {
                router.activate(item, store: store)
            } else {
                // 뒤에 있는 카드를 누르면 앞으로 데려온다. 월렛과 같은 감각.
                withAnimation(.snappy(duration: 0.3)) { focused += slot }
            }
        }
        .frame(height: metrics.cardHeight)
        .scaleEffect(place.scale, anchor: .bottom)
        .offset(y: place.y)
        .opacity(place.opacity)
        .zIndex(-Double(slot) + Double(progress))
        .allowsHitTesting(place.opacity > 0.6)
        .contextMenu {
            Button("수정", systemImage: "pencil") { router.editingItem = item }
            Button("삭제", systemImage: "trash", role: .destructive) { store.delete(id: item.id) }
        }
    }

    private func deckDrag(metrics: DeckMetrics) -> some Gesture {
        DragGesture(minimumDistance: 8)
            .updating($dragAmount) { value, state, _ in
                state = value.translation.height
            }
            .onEnded { value in
                guard store.orderedItems.count > 1 else { return }
                // 빠르게 튕기면 짧게 밀어도 넘어간다.
                let travel = value.translation.height + value.predictedEndTranslation.height * 0.3
                guard abs(travel) > metrics.advance * 0.45 else { return }
                withAnimation(.snappy(duration: 0.32)) {
                    focused += travel < 0 ? 1 : -1
                }
            }
    }

    /// 그릴 자리들. -1은 위로 빠져나가는 카드 자리다.
    private var visibleSlots: [Int] {
        let count = store.orderedItems.count
        guard count > 1 else { return [0] }
        return Array(-1...min(3, count - 1))
    }

    /// 끝에서 처음으로 이어지도록 나머지 연산으로 고른다.
    private func item(at index: Int) -> WalletItem {
        let items = store.orderedItems
        let count = items.count
        return items[((index % count) + count) % count]
    }

    @ToolbarContentBuilder
    private var toolbar: some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            Button {
                router.showsRecord = true
            } label: {
                Text(homeTitle)
                    .font(.headline)
                    .foregroundStyle(.white.opacity(0.7))
            }
        }
        ToolbarItemGroup(placement: .topBarTrailing) {
            Button("추가", systemImage: "plus") { router.isAddingItem = true }
            Button("설정", systemImage: "gearshape") { router.showsSettings = true }
        }
    }

    /// 기록이 쌓이면 제목 자리가 프레임을 대신 말해준다 — 사고가 아니라 선택이었다고.
    private var homeTitle: String {
        let streak = store.currentStreak
        return streak > 0 ? "지갑 없이 \(streak)일째" : "지갑 없는 날"
    }

    private func consumePendingRoute() {
        guard let request = pendingRoute.take() else { return }
        router.open(request, store: store)
    }

    /// 딥링크로 들어온 항목을 fullScreenCover에 물려주기 위한 바인딩.
    private var stagedItem: Binding<WalletItem?> {
        Binding(
            get: { router.stagedItemID.flatMap(store.item(id:)) },
            set: { if $0 == nil { router.stagedItemID = nil } }
        )
    }
}

/// 카드 더미의 배치 계산.
///
/// p는 카드의 연속적인 자리다. 0이 맨 앞, 1·2·3은 뒤로 갈수록,
/// 음수는 위로 빠져나가는 중이라는 뜻이다. 드래그하면 p가 연속으로 움직인다.
private struct DeckMetrics {
    let cardHeight: CGFloat

    /// 뒤 카드가 위로 얼마나 고개를 내미는지
    var peek: CGFloat { 34 }
    /// 한 장 넘기는 데 필요한 드래그 거리
    var advance: CGFloat { max(120, cardHeight * 0.3) }

    func place(_ p: CGFloat) -> (y: CGFloat, scale: CGFloat, opacity: Double) {
        if p < 0 {
            // 위로 빠져나가며 사라진다
            let t = min(-p, 1)
            return (y: -t * cardHeight * 0.92, scale: 1, opacity: Double(1 - t))
        }
        let depth = min(p, 3)
        // 뒤로 갈수록 간격이 좁아지게. 일정 간격이면 계단처럼 보인다.
        let y = -peek * CGFloat(pow(Double(depth), 0.8))
        let scale = 1 - 0.045 * depth
        let opacity = p > 2.4 ? Double(max(0, 1 - (p - 2.4) / 0.6)) : 1
        return (y: y, scale: scale, opacity: opacity)
    }
}

private struct NewDayBanner: View {
    let streak: Int
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: "checkmark.seal.fill")
                Text("오늘도 지갑 없이 — \(streak)일째")
                    .font(.subheadline.weight(.semibold))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(.thinMaterial, in: Capsule())
        }
        .buttonStyle(.plain)
    }
}

private struct EmptyStateView: View {
    let onAdd: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "barcode.viewfinder")
                .font(.system(size: 56))
                .foregroundStyle(.white.opacity(0.6))
            Text("아직 등록된 카드가 없어요")
                .font(.title3.weight(.semibold))
                .foregroundStyle(.white)
            Text("멤버십 바코드 하나만 넣어두면\n지갑 없이 나가도 됩니다")
                .multilineTextAlignment(.center)
                .foregroundStyle(.white.opacity(0.6))
            Button("카드 추가", action: onAdd)
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .padding(.top, 8)
        }
        .padding(32)
    }
}
