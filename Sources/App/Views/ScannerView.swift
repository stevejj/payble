import AVFoundation
import SwiftUI

/// 카드 뒷면 바코드를 카메라로 읽어 값과 종류를 그대로 가져온다.
/// 직접 타이핑하게 만들면 등록 단계에서 이탈한다.
struct ScannerView: UIViewControllerRepresentable {
    let onScan: (Barcode) -> Void

    func makeUIViewController(context: Context) -> ScannerViewController {
        let controller = ScannerViewController()
        controller.onScan = onScan
        return controller
    }

    func updateUIViewController(_ uiViewController: ScannerViewController, context: Context) {}
}

final class ScannerViewController: UIViewController {
    var onScan: ((Barcode) -> Void)?

    private let session = AVCaptureSession()
    private var previewLayer: AVCaptureVideoPreviewLayer?
    private var hasDelivered = false

    /// UPC-E는 압축 표기라 UPC-A로 펼치지 않으면 그대로 그릴 수 없다. 지금은 받지 않는다.
    private static let supported: [AVMetadataObject.ObjectType: BarcodeSymbology] = [
        .ean13: .ean13,
        .ean8: .ean8,
        .code128: .code128,
        .qr: .qr
    ]

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        configureSession()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        guard !session.isRunning else { return }
        DispatchQueue.global(qos: .userInitiated).async { [session] in session.startRunning() }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        guard session.isRunning else { return }
        DispatchQueue.global(qos: .userInitiated).async { [session] in session.stopRunning() }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        previewLayer?.frame = view.bounds
    }

    private func configureSession() {
        guard let device = AVCaptureDevice.default(for: .video),
              let input = try? AVCaptureDeviceInput(device: device),
              session.canAddInput(input) else { return }
        session.addInput(input)

        let output = AVCaptureMetadataOutput()
        guard session.canAddOutput(output) else { return }
        session.addOutput(output)
        output.setMetadataObjectsDelegate(self, queue: .main)
        output.metadataObjectTypes = Array(Self.supported.keys)

        let layer = AVCaptureVideoPreviewLayer(session: session)
        layer.videoGravity = .resizeAspectFill
        layer.frame = view.bounds
        view.layer.addSublayer(layer)
        previewLayer = layer
    }
}

extension ScannerViewController: AVCaptureMetadataOutputObjectsDelegate {
    func metadataOutput(
        _ output: AVCaptureMetadataOutput,
        didOutput metadataObjects: [AVMetadataObject],
        from connection: AVCaptureConnection
    ) {
        guard !hasDelivered,
              let object = metadataObjects.compactMap({ $0 as? AVMetadataMachineReadableCodeObject }).first,
              let symbology = Self.supported[object.type],
              let value = object.stringValue else { return }
        hasDelivered = true
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        onScan?(Barcode(value: value, symbology: symbology))
    }
}
