import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var store: WalletStore
    @EnvironmentObject private var router: AppRouter

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
        }
        .fullScreenCover(item: stagedItem) { item in
            BarcodeStageView(item: item)
        }
        .fullScreenCover(isPresented: $router.showsOnboarding) {
            OnboardingView()
        }
        .sheet(isPresented: $router.showsSettings) {
            SettingsView()
        }
        .sheet(isPresented: $router.isAddingItem) {
            ItemEditorView(item: nil)
        }
        .sheet(item: $router.editingItem) { item in
            ItemEditorView(item: item)
        }
    }

    /// 세로로 한 장씩. 아래로 밀면 다음 후보.
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
            Text("지갑 없는 날")
                .font(.headline)
                .foregroundStyle(.white.opacity(0.7))
        }
        ToolbarItemGroup(placement: .topBarTrailing) {
            Button("추가", systemImage: "plus") { router.isAddingItem = true }
            Button("설정", systemImage: "gearshape") { router.showsSettings = true }
        }
    }

    /// 딥링크로 들어온 항목을 fullScreenCover에 물려주기 위한 바인딩.
    private var stagedItem: Binding<WalletItem?> {
        Binding(
            get: { router.stagedItemID.flatMap(store.item(id:)) },
            set: { if $0 == nil { router.stagedItemID = nil } }
        )
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
