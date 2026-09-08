import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var store: WalletStore
    @EnvironmentObject private var router: AppRouter
    @EnvironmentObject private var pendingRoute: PendingRoute

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

    private var cardStack: some View {
        ScrollView(.vertical) {
            LazyVStack(spacing: 0) {
                ForEach(store.orderedItems) { item in
                    ItemCardView(item: item) { router.activate(item, store: store) }
                        // 카드 사이 여백은 프레임 안쪽에서 준다. 밖에서 주면 페이징 위치가 어긋난다.
                        .padding(.vertical, 8)
                        .containerRelativeFrame(.vertical, count: 1, spacing: 0)
                        .contextMenu {
                            Button("수정", systemImage: "pencil") { router.editingItem = item }
                            Button("삭제", systemImage: "trash", role: .destructive) {
                                store.delete(id: item.id)
                            }
                        }
                }
            }
            .scrollTargetLayout()
            .padding(.horizontal, 16)
        }
        .scrollTargetBehavior(.paging)
        .scrollIndicators(.hidden)
        .overlay(alignment: .bottom) {
            if store.orderedItems.count > 1 {
                Label("아래로 밀면 다음", systemImage: "chevron.down")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.white.opacity(0.5))
                    .padding(.bottom, 4)
                    .allowsHitTesting(false)
            }
        }
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
