import SwiftUI
import UIKit
import AVFoundation

@main
struct KenhLiveApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    init() {
        configureAudioSession()
        configureNavigationAppearance()
        configureImageAndNetworkCache()
    }

    var body: some Scene {
        WindowGroup {
            MainTabView()
                .preferredColorScheme(.dark)
        }
    }

    private func configureImageAndNetworkCache() {
        // Cache API JSON gọn nhẹ (chỉ 8MB RAM, 20MB Disk), không lưu đúp ảnh
        let memoryCap = 8 * 1024 * 1024
        let diskCap = 20 * 1024 * 1024
        URLCache.shared = URLCache(
            memoryCapacity: memoryCap,
            diskCapacity: diskCap,
            diskPath: "kl_network_api_cache"
        )
    }

    private func configureAudioSession() {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .moviePlayback)
            try session.setActive(true)
        } catch {
            // Ignore audio session setup errors on simulator
        }
    }

    private func configureNavigationAppearance() {
        let navAppearance = UINavigationBarAppearance()
        navAppearance.configureWithOpaqueBackground()
        navAppearance.backgroundColor = UIColor.black
        navAppearance.titleTextAttributes = [.foregroundColor: UIColor.white]
        navAppearance.largeTitleTextAttributes = [.foregroundColor: UIColor.white]
        UINavigationBar.appearance().standardAppearance = navAppearance
        UINavigationBar.appearance().scrollEdgeAppearance = navAppearance
        UINavigationBar.appearance().compactAppearance = navAppearance
    }
}
