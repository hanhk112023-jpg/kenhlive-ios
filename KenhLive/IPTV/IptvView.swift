import SwiftUI
import AVKit

struct IptvView: View {
    @ObservedObject private var storage = StorageManager.shared
    @State private var categories: [IptvCategory] = []
    @State private var selectedCategory: String = "VTV Quốc Gia"
    @State private var previewChannel: IptvChannel? = nil
    @State private var activeChannelForPlayer: IptvChannel? = nil
    @State private var isLoading: Bool = true

    private var currentCategoryChannels: [IptvChannel] {
        if selectedCategory == "Yêu Thích" {
            let favs = categories.flatMap { $0.channels }.filter { storage.isFavoriteChannel(id: $0.channelId) }
            return Array(Set(favs))
        }
        return categories.first(where: { $0.name == selectedCategory })?.channels ?? []
    }

    private var categoryTabs: [KLFilterItem<String>] {
        categories.map { KLFilterItem(id: $0.name, title: $0.name) }
    }

    var body: some View {
        ZStack {
            KLTheme.bgDeep.ignoresSafeArea()

            VStack(spacing: 0) {
                // Header Bar (Typography-First, Zero Icons)
                HStack(alignment: .lastTextBaseline) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("TRUYỀN HÌNH VIỆT NAM")
                            .font(.system(size: 11, weight: .black, design: .rounded))
                            .tracking(1.8)
                            .foregroundColor(KLTheme.brandOrange)

                        Text("Kênh TV Trực Tuyến")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(KLTheme.textPrimary)
                    }

                    Spacer()

                    if let preview = previewChannel {
                        Text(preview.name)
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(KLTheme.textSecondary)
                            .lineLimit(1)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)
                .padding(.bottom, 10)

                // Inline Top Preview Player
                if let preview = previewChannel {
                    InlinePreviewPlayerView(channel: preview) {
                        activeChannelForPlayer = preview
                    }
                    .frame(height: 195)
                    .cornerRadius(14)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 12)
                }

                // Category Filter Strip
                if !categoryTabs.isEmpty {
                    KLFilterStrip(items: categoryTabs, selection: $selectedCategory)
                        .padding(.bottom, 12)
                }

                // Channel Grid (2 Columns on iPhone)
                ScrollView(showsIndicators: false) {
                    LazyVGrid(columns: [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)], spacing: 10) {
                        ForEach(currentCategoryChannels) { channel in
                            let isFav = storage.isFavoriteChannel(id: channel.channelId)
                            let isCurrentPreview = previewChannel?.channelId == channel.channelId

                            Button {
                                previewChannel = channel
                            } label: {
                                VStack(alignment: .leading, spacing: 8) {
                                    HStack {
                                        KLPillBadge(text: "LIVE", fg: .white, bg: KLTheme.liveRed, border: .clear)
                                        Spacer()
                                        KLPillBadge(text: channel.resolution, fg: .white, bg: Color.white.opacity(0.10), border: .clear)
                                    }

                                    Text(channel.name)
                                        .font(.system(size: 15, weight: .bold))
                                        .foregroundColor(KLTheme.textPrimary)
                                        .lineLimit(1)

                                    HStack {
                                        Text(channel.group.uppercased())
                                            .font(.system(size: 10.5, weight: .medium, design: .monospaced))
                                            .foregroundColor(KLTheme.textMuted)

                                        Spacer()

                                        if isFav {
                                            Text("LƯU")
                                                .font(.system(size: 9.5, weight: .bold))
                                                .foregroundColor(KLTheme.imdbGold)
                                                .padding(.horizontal, 6)
                                                .padding(.vertical, 2)
                                                .background(KLTheme.imdbGold.opacity(0.12))
                                                .cornerRadius(4)
                                        }
                                    }
                                }
                                .padding(13)
                                .background(isCurrentPreview ? KLTheme.brandOrange.opacity(0.15) : KLTheme.surfaceCard)
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(isCurrentPreview ? KLTheme.brandOrange : KLTheme.borderSubtle, lineWidth: isCurrentPreview ? 1.5 : 0.8)
                                )
                            }
                            .buttonStyle(.plain)
                            .contextMenu {
                                Button {
                                    activeChannelForPlayer = channel
                                } label: {
                                    Text("Phát toàn màn hình")
                                }

                                Button {
                                    storage.toggleFavoriteChannel(id: channel.channelId)
                                } label: {
                                    Text(isFav ? "Bỏ lưu kênh yêu thích" : "Lưu vào kênh yêu thích")
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 90)
                }
            }

            if isLoading && categories.isEmpty {
                ProgressView()
                    .tint(KLTheme.brandOrange)
            }
        }
        .task {
            if categories.isEmpty {
                isLoading = true
                categories = await IptvService.shared.fetchCuratedChannels()
                if let first = categories.first?.channels.first {
                    previewChannel = first
                }
                isLoading = false
            }
        }
        .fullScreenCover(item: $activeChannelForPlayer) { channel in
            HLSPlayerView(
                title: channel.name,
                subtitle: channel.group,
                roomNum: nil,
                directUrl: channel.streamUrl
            )
        }
    }
}

// MARK: - Inline Preview Player
private struct InlinePreviewPlayerView: View {
    let channel: IptvChannel
    let onExpandFullscreen: () -> Void

    @State private var player: AVPlayer? = nil

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            Color.black

            if let p = player {
                VideoPlayer(player: p)
                    .disabled(true)
            }

            // Click-to-fullscreen overlay button
            Button(action: onExpandFullscreen) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(channel.name.uppercased())
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(.white)

                        Text("Chạm để phóng to toàn màn hình")
                            .font(.system(size: 10.5, weight: .regular))
                            .foregroundColor(KLTheme.textSecondary)
                    }

                    Spacer()

                    Text("PHÁT")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(KLTheme.brandOrange)
                        .cornerRadius(6)
                }
                .padding(12)
                .background(
                    LinearGradient(colors: [Color.clear, Color.black.opacity(0.85)], startPoint: .top, endPoint: .bottom)
                )
            }
            .buttonStyle(.plain)
        }
        .onAppear {
            setupPlayer()
        }
        .onChange(of: channel) { _ in
            setupPlayer()
        }
        .onDisappear {
            player?.pause()
            player = nil
        }
    }

    private func setupPlayer() {
        Task {
            let resolved = await IptvService.shared.resolveStreamUrl(channel: channel)
            if let url = URL(string: resolved) {
                await MainActor.run {
                    self.player = AVPlayer(url: url)
                    self.player?.isMuted = true
                    self.player?.play()
                }
            }
        }
    }
}
