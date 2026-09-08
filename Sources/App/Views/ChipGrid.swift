import SwiftUI

/// 여러 개를 눌러 고르는 칩 묶음. 온보딩과 카드 편집에서 같은 것을 쓴다.
struct ChipGrid: View {
    let items: [ChipItem]
    let isSelected: (ChipItem) -> Bool
    let onTap: (ChipItem) -> Void

    init(
        items: [ChipItem],
        isSelected: @escaping (ChipItem) -> Bool,
        onTap: @escaping (ChipItem) -> Void
    ) {
        self.items = items
        self.isSelected = isSelected
        self.onTap = onTap
    }

    private var columns: [GridItem] {
        [GridItem(.adaptive(minimum: 96), spacing: 8)]
    }

    var body: some View {
        LazyVGrid(columns: columns, alignment: .leading, spacing: 8) {
            ForEach(items) { item in
                // 배경까지 탭 영역에 들어오도록 label 안에서 꾸민다.
                Button {
                    onTap(item)
                } label: {
                    Text(item.title)
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
