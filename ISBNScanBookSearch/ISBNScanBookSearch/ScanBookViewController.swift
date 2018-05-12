//
//  ScanBookViewController.swift
//  ISBNScanBookSearch
//

import UIKit
import AVKit

class ScanBookViewController: UIViewController {

    private let viewModel = ScanBookViewModel()
    private var preview: VideoPreviewLayer?
    private var previewBase: PreviewBaseView = PreviewBaseView()
    private let bookTitleLabel = UILabel()
    private let openRakutenButton = UIButton()
    private let openAmazonButton = UIButton()

    static func start(on parent: UIViewController) {
        guard ScanBookUtility.checkCameraUseAvailability(viewController: parent) else {
            return
        }
        let thisViewController = ScanBookViewController()
        let navigationController = UINavigationController(rootViewController: thisViewController)
        parent.present(navigationController, animated: true) { }
    }

    convenience init() {
        self.init(nibName: nil, bundle: nil)
    }

    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("\(#function): no support of NSCoding")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        edgesForExtendedLayout = UIRectEdge.init(rawValue: 0)
        navigationItem.title = viewModel.scanTitle
        registerAppStateNotifications()

        viewModel.handleQR = { [weak self] (string, urls) in
            self?.showQROptions(text: string, urls: urls)
        }
        viewModel.handleISBN = { [weak self] error in
            guard error == nil else {
                self?.alert(title: "error", message: "\(error?.localizedDescription ?? "")")
                return
            }
            self?.showISBNOptions()
        }

        setupViews()
        viewModel.setupVideo()
        viewModel.start()
    }

    private func registerAppStateNotifications() {
        let names: [Notification.Name] = [
            .UIApplicationWillEnterForeground,
            .UIApplicationDidBecomeActive,
            .UIApplicationWillResignActive,
            .UIApplicationDidEnterBackground,
            .UIApplicationWillTerminate
        ]
        for name in names {
            NotificationCenter.default.addObserver(self, selector: #selector(appStateChange(_:)), name: name, object: nil)
        }
    }

    @objc private func appStateChange(_ notification: Notification) {
        switch notification.name {
        case NSNotification.Name.UIApplicationWillEnterForeground:
            break
        case NSNotification.Name.UIApplicationDidBecomeActive:
            viewModel.start()
        case NSNotification.Name.UIApplicationWillResignActive:
            viewModel.stop()
        case NSNotification.Name.UIApplicationDidEnterBackground:
            break
        case NSNotification.Name.UIApplicationWillTerminate:
            break
        default:
            break
        }
    }

    private func setupViews() {
        let bounds = view.bounds
        let width = bounds.width
        let height = bounds.height
        let dimension: CGFloat = min(width, height)
        previewBase.setup(dimension: dimension)
        preview = VideoPreviewLayer(session: viewModel.session)
        preview?.setup(dimension: dimension)
        previewBase.layer.addSublayer(preview!)
        view.addSubview(previewBase)
    }

    private func showQROptions(text: String, urls: [URL]) {
        let title: String? = nil
        let message: String? = text
        let alert = UIAlertController.init(title: title, message: message, preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction.init(title: viewModel.optionQRCopyText, style: .default, handler: { (action) in
            UIPasteboard.general.string = text
        }))
        if let url = urls.first {
            alert.addAction(UIAlertAction.init(title: viewModel.optionQRCopyURL, style: .default, handler: { (action) in
                UIPasteboard.general.url = url
            }))
            alert.addAction(UIAlertAction.init(title: viewModel.optionQROpenURL, style: .default, handler: { (action) in
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
            }))
        }
        alert.addAction(UIAlertAction.init(title: viewModel.optionCancel, style: .cancel, handler: { [weak self] (action) in
            self?.viewModel.start()
        }))
        alert.popoverPresentationController?.sourceView = view
        alert.popoverPresentationController?.sourceRect = view.frame
        self.present(alert, animated: true, completion: { })
    }

    private func showISBNOptions() {
        let viewModel = self.viewModel
        let title: String? = nil
        let message: String? = viewModel.bookTitle
        let alert = UIAlertController.init(title: title, message: message, preferredStyle: .actionSheet)
        if let _ = viewModel.bookTitle {
            alert.addAction(UIAlertAction.init(title: viewModel.optionBookCopyTitle, style: .default, handler: { (action) in
                viewModel.copyBookTitle()
            }))
        }
        if viewModel.canOpenInRakutenBook {
            alert.addAction(UIAlertAction.init(title: viewModel.optionBookOpenInRakuten, style: .default, handler: { (action) in
                viewModel.openRakutenBook()
            }))
        }
        if viewModel.canOpenInAmazon {
            alert.addAction(UIAlertAction.init(title: viewModel.optionBookOpenInAmazon, style: .default, handler: { (action) in
                viewModel.openAmazon()
            }))
        }
        alert.addAction(UIAlertAction.init(title: viewModel.optionCancel, style: .cancel, handler: { (action) in
            viewModel.start()
        }))
        alert.popoverPresentationController?.sourceView = view
        alert.popoverPresentationController?.sourceRect = view.frame
        self.present(alert, animated: true, completion: { })
    }

    func alert(title: String?, message: String?) {
        let alert = UIAlertController.init(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction.init(title: "OK", style: .default, handler: { (action) in }))
        self.present(alert, animated: true, completion: { })
    }
}

private class PreviewBaseView: UIView {
    func setup(dimension: CGFloat) {
        let base = self
        base.frame = CGRect(x: 0, y: 0, width: dimension, height: dimension * 0.618)
        base.backgroundColor = UIColor.orange
        base.clipsToBounds = true
        base.layer.borderColor = UIColor.white.cgColor
        base.layer.borderWidth = 2
    }
}

private class VideoPreviewLayer: AVCaptureVideoPreviewLayer {
    func setup(dimension: CGFloat) {
        let pv = self
        pv.frame = CGRect(x: 0, y: 0, width: dimension, height: dimension * 0.618)
        pv.videoGravity = AVLayerVideoGravity.resizeAspectFill
    }
}

