import SwiftUI

/// 1차의 유일한 정렬 수단. 자동 판단 대신 사용자가 직접 맨 앞을 정한다.
struct ReorderView: View {
    @EnvironmentObject private var store: WalletStore

    init() {}

    var body: some View {
        List {
            Section {
                ForEach(store.orderedItems) { item in
                    HStack(spacing: 12) {
                        Circle().fill(Color(hex: item.tintHex)).frame(width: 10, height: 10)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(item.name)
                            Text(item.subtitle)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        if item.usageCount > 0 {
                            Text("\(item.usageCount)회")
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                        }
                    }
                }
                .onMove { store.move(fromOffsets: $0, toOffset: $1) }
                .onDelete { offsets in
                    for index in offsets { store.delete(id: store.orderedItems[index].id) }
                }
            } footer: {
                Text("맨 위 카드가 앱을 열자마자 보이는 카드예요.")
            }
        }
        .environment(\.editMode, .constant(.active))
        .navigationTitle("순서 정하기")
        .navigationBarTitleDisplayMode(.inline)
    }
}
