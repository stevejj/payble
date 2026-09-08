import SwiftUI

/// 탭 0회 경로를 켜는 방법.
///
/// 앱이 App Intents로 "바코드 열기" 동작을 시스템에 등록해 두었기 때문에,
/// 사용자는 아래 어디에든 그 동작을 붙이기만 하면 된다.
struct QuickLaunchGuideView: View {
    init() {}

    var body: some View {
        List {
            Section {
                Text("이 앱은 \"바코드 열기\"를 시스템 동작으로 등록해 둡니다. 아래 방법 중 하나만 연결해두면 앱을 찾아 들어가는 과정 없이 바로 바코드가 열립니다.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            ForEach(QuickLaunchRecipe.all) { recipe in
                Section {
                    ForEach(Array(recipe.steps.enumerated()), id: \.offset) { index, step in
                        HStack(alignment: .top, spacing: 10) {
                            Text("\(index + 1)")
                                .font(.caption.monospacedDigit().weight(.bold))
                                .foregroundStyle(.secondary)
                                .frame(width: 16, alignment: .trailing)
                            Text(step)
                                .font(.subheadline)
                        }
                    }
                } header: {
                    Label(recipe.title, systemImage: recipe.systemImage)
                } footer: {
                    Text(recipe.note)
                }
            }
        }
        .navigationTitle("탭 없이 열기")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct QuickLaunchRecipe: Identifiable {
    let id = UUID()
    let title: String
    let systemImage: String
    let steps: [String]
    let note: String

    static let all: [QuickLaunchRecipe] = [
        QuickLaunchRecipe(
            title: "뒷면 두 번 탭",
            systemImage: "hand.tap",
            steps: [
                "설정 > 손쉬운 사용 > 터치 > 뒷면 탭",
                "‘두 번 탭’ 선택",
                "맨 아래 단축어 목록에서 ‘바코드 열기’ 선택"
            ],
            note: "주머니에서 꺼내면서 뒷면을 두 번 치면 이미 바코드가 떠 있습니다. 가장 빠른 경로입니다."
        ),
        QuickLaunchRecipe(
            title: "액션 버튼",
            systemImage: "button.horizontal.top.press",
            steps: [
                "설정 > 액션 버튼",
                "옆으로 넘겨 ‘단축어’ 선택",
                "‘바코드 열기’ 선택"
            ],
            note: "아이폰 15 Pro 이상에서만 있습니다. 길게 누르면 바로 열립니다."
        ),
        QuickLaunchRecipe(
            title: "시리",
            systemImage: "mic",
            steps: [
                "따로 설정할 것이 없습니다",
                "‘시리야, 지갑 없는 날 바코드’ 라고 말하면 됩니다"
            ],
            note: "손이 하나만 비어 있을 때 쓸 수 있는 유일한 경로입니다."
        ),
        QuickLaunchRecipe(
            title: "제어 센터",
            systemImage: "switch.2",
            steps: [
                "제어 센터를 열고 왼쪽 위 ‘+’ 를 누릅니다",
                "‘제어 추가’ 에서 ‘바코드 열기’ 를 찾아 추가"
            ],
            note: "iOS 18 이상. 잠금 상태에서도 위에서 쓸어내려 누를 수 있습니다."
        ),
        QuickLaunchRecipe(
            title: "Spotlight 검색",
            systemImage: "magnifyingglass",
            steps: [
                "따로 설정할 것이 없습니다",
                "홈 화면에서 아래로 쓸어내리고 ‘바코드’ 를 입력"
            ],
            note: "앱 아이콘을 찾아 헤매는 것보다 빠릅니다."
        )
    ]
}
