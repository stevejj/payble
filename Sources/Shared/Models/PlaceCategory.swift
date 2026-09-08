import Foundation

/// 카드를 어디서 쓰는지.
///
/// 브랜드가 아니라 **장소의 종류**만 다룬다. 어떤 매장이 어떤 포인트와 제휴했는지는
/// 앱이 알 수 없고, 틀린 정보는 정보 없음보다 나쁘기 때문이다.
/// "편의점에서 쓰는 카드"라는 것만 알아도 계산대에서 꺼낼지 말지는 정해진다.
///
/// 2차에서 위치로 "지금 여기"를 판별할 때, 맞춰볼 대상이 바로 이 값이다.
enum PlaceCategory: String, Codable, CaseIterable, Identifiable, Sendable {
    case convenience
    case cafe
    case mart
    case bakery
    case restaurant
    case gas
    case movie
    case other

    var id: String { rawValue }

    var title: String {
        switch self {
        case .convenience: return "편의점"
        case .cafe: return "카페"
        case .mart: return "마트"
        case .bakery: return "베이커리"
        case .restaurant: return "음식점"
        case .gas: return "주유소"
        case .movie: return "영화관"
        case .other: return "기타"
        }
    }

    var systemImage: String {
        switch self {
        case .convenience: return "basket"
        case .cafe: return "cup.and.saucer"
        case .mart: return "cart"
        case .bakery: return "birthday.cake"
        case .restaurant: return "fork.knife"
        case .gas: return "fuelpump"
        case .movie: return "film"
        case .other: return "tag"
        }
    }

    /// 온보딩에서 카드 이름을 제안할 때 쓴다. 브랜드를 지어내지 않는다.
    var suggestedCardName: String {
        switch self {
        case .convenience: return "편의점 멤버십"
        case .cafe: return "카페 적립"
        case .mart: return "마트 포인트"
        case .bakery: return "베이커리 적립"
        case .restaurant: return "식당 적립"
        case .gas: return "주유 할인"
        case .movie: return "영화 멤버십"
        case .other: return "적립 카드"
        }
    }

    var chip: ChipItem { ChipItem(id: rawValue, title: title) }

    static func from(chip: ChipItem) -> PlaceCategory? {
        PlaceCategory(rawValue: chip.id)
    }
}

/// 칩 하나. 화면 쪽에서 문자열을 다시 enum으로 되돌리지 않아도 되게 id를 들고 다닌다.
struct ChipItem: Identifiable, Hashable, Sendable {
    let id: String
    let title: String
}
