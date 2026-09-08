import Foundation

/// 국내 멤버십·포인트 카드에서 실제로 쓰이는 것만 담았다.
enum BarcodeSymbology: String, Codable, CaseIterable, Identifiable, Sendable {
    case ean13
    case ean8
    case upca
    case code128
    case qr

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .ean13: return "EAN-13"
        case .ean8: return "EAN-8"
        case .upca: return "UPC-A"
        case .code128: return "Code 128"
        case .qr: return "QR 코드"
        }
    }

    var hint: String {
        switch self {
        case .ean13: return "숫자 13자리. 국내 멤버십에서 가장 흔하다."
        case .ean8: return "숫자 8자리."
        case .upca: return "숫자 12자리."
        case .code128: return "숫자·영문 혼합. 길이 제한이 느슨하다."
        case .qr: return "정사각형 코드."
        }
    }

    /// 체크디지트를 포함한 전체 자릿수. 가변 길이면 nil.
    var digitCount: Int? {
        switch self {
        case .ean13: return 13
        case .ean8: return 8
        case .upca: return 12
        case .code128, .qr: return nil
        }
    }

    var isNumericOnly: Bool { digitCount != nil }

    var isSquare: Bool { self == .qr }
}

struct Barcode: Codable, Hashable, Sendable {
    var value: String
    var symbology: BarcodeSymbology

    /// 화면에 사람이 읽을 수 있게 끊어서 보여주는 형태.
    var groupedValue: String {
        guard symbology.isNumericOnly else { return value }
        switch symbology {
        case .ean13:
            guard value.count == 13 else { return value }
            let d = Array(value)
            return "\(d[0])  \(String(d[1...6]))  \(String(d[7...12]))"
        case .upca:
            guard value.count == 12 else { return value }
            let d = Array(value)
            return "\(d[0])  \(String(d[1...5]))  \(String(d[6...10]))  \(d[11])"
        case .ean8:
            guard value.count == 8 else { return value }
            let d = Array(value)
            return "\(String(d[0...3]))  \(String(d[4...7]))"
        default:
            return value
        }
    }
}
