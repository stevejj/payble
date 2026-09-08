import Foundation

/// EAN-13 / EAN-8 / UPC-A 모듈 인코더.
///
/// CoreImage에는 Code128·QR 생성기만 있고 EAN 계열이 없다.
/// 국내 멤버십 바코드는 EAN-13이 가장 흔해서 직접 만든다.
enum EANEncoder {
    // 좌측 홀수 패리티
    private static let l = [
        "0001101", "0011001", "0010011", "0111101", "0100011",
        "0110001", "0101111", "0111011", "0110111", "0001011"
    ]
    // 좌측 짝수 패리티
    private static let g = [
        "0100111", "0110011", "0011011", "0100001", "0011101",
        "0111001", "0000101", "0010001", "0001001", "0010111"
    ]
    // 우측
    private static let r = [
        "1110010", "1100110", "1101100", "1000010", "1011100",
        "1001110", "1010000", "1000100", "1001000", "1110100"
    ]
    // 첫 자리가 결정하는 2~7번째 자리의 패리티 배치
    private static let parity = [
        "LLLLLL", "LLGLGG", "LLGGLG", "LLGGGL", "LGLLGG",
        "LGGLLG", "LGGGLL", "LGLGLG", "LGLGGL", "LGGLGL"
    ]

    private static let guardPattern = "101"
    private static let centerPattern = "01010"

    /// 체크디지트를 뺀 앞자리들로 체크디지트를 계산한다.
    /// 오른쪽에서부터 3, 1, 3, 1... 가중치 — EAN-13/EAN-8/UPC-A에 모두 같은 규칙이 적용된다.
    static func checkDigit(forPrefix digits: String) -> Int? {
        let values = digits.compactMap { $0.wholeNumberValue }
        guard values.count == digits.count, !values.isEmpty else { return nil }
        let sum = values.reversed().enumerated().reduce(0) { acc, pair in
            acc + pair.element * (pair.offset.isMultiple(of: 2) ? 3 : 1)
        }
        return (10 - sum % 10) % 10
    }

    /// 입력을 정규화한다.
    /// - 자릿수가 하나 모자라면 체크디지트를 붙여준다. (카드 뒷면 숫자를 그대로 치는 경우)
    /// - 다 채워져 있으면 체크디지트가 맞는지 검사한다.
    static func normalized(_ raw: String, for symbology: BarcodeSymbology) -> String? {
        guard let total = symbology.digitCount else { return nil }
        let digits = raw.filter(\.isNumber)
        if digits.count == total - 1 {
            guard let check = checkDigit(forPrefix: digits) else { return nil }
            return digits + String(check)
        }
        if digits.count == total {
            let prefix = String(digits.dropLast())
            guard let check = checkDigit(forPrefix: prefix),
                  digits.last?.wholeNumberValue == check else { return nil }
            return digits
        }
        return nil
    }

    /// 검은 막대를 true로 나타낸 모듈 배열.
    static func modules(_ value: String, for symbology: BarcodeSymbology) -> [Bool]? {
        switch symbology {
        case .ean13: return ean13(value)
        case .upca: return ean13("0" + value)
        case .ean8: return ean8(value)
        case .code128, .qr: return nil
        }
    }

    private static func ean13(_ value: String) -> [Bool]? {
        let d = value.compactMap { $0.wholeNumberValue }
        guard d.count == 13, let first = d.first, parity.indices.contains(first) else { return nil }
        let layout = Array(parity[first])
        var bits = guardPattern
        for (index, digit) in d[1...6].enumerated() {
            bits += layout[index] == "L" ? l[digit] : g[digit]
        }
        bits += centerPattern
        for digit in d[7...12] {
            bits += r[digit]
        }
        bits += guardPattern
        return bits.map { $0 == "1" }
    }

    private static func ean8(_ value: String) -> [Bool]? {
        let d = value.compactMap { $0.wholeNumberValue }
        guard d.count == 8 else { return nil }
        var bits = guardPattern
        for digit in d[0...3] { bits += l[digit] }
        bits += centerPattern
        for digit in d[4...7] { bits += r[digit] }
        bits += guardPattern
        return bits.map { $0 == "1" }
    }
}
