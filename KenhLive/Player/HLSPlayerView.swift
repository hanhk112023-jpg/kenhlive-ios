import SwiftUI
import AVKit

struct HLSPlayerView: View {
    let title: String
    let subtitle: String
    var roomNum: String? = nil
    var directUrl: String? = nil
    var streamReferer: String? = nil
    var room: LiveRoom? = nil

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
        if let r = room {
            let list = await SportsService.shared.resolveStreamServers(room: r)
            servers = list
            if let first = list.first, let url = URL(string: first.url) {
                playUrl(url, referer: first.referer.isEmpty ? r.streamReferer : first.referer)
            }
        } else if let direct = directUrl, let url = URL(string: direct) {
            let ref = streamReferer ?? ""
            servers = [StreamServer(name: "MÁY CHỦ CHÍNH", url: direct, isBackup: false, referer: ref)]
            playUrl(url, referer: ref)
        } else if let num = roomNum {
            let dummy = LiveRoom(roomNum: num, blvName: "BLV", avatar: "", viewers: 0, matchTitle: title, league: subtitle, cover: "", category: "Bóng đá", blvLevel: "", score: 0, notice: "")
            let list = await SportsService.shared.resolveStreamServers(room: dummy)
            servers = list
            if let first = list.first, let url = URL(string: first.url) {
                playUrl(url, referer: first.referer)
            }
        }
        isLoadingStream = false
    }

    private func switchServer(to index: Int) {
        guard index < servers.count, let url = URL(string: servers[index].url) else { return }
        currentServerIndex = index
        playUrl(url, referer: servers[index].referer)
    }

    private func playUrl(_ url: URL, referer: String) {
        var headers: [String: String] = [
            "User-Agent": "Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X)"
        ]
        if !referer.isEmpty {
            headers["Referer"] = referer
        }

        let asset = AVURLAsset(url: url, options: [
            "AVURLAssetHTTPHeaderFieldsKey": headers
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
