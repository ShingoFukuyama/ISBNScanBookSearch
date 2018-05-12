//
//  ScanBookViewModel.swift
//  ISBNScanBookSearch
//

import AVKit

class ScanBookViewModel: NSObject {

    let scanTitle = "QR/ISBNスキャン"
    let scanCameraNotFound = "カメラがありません"
    let scanRequrePermission = "この機能を使用するにはプライバシー設定が必要です。\n設定画面に移動しますか？"
    let optionQRCopyText = "Copy Text"
    let optionQRCopyURL = "Copy URL"
    let optionQROpenURL = "Open URL"
    let optionBookCopyTitle = "Open Title"
    let optionBookOpenInRakuten = "Open in Rakuten"
    let optionBookOpenInAmazon = "Open in Amazon"
    let optionCancel = "Cancel"

    var session: AVCaptureSession = AVCaptureSession()
    private let model = ScanBookModel()
    private var isRunning = false

    var bookTitle: String? {
        return model.isbn?.title
    }

    var canOpenInRakutenBook: Bool {
        if let url = model.isbn?.rakutenURL,
            UIApplication.shared.canOpenURL(url) {
            return true
        }
        return false
    }

    var canOpenInAmazon: Bool {
        if let url = model.isbn?.amazonURL,
            UIApplication.shared.canOpenURL(url) {
            return true
        }
        return false
    }

    var handleQR: ((String, [URL]) -> Void)?

    var handleISBN: ((Error?) -> Void)? {
        get {
            return model.handleISBN
        }
        set {
            model.handleISBN = newValue
        }
    }
    
    func start() {
        guard !isRunning else {
            return
        }
        session.startRunning()
        isRunning = true
    }

    func stop() {
        guard isRunning else {
            return
        }
        session.stopRunning()
        isRunning = false
    }

    func copyBookTitle() {
        guard let title = model.isbn?.title else {
            return
        }
        UIPasteboard.general.string = title
    }

    func openRakutenBook() {
        guard let url = model.isbn?.rakutenURL else {
            return
        }
        UIApplication.shared.open(url, options: [:], completionHandler: nil)
    }

    func openAmazon() {
        guard let url = model.isbn?.amazonURL else {
            return
        }
        UIApplication.shared.open(url, options: [:], completionHandler: nil)
    }

    func setupVideo() {
        guard let device = AVCaptureDevice.default(
            AVCaptureDevice.DeviceType.builtInWideAngleCamera,
            for: AVMediaType.video,
            position: AVCaptureDevice.Position.back)
            else {
                return
        }
        do {
            let input = try AVCaptureDeviceInput(device: device)
            session.addInput(input)
            let output = AVCaptureMetadataOutput()
            output.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
            session.addOutput(output)
            output.metadataObjectTypes = [.qr, .ean13]
        }
        catch {
            print("\(type(of: self)) \(#function)  error:\(error)")
        }
    }
}


extension ScanBookViewModel: AVCaptureMetadataOutputObjectsDelegate {
    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {

        for case let _metadata in metadataObjects {
            guard let metadata = _metadata as? AVMetadataMachineReadableCodeObject else {
                continue
            }
            let type: AVMetadataObject.ObjectType = metadata.type
            switch type {
            case .qr:
                guard let code = metadata.stringValue else {
                    continue
                }
                stop()
                let urls = extractURL(from: code)
                handleQR?(code, urls)
            case .ean13:
                guard let ean13 = metadata.stringValue,
                    !ean13.isEmpty,
                    let value = Int64(ean13)
                    else {
                        continue
                }
                let prefix = value / 10_000_000_000
                guard prefix == 978 || prefix == 979 else {
                    continue
                }
                stop()
                model.fetchRakutenBookURL(code: ean13)
            default:
                break
            }
        }
    }

    private func extractURL(from string: String) -> [URL] {
        guard let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue) else {
            return []
        }
        let links = detector.matches(in: string, options: [], range: NSRange(string.startIndex..., in: string))
        return links.compactMap { $0.url }
    }
}
