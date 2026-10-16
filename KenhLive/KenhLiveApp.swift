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
        let memoryCap = 150 * 1024 * 1024 // 150 MB RAM
        let diskCap = 600 * 1024 * 1024   // 600 MB Disk
        URLCache.shared = URLCache(
            memoryCapacity: memoryCap,
            diskCapacity: diskCap,
            diskPath: "kl_network_image_cache"
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
        navAppearance.backgroundColor = UIColor(red: 7/255, green: 8/255, blue: 14/255, alpha: 0.94)
        navAppearance.titleTextAttributes = [.foregroundColor: UIColor.white]
        navAppearance.largeTitleTextAttributes = [.foregroundColor: UIColor.white]
        UINavigationBar.appearance().standardAppearance = navAppearance
        UINavigationBar.appearance().scrollEdgeAppearance = navAppearance
        UINavigationBar.appearance().compactAppearance = navAppearance
    }
}
