import SwiftUI
import AVKit

struct HLSPlayerView: View {
    let title: String
    let subtitle: String
    let roomNum: String?
    let directUrl: String?

    @Environment(\.dismiss) private var dismiss
    @State private var servers: [StreamServer] = []
    @State private var currentServerIndex: Int = 0
    @State private var player: AVPlayer? = nil
    @State private var isShowingServerSheet: Bool = false
    @State private var isLoadingStream: Bool = true

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            if let p = player {
                CustomAVPlayerViewControllerRepresentable(player: p)
                    .ignoresSafeArea()
            }

            // Top Bar Overlay
            VStack {
                HStack(alignment: .top) {
                    Button {
                        player?.pause()
                        dismiss()
                    } label: {
                        Text("ĐÓNG")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(Color.black.opacity(0.65))
                            .cornerRadius(8)
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 3) {
                        Text(title)
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white)
                            .lineLimit(1)

                        Text(subtitle)
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(KLTheme.textSecondary)
                    }

                    if servers.count > 1 {
                        Button {
                            isShowingServerSheet = true
                        } label: {
                            Text("ĐỔI SERVER")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(KLTheme.brandOrange)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(Color.black.opacity(0.65))
                                .cornerRadius(8)
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 10)

                Spacer()
            }

            if isLoadingStream {
                ProgressView()
                    .tint(KLTheme.brandOrange)
            }
        }
        .task {
            await startPlayback()
        }
        .onDisappear {
            player?.pause()
            player = nil
        }
        .confirmationDialog("Chọn Máy Chủ Phát", isPresented: $isShowingServerSheet, titleVisibility: .visible) {
            ForEach(Array(servers.enumerated()), id: \.offset) { index, srv in
                Button(srv.name) {
                    switchServer(to: index)
                }
            }
            Button("Hủy", role: .cancel) { }
        }
    }

    private func startPlayback() async {
        isLoadingStream = true
        if let direct = directUrl, let url = URL(string: direct) {
            servers = [StreamServer(name: "MÁY CHỦ CHÍNH", url: direct, isBackup: false)]
            playUrl(url)
        } else if let num = roomNum {
            let list = await SportsService.shared.resolveStreamServers(roomNum: num)
            servers = list
            if let first = list.first, let url = URL(string: first.url) {
                playUrl(url)
            }
        }
        isLoadingStream = false
    }

    private func switchServer(to index: Int) {
        guard index < servers.count, let url = URL(string: servers[index].url) else { return }
        currentServerIndex = index
        playUrl(url)
    }

    private func playUrl(_ url: URL) {
        let asset = AVURLAsset(url: url, options: [
            "AVURLAssetHTTPHeaderFieldsKey": [
                "Referer": "https://vnres.co/",
                "User-Agent": "Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X)"
            ]
        ])
        let item = AVPlayerItem(asset: asset)
        if player == nil {
            player = AVPlayer(playerItem: item)
        } else {
            player?.replaceCurrentItem(with: item)
        }
        player?.play()
    }
}

private struct CustomAVPlayerViewControllerRepresentable: UIViewControllerRepresentable {
    let player: AVPlayer

    func makeUIViewController(context: Context) -> AVPlayerViewController {
        let vc = AVPlayerViewController()
        vc.player = player
        vc.allowsPictureInPicturePlayback = true
        vc.showsPlaybackControls = true
        return vc
    }

    func updateUIViewController(_ uiViewController: AVPlayerViewController, context: Context) {
        uiViewController.player = player
    }
}
