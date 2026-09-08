import SwiftUI

/// 1차의 유일한 정렬 수단. 자동 판단 대신 사용자가 직접 맨 앞을 정한다.
struct ReorderView: View {
    @EnvironmentObject private var store: WalletStore
    @State private var groupByPlace = PlaceGrouping.isEnabled

    init() {}

    var body: some View {
        List {
            Section {
                Toggle("같은 장소끼리 모으기", isOn: $groupByPlace)
                    .onChange(of: groupByPlace) { _, enabled in
                        store.setPlaceGrouping(enabled)
                    }
            } footer: {
                Text(groupByPlace
                     ? "편의점 카드끼리, 카페 카드끼리 붙어서 나옵니다. 계산대 앞에서 아래로 한 번만 밀면 다음 후보가 나오도록. 맨 위 카드는 바뀌지 않고, 다른 묶음으로 끌어다 놓으면 제자리로 돌아옵니다."
                     : "손으로 정한 순서를 그대로 씁니다.")
            }

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
                Text("맨 위 카드가 앱을 열자마자 보이는 카드이고, 뒷면 탭·시리·제어 센터가 여는 카드입니다.")
            }
        }
        .environment(\.editMode, .constant(.active))
        .navigationTitle("순서 정하기")
        .navigationBarTitleDisplayMode(.inline)
    }
}
