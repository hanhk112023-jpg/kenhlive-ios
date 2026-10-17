import SwiftUI
import AVKit

struct IptvView: View {
    var isActive: Bool = true
    @ObservedObject private var storage = StorageManager.shared
    @State private var categories: [IptvCategory] = []
    @State private var selectedCategory: String = "VTV Quốc Gia"
    @State private var previewChannel: IptvChannel? = nil
    @State private var activeChannelForPlayer: IptvChannel? = nil
    @State private var isLoading: Bool = true

    private var allChannelsList: [IptvChannel] {
        categories.flatMap { $0.channels }
    }

    private var favoriteChannels: [IptvChannel] {
        let favs = allChannelsList.filter { storage.isFavoriteChannel(id: $0.channelId) }
        return Array(Dictionary(grouping: favs, by: { $0.channelId }).values.compactMap { $0.first })
    }

    private var currentCategoryChannels: [IptvChannel] {
        if selectedCategory == "⭐ Yêu Thích" {
            return favoriteChannels
        } else if selectedCategory == "Tất Cả" {
            return allChannelsList
        } else {
            return categories.first(where: { $0.name == selectedCategory })?.channels ?? []
        }
    }

    private var categoryTabs: [KLFilterItem<String>] {
        var tabs: [KLFilterItem<String>] = []
        if !favoriteChannels.isEmpty {
            tabs.append(KLFilterItem(id: "⭐ Yêu Thích", title: "⭐ Yêu Thích", badge: "\(favoriteChannels.count)"))
        }
        tabs.append(contentsOf: categories.map {
            KLFilterItem(id: $0.name, title: $0.name, badge: "\($0.channels.count)")
        })
        return tabs
    }

    var body: some View {
        ZStack {
            KLTheme.bgDeep.ignoresSafeArea()

            VStack(spacing: 0) {
                // 1. Editorial Header Bar
                renderHeaderBar()

                // 2. Inline 16:9 Muted Preview Player
                if let preview = previewChannel {
                    InlinePreviewPlayerView(
                        channel: preview,
                        isFullscreenActive: activeChannelForPlayer != nil,
                        isActive: isActive,
                        onExpandFullscreen: {
                            activeChannelForPlayer = preview
                        }
                    )
                    .frame(height: 195)
                    .cornerRadius(14)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 12)
                }

                // 4. Category Filter Strip
                if !categoryTabs.isEmpty {
                    KLFilterStrip(items: categoryTabs, selection: $selectedCategory)
                        .padding(.bottom, 10)
                }

                // 5. Channel Grid (2 Columns on iPhone)
                ScrollView(showsIndicators: false) {
                    if currentCategoryChannels.isEmpty {
                        VStack(spacing: 12) {
                            Image(systemName: "tv.slash")
                                .font(.system(size: 34))
                                .foregroundColor(KLTheme.textMuted)

                            Text("Không có kênh truyền hình phù hợp")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(KLTheme.textSecondary)

                            if selectedCategory == "⭐ Yêu Thích" {
                                Text("Chạm vào biểu tượng ngôi sao ở mỗi kênh để lưu vào danh sách yêu thích.")
                                    .font(.system(size: 11.5, weight: .regular))
                                    .foregroundColor(KLTheme.textMuted)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal, 40)
                            }
                        }
                        .padding(.top, 40)
                    } else {
                        LazyVGrid(columns: [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)], spacing: 10) {
                            ForEach(currentCategoryChannels) { channel in
                                renderChannelCard(channel: channel)
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.bottom, 90)
                    }
                }
            }

            if isLoading && categories.isEmpty {
                ProgressView()
                    .tint(KLTheme.brandOrange)
                    .scaleEffect(1.3)
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
        .onDisappear {
            previewChannel = nil
        }
    }

    // MARK: - Header Bar
    @ViewBuilder
    private func renderHeaderBar() -> some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 5) {
                    Text("TRUYỀN HÌNH VIỆT NAM & QUỐC TẾ")
                        .font(.system(size: 10, weight: .black, design: .rounded))
                        .tracking(1.4)
                        .foregroundColor(KLTheme.accentCyan)

                    Circle()
                        .fill(KLTheme.accentCyan)
                        .frame(width: 5, height: 5)
                }

                Text("Kênh TV Trực Tuyến")
                    .font(.system(size: 22, weight: .heavy, design: .rounded))
                    .foregroundColor(.white)
            }

            Spacer()

            if let preview = previewChannel {
                HStack(spacing: 5) {
                    Circle()
                        .fill(KLTheme.liveRed)
                        .frame(width: 5, height: 5)
                    Text(preview.name)
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(KLTheme.textSecondary)
                        .lineLimit(1)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(KLTheme.surfaceCard)
                .cornerRadius(6)
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 4)
        .padding(.bottom, 10)
    }

    // MARK: - Channel Card
    @ViewBuilder
    private func renderChannelCard(channel: IptvChannel) -> some View {
        let isFav = storage.isFavoriteChannel(id: channel.channelId)
        let isCurrentPreview = previewChannel?.channelId == channel.channelId

        Button {
            KLHaptics.selection()
            if isCurrentPreview {
                activeChannelForPlayer = channel
            } else {
                previewChannel = channel
            }
        } label: {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    KLLivePulseBadge(text: "LIVE", color: KLTheme.liveRed)

                    Spacer()

                    Text(channel.resolution.isEmpty ? "FHD" : channel.resolution)
                        .font(.system(size: 8.5, weight: .black, design: .rounded))
                        .foregroundColor(KLTheme.accentCyan)
                        .padding(.horizontal, 5)
                        .padding(.vertical, 2)
                        .background(KLTheme.accentCyan.opacity(0.14))
                        .cornerRadius(4)

                    // Favorite Button
                    Button {
                        KLHaptics.selection()
                        storage.toggleFavoriteChannel(id: channel.channelId)
                    } label: {
                        Image(systemName: isFav ? "star.fill" : "star")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(isFav ? KLTheme.imdbGold : KLTheme.textMuted)
                            .padding(2)
                    }
                    .buttonStyle(.plain)
                }

                Text(channel.name)
                    .font(.system(size: 14.5, weight: .bold))
                    .foregroundColor(.white)
                    .lineLimit(1)

                HStack {
                    Text(channel.group.uppercased())
                        .font(.system(size: 9.5, weight: .medium, design: .monospaced))
                        .foregroundColor(KLTheme.textMuted)
                        .lineLimit(1)

                    Spacer()

                    HStack(spacing: 3) {
                        Text(isCurrentPreview ? "PHÁT" : "XEM")
                            .font(.system(size: 9.5, weight: .bold))
                        Image(systemName: isCurrentPreview ? "play.circle.fill" : "play.fill")
                            .font(.system(size: 8.5, weight: .bold))
                    }
                    .foregroundColor(isCurrentPreview ? KLTheme.brandOrange : KLTheme.textSecondary)
                }
            }
            .padding(12)
            .background(isCurrentPreview ? KLTheme.brandOrange.opacity(0.12) : KLTheme.surfaceCard)
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(isCurrentPreview ? KLTheme.brandOrange : KLTheme.borderSubtle, lineWidth: isCurrentPreview ? 1.5 : 0.8)
            )
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .buttonStyle(KLScaleButtonStyle())
        .contextMenu {
            Button {
                activeChannelForPlayer = channel
            } label: {
                Label("Phát toàn màn hình", systemImage: "arrow.up.left.and.arrow.down.right")
            }

            Button {
                storage.toggleFavoriteChannel(id: channel.channelId)
            } label: {
                Label(isFav ? "Bỏ lưu kênh yêu thích" : "Lưu vào kênh yêu thích", systemImage: isFav ? "star.slash" : "star.fill")
            }
        }
    }
}

// MARK: - Inline Preview Player
private struct InlinePreviewPlayerView: View {
    let channel: IptvChannel
    let isFullscreenActive: Bool
    let isActive: Bool
    let onExpandFullscreen: () -> Void

    @State private var player: AVPlayer? = nil
    @State private var isMuted: Bool = true // Always muted by default on iOS preview
    @State private var setupTask: Task<Void, Never>? = nil

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

                    HStack(spacing: 4) {
                        Image(systemName: "arrow.up.left.and.arrow.down.right")
                            .font(.system(size: 10, weight: .bold))
                        Text("PHÓNG TO")
                            .font(.system(size: 10.5, weight: .bold))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 11)
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

            // Mute / Unmute Floating Toggle Button (Top Right)
            VStack {
                HStack {
                    Spacer()
                    Button {
                        KLHaptics.light()
                        isMuted.toggle()
                        player?.isMuted = isMuted
                    } label: {
                        Image(systemName: isMuted ? "speaker.slash.fill" : "speaker.wave.2.fill")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.white)
                            .padding(8)
                            .background(Color.black.opacity(0.65))
                            .clipShape(Circle())
                    }
                    .padding(8)
                }
                Spacer()
            }
        }
        .onAppear {
            if !isFullscreenActive {
                setupPlayer()
            }
        }
        .onChange(of: channel) { _ in
            if !isFullscreenActive {
                setupPlayer()
            }
        }
        .onChange(of: isFullscreenActive) { active in
            if active {
                // Instantly pause and silence preview when fullscreen is active
                player?.pause()
            } else if isActive {
                // Resume preview (remains muted) when fullscreen is dismissed
                player?.isMuted = isMuted
                player?.play()
            }
        }
        .onChange(of: isActive) { active in
            if !active {
                player?.pause()
            } else if !isFullscreenActive {
                player?.isMuted = isMuted
                player?.play()
            }
        }
        .onDisappear {
            setupTask?.cancel()
            setupTask = nil
            player?.pause()
            player = nil
        }
    }

    private func setupPlayer() {
        setupTask?.cancel()
        setupTask = Task {
            let resolved = await IptvService.shared.resolveStreamUrl(channel: channel)
            guard !Task.isCancelled, let url = URL(string: resolved) else { return }
            await MainActor.run {
                guard !Task.isCancelled else { return }
                self.player?.pause()
                let newPlayer = AVPlayer(url: url)
                newPlayer.isMuted = self.isMuted
                self.player = newPlayer
                if !self.isFullscreenActive {
                    self.player?.play()
                }
            }
        }
    }
}
