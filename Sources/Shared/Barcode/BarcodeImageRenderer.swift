import CoreGraphics
import CoreImage
import CoreImage.CIFilterBuiltins
import Foundation

/// 바코드 → CGImage.
/// EAN 계열은 직접 그리고, Code128·QR은 CoreImage에 맡긴다.
enum BarcodeImageRenderer {
    private static let context = CIContext(options: [.useSoftwareRenderer: false])
    private static let cache = NSCache<NSString, CGImage>()

    static func image(for barcode: Barcode) -> CGImage? {
        let key = "\(barcode.symbology.rawValue):\(barcode.value)" as NSString
        if let cached = cache.object(forKey: key) { return cached }
        let made: CGImage?
        switch barcode.symbology {
        case .ean13, .ean8, .upca:
            made = EANEncoder.modules(barcode.value, for: barcode.symbology).flatMap(stripeImage)
        case .code128:
            made = filterImage(barcode.value) { value in
                let f = CIFilter.code128BarcodeGenerator()
                f.message = Data(value.utf8)
                f.quietSpace = 8
                return f.outputImage
            }
        case .qr:
            made = filterImage(barcode.value) { value in
                let f = CIFilter.qrCodeGenerator()
                f.message = Data(value.utf8)
                f.correctionLevel = "M"
                return f.outputImage
            }
        }
        if let made { cache.setObject(made, forKey: key) }
        return made
    }

    /// 모듈 하나가 가로 1픽셀인 이미지. 표시할 때 보간 없이 늘린다.
    /// (보간을 켜면 막대 경계가 뭉개져서 스캐너가 못 읽는다)
    private static func stripeImage(_ modules: [Bool]) -> CGImage? {
        let quietZone = 10
        let width = modules.count + quietZone * 2
        let height = 1
        var pixels = [UInt8](repeating: 255, count: width * height)
        for (index, isBar) in modules.enumerated() where isBar {
            pixels[index + quietZone] = 0
        }
        guard let provider = CGDataProvider(data: Data(pixels) as CFData) else { return nil }
        return CGImage(
            width: width,
            height: height,
            bitsPerComponent: 8,
            bitsPerPixel: 8,
            bytesPerRow: width,
            space: CGColorSpaceCreateDeviceGray(),
            bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.none.rawValue),
            provider: provider,
            decode: nil,
            shouldInterpolate: false,
            intent: .defaultIntent
        )
    }

    private static func filterImage(_ value: String, _ make: (String) -> CIImage?) -> CGImage? {
        guard !value.isEmpty, let output = make(value) else { return nil }
        return context.createCGImage(output, from: output.extent)
    }
}
