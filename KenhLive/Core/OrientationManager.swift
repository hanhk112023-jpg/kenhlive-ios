import SwiftUI
import UIKit

// MARK: - App Delegate for Screen Orientation Control
final class AppDelegate: NSObject, UIApplicationDelegate {
    static var orientationLock: UIInterfaceOrientationMask = .portrait

    func application(
        _ application: UIApplication,
        supportedInterfaceOrientationsFor window: UIWindow?
    ) -> UIInterfaceOrientationMask {
        // iPad supports all orientations naturally
        if UIDevice.current.userInterfaceIdiom == .pad {
            return .all
        }
        return AppDelegate.orientationLock
    }
}

// MARK: - Orientation Manager
enum OrientationManager {
    /// Lock orientation to specified mask and request device rotation
    static func lockOrientation(
        _ mask: UIInterfaceOrientationMask,
        rotateTo orientation: UIInterfaceOrientation? = nil
    ) {
        AppDelegate.orientationLock = mask

        DispatchQueue.main.async {
            if #available(iOS 16.0, *) {
                let scenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
                guard let windowScene = scenes.first(where: { $0.activationState == .foregroundActive }) ?? scenes.first else {
                    return
                }

                let targetMask: UIInterfaceOrientationMask
                if mask.contains(.landscape) || mask == .landscapeRight || mask == .landscapeLeft {
                    targetMask = .landscape
                } else {
                    targetMask = .portrait
                }

                let preferences = UIWindowScene.GeometryPreferences.iOS(interfaceOrientations: targetMask)
                windowScene.requestGeometryUpdate(preferences) { error in
                    // System rejected or already in target geometry
                }
                windowScene.keyWindow?.rootViewController?.setNeedsUpdateOfSupportedInterfaceOrientations()
            } else {
                let targetRaw = orientation?.rawValue ?? (mask == .portrait ? UIInterfaceOrientation.portrait.rawValue : UIInterfaceOrientation.landscapeRight.rawValue)
                UIDevice.current.setValue(targetRaw, forKey: "orientation")
                UIViewController.attemptRotationToDeviceOrientation()
            }
        }
    }

    /// Automatically locks and rotates screen to Landscape for Cinema viewing
    static func lockLandscape() {
        lockOrientation([.landscapeLeft, .landscapeRight], rotateTo: .landscapeRight)
    }

    /// Restores screen orientation to Portrait for normal browsing
    static func lockPortrait() {
        lockOrientation(.portrait, rotateTo: .portrait)
    }

    /// Unlock to permit both portrait and landscape
    static func unlockAll() {
        lockOrientation(.allButUpsideDown)
    }
}
