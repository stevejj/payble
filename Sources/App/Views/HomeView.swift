import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var store: WalletStore
    @EnvironmentObject private var router: AppRouter
    @EnvironmentObject private var pendingRoute: PendingRoute

    /// 지금 맨 앞에 있는 카드. 끝없이 커지거나 작아지는 값이고, 실제 카드는 나머지 연산으로 고른다.
    /// 그래서 3장이면 1 → 2 → 3 → 1 로 끝없이 돈다.
    @State private var focused = 0
    /// 손가락이 화면에 있는 동안만 참. 카드 위치에는 관여하지 않고 안내만 밝힌다.
    @GestureState private var isSwiping = false

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
            let metrics = DeckMetrics(cardHeight: min(max(proxy.size.height * 0.72, 320), 620))

            ZStack(alignment: .bottom) {
                ForEach(visibleIndices, id: \.self) { index in
                    card(index: index, metrics: metrics)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
            .padding(.horizontal, 12)
            .padding(.bottom, 34)
            .contentShape(Rectangle())
            // 카드가 버튼이라 그냥 gesture로 붙이면 카드 위에서는 쓸기가 먹지 않는다.
            // 우선권을 줘서 화면 어디서 시작하든 넘어간다. 손가락이 20pt를 못 넘기면
            // 쓸기가 성립하지 않아 카드 탭은 그대로 살아 있다.
            .highPriorityGesture(deckSwipe)
        }
        .overlay(alignment: .bottom) { dragHint }
        // 넘어간 순간을 손끝으로도 알려준다. 화면을 안 보고도 몇 장 넘겼는지 센다.
        .sensoryFeedback(.impact(weight: .light), trigger: focused)
    }

    /// 끌고 있는 동안 안내가 또렷해진다 — 지금 반응하고 있다는 신호.
    @ViewBuilder
    private var dragHint: some View {
        if canAdvance {
            Label("아래/위로 밀면 다음 카드", systemImage: "chevron.up.chevron.down")
                .font(.caption.weight(.medium))
                .foregroundStyle(.white.opacity(isSwiping ? 0.9 : 0.45))
                .scaleEffect(isSwiping ? 1.08 : 1)
                .padding(.bottom, 6)
                .allowsHitTesting(false)
                .animation(.easeOut(duration: 0.18), value: isSwiping)
        }
    }

    private var canAdvance: Bool { store.orderedItems.count > 1 }

    @ViewBuilder
    private func card(index: Int, metrics: DeckMetrics) -> some View {
        let slot = index - focused
        let item = item(at: index)
        let place = metrics.place(CGFloat(slot))

        ItemCardView(item: item) {
            if slot == 0 {
                router.activate(item, store: store)
            } else {
                // 뒤에 있는 카드를 누르면 앞으로 데려온다. 월렛과 같은 감각.
                withAnimation(.snappy(duration: DeckMetrics.settle)) { focused += slot }
            }
        }
        .frame(height: metrics.cardHeight)
        .overlay {
            // 뒤 카드에 드리우는 그늘. 카드 모서리를 그대로 따라간다.
            RoundedRectangle(cornerRadius: 32, style: .continuous)
                .fill(.black.opacity(place.dim))
                .allowsHitTesting(false)
        }
        // 앞 카드가 뒤 카드 위에 그림자를 얹어 경계가 드러난다.
        .shadow(color: .black.opacity(0.55), radius: 14, x: 0, y: -6)
        .scaleEffect(place.scale, anchor: .bottom)
        .offset(y: place.y)
        .opacity(place.opacity)
        .zIndex(-Double(slot))
        .allowsHitTesting(place.opacity > 0.6)
        .contextMenu {
            Button("수정", systemImage: "pencil") { router.editingItem = item }
            Button("삭제", systemImage: "trash", role: .destructive) { store.delete(id: item.id) }
        }
    }

    /// 손가락은 **방향만** 알려준다. 카드를 끌고 다니지 않는다.
    ///
    /// 쓸기는 사람마다 빠르기도 길이도 제각각이라, 카드를 손가락에 물려두면
    /// 넘어가는 모습이 매번 달라진다. 어떤 번은 확 튀고 어떤 번은 굼뜬다.
    /// 그래서 손을 뗀 자리도 속도도 보지 않고, 방향만 읽어 **늘 같은 한 장면**을 재생한다.
    /// 30프레임과 60프레임을 섞어 보여줄 이유가 없는 것과 같다 — 가장 좋은 하나만 보여준다.
    private var deckSwipe: some Gesture {
        DragGesture(minimumDistance: 20)
            .updating($isSwiping) { _, state, _ in state = true }
            .onEnded { value in
                guard canAdvance else { return }
                // 빠르게 튕기면 짧게 밀어도 읽힌다.
                let travel = value.translation.height + value.predictedEndTranslation.height * 0.3
                guard abs(travel) > 44 else { return }
                withAnimation(.snappy(duration: DeckMetrics.settle)) {
                    focused += travel > 0 ? 1 : -1
                }
            }
    }

    /// 그릴 카드들. 자리 번호가 아니라 **카드의 절대 위치**로 센다.
    ///
    /// 자리 번호로 세면 넘길 때 같은 자리에 내용만 갈린다. 미리 보이던 다음 카드가
    /// 앞으로 걸어오는 게 아니라, 맨 앞자리가 다른 카드로 바뀐 뒤 화면 밖에서부터
    /// 다시 날아온다 — 그래서 한 번 넘기는데 두 번 움직이는 것처럼 보였다.
    /// 절대 위치로 세면 그 카드가 그대로 자리를 옮기므로 손을 뗀 자리에서 이어진다.
    private var visibleIndices: [Int] {
        let count = store.orderedItems.count
        guard count > 1 else { return [focused] }
        return Array((focused - 1)...(focused + min(3, count - 1)))
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

    /// 손을 뗀 자리와 상관없이 늘 같은 시간. 조금만 밀고 놓았을 때의 그 감각으로 고정한다.
    static let settle: Double = 0.30

    /// 뒤 카드가 위로 얼마나 고개를 내미는지
    var peek: CGFloat { 46 }

    func place(_ p: CGFloat) -> (y: CGFloat, scale: CGFloat, opacity: Double, dim: Double) {
        if p < 0 {
            // 앞 카드는 아래로 미끄러져 화면 밖으로 빠진다.
            // 뒤 카드는 전부 위쪽에 있으니 나가는 길에 가로지를 것이 없다 —
            // 겹쳐 비칠 일도, 화면을 가로질러 날아갈 일도 없다.
            // 크기와 투명도는 건드리지 않는다. 그냥 비켜줄 뿐이다.
            let t = min(-p, 1)
            return (y: t * (cardHeight + 80), scale: 1, opacity: 1, dim: 0)
        }
        let depth = min(p, 3)
        // 뒤로 갈수록 간격이 좁아지게. 일정 간격이면 계단처럼 보인다.
        let y = -peek * CGFloat(pow(Double(depth), 0.8))
        // 앞뒤 크기 차를 키워야 "뒤엣것이 앞으로 나온다"가 읽힌다.
        let scale = 1 - 0.07 * depth
        let opacity = p > 2.4 ? Double(max(0, 1 - (p - 2.4) / 0.6)) : 1
        // 뒤로 갈수록 그늘이 진다. 크기 차이만으로는 몇 장이 쌓였는지 읽히지 않는다.
        let dim = min(Double(depth) * 0.12, 0.34)
        return (y: y, scale: scale, opacity: opacity, dim: dim)
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
