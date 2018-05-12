//
//  ScanBookUtility.swift
//  ISBNScanBookSearch
//
//  Created by Shingo Fukuyama on 2018/05/12.
//  Copyright © 2018 Shingo Fukuyama. All rights reserved.
//

import UIKit
import AVKit

class ScanBookUtility {

    private struct Text {
        let scanTitle = "ISBN Scan"
        let cameraNotFound = "Camera not found"
        let actionOK = "OK"
        let scanRequrePermission = "You need to enable camera access. Go to settings page? / この機能を使用するにはプライバシー設定が必要です。\n設定画面に移動しますか？"
        let actionMove = "Go"
        let actionCancel = "Cancel"
    }

    static var isCameraUseAllowed: Bool {
        let status: AVAuthorizationStatus = AVCaptureDevice.authorizationStatus(for: AVMediaType.video)
        return status == .authorized
    }

    static func checkCameraUseAvailability(viewController: UIViewController) -> Bool {
        let text = ScanBookUtility.Text()
        guard UIImagePickerController.isSourceTypeAvailable(.camera) else {
            let alert = UIAlertController.init(title: text.scanTitle, message: text.cameraNotFound, preferredStyle: .alert)
            alert.addAction(UIAlertAction.init(title: text.actionOK, style: .default, handler: { (action) in }))
            viewController.present(alert, animated: true, completion: { })
            return false
        }
        let status: AVAuthorizationStatus = AVCaptureDevice.authorizationStatus(for: AVMediaType.video)
        switch status {
        case .authorized,
             .notDetermined:
            return true
        case .denied:
            let alert = UIAlertController.init(title: text.scanTitle, message: text.scanRequrePermission, preferredStyle: .alert)
            alert.addAction(UIAlertAction.init(title: text.actionMove, style: .default, handler: { (action) in
                goToSettingsApp()
            }))
            alert.addAction(UIAlertAction.init(title: text.actionCancel, style: .cancel, handler: { (action) in }))
            viewController.present(alert, animated: true, completion: {  })
            return false
        case .restricted:
            return false
        }
    }

    static func goToSettingsApp() {
        if let url = URL(string: UIApplicationOpenSettingsURLString) {
            if #available(iOS 10.0, *) {
                UIApplication.shared.open(url, options: [:], completionHandler: { (finished) in })
            }
            else {
                UIApplication.shared.openURL(url)
            }
        }
    }

}
