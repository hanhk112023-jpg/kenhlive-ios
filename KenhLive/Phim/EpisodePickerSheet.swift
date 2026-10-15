import SwiftUI
import AVFoundation

struct EpisodePickerSheet: View {
    let film: FilmItem
    var initialResumeProgress: WatchProgress? = nil
    var onSelectEpisode: ((EpisodeItem) -> Void)? = nil

    @Environment(\.dismiss) private var dismiss
    private let storage = StorageManager.shared

    @State private var isFavFilm: Bool = false
    @State private var detail: FilmDetailResult? = nil
    @State private var selectedServerIndex: Int = 0
    @State private var selectedChunkIndex: Int = 0
    @State private var isExpandedSynopsis: Bool = false
    @State private var isLoading: Bool = true

    // Inline Cinema Player State (Plays in 16:9 top header with zero forced full screen)
    @State private var activePlayingEpisode: EpisodeItem? = nil
    @State private var activeResumeSeconds: Double = 0
    @State private var isFullscreenPlayerPresented: Bool = false

    private let chunkSize = 30

    private var currentServer: EpisodeServer? {
        guard let servers = detail?.servers, selectedServerIndex < servers.count else { return nil }
        return servers[selectedServerIndex]
    }

    private var allCurrentEpisodes: [EpisodeItem] {
        currentServer?.episodes ?? []
    }

    private var totalChunks: Int {
        guard !allCurrentEpisodes.isEmpty else { return 0 }
        return (allCurrentEpisodes.count + chunkSize - 1) / chunkSize
    }

    private var visibleEpisodes: [EpisodeItem] {
        guard !allCurrentEpisodes.isEmpty else { return [] }
        let start = selectedChunkIndex * chunkSize
        guard start < allCurrentEpisodes.count else { return allCurrentEpisodes }
        let end = min(start + chunkSize, allCurrentEpisodes.count)
        return Array(allCurrentEpisodes[start..<end])
    }

    private var savedProgress: WatchProgress? {
        initialResumeProgress ?? storage.getProgress(for: film.slug)
    }

    var body: some View {
        ZStack {
            KLTheme.bgDeep.ignoresSafeArea()

            VStack(alignment: .leading, spacing: 0) {
                // Top Navigation Bar
                HStack {
                    Text(film.name)
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(.white)
                        .lineLimit(1)

                    Spacer()

                    Button {
                        KLHaptics.light()
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.white)
                            .padding(8)
                            .background(Color.white.opacity(0.12))
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)
                .padding(.bottom, 8)

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 14) {
                        // 1. Top Section: 16:9 Inline Player OR Cinema Poster Banner
                        if let activeEp = activePlayingEpisode {
                            let directUrl = activeEp.m3u8.isEmpty ? activeEp.embed : activeEp.m3u8
                            VStack(alignment: .leading, spacing: 6) {
                                HLSPlayerView(
                                    title: film.name,
                                    subtitle: "\(film.quality) · \(activeEp.name)",
                                    roomNum: nil,
                                    directUrl: directUrl,
                                    streamReferer: nil,
                                    room: nil,
                                    initialTimeSeconds: activeResumeSeconds,
                                    isFullscreen: false,
                                    onToggleFullscreen: {
                                        isFullscreenPlayerPresented = true
                                    },
                                    onClose: {
                                        activePlayingEpisode = nil
                                    },
                                    onProgressUpdate: { currentSec, durationSec in
                                        activeResumeSeconds = currentSec
                                        saveProgress(episode: activeEp, currentSec: currentSec, durationSec: durationSec)
                                    }
                                )
                                .id("inline-\(activeEp.slug)")
                                .frame(height: 220)
                                .cornerRadius(12)
                                .clipped()
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(KLTheme.borderSubtle, lineWidth: 0.8)
                                )

                                HStack {
                                    HStack(spacing: 5) {
                                        Circle()
                                            .fill(KLTheme.netflixGreen)
                                            .frame(width: 6, height: 6)
                                        Text("Đang phát: \(activeEp.name)")
                                            .font(.system(size: 11.5, weight: .bold))
                                            .foregroundColor(KLTheme.netflixGreen)
                                    }

                                    Spacer()

                                    Button {
                                        KLHaptics.medium()
                                        isFullscreenPlayerPresented = true
                                    } label: {
                                        HStack(spacing: 4) {
                                            Image(systemName: "arrow.up.left.and.arrow.down.right")
                                                .font(.system(size: 10, weight: .bold))
                                            Text("Toàn màn hình")
                                                .font(.system(size: 10.5, weight: .bold))
                                        }
                                        .foregroundColor(KLTheme.brandOrange)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(KLTheme.brandOrange.opacity(0.12))
                                        .cornerRadius(6)
                                    }
                                    .buttonStyle(.plain)
                                }
                                .padding(.horizontal, 2)
                            }
                        } else {
                            // Poster Thumbnail (2:3) & Metadata
                            renderPosterHeader()
                        }

                        // 2. Resume Watching Banner (If previous watch progress exists)
                        if let saved = savedProgress, activePlayingEpisode?.slug != saved.episodeSlug {
                            HStack(spacing: 10) {
                                Image(systemName: "clock.arrow.circlepath")
                                    .font(.system(size: 15, weight: .bold))
                                    .foregroundColor(KLTheme.brandOrange)

                                VStack(alignment: .leading, spacing: 1) {
                                    Text("Xem tiếp tập \(saved.episodeName)")
                                        .font(.system(size: 12.5, weight: .bold))
                                        .foregroundColor(.white)
                                    Text("Dừng tại \(formatTime(Double(saved.positionMs) / 1000.0))")
                                        .font(.system(size: 10.5, weight: .medium))
                                        .foregroundColor(KLTheme.textSecondary)
                                }

                                Spacer()

                                Button {
                                    resumeSavedProgress(saved)
                                } label: {
                                    Text("XEM TIẾP")
                                        .font(.system(size: 11, weight: .black))
                                        .foregroundColor(.black)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(KLTheme.brandOrange)
                                        .cornerRadius(6)
                                }
                                .buttonStyle(.plain)
                            }
                            .padding(10)
                            .background(KLTheme.brandOrange.opacity(0.10))
                            .cornerRadius(10)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(KLTheme.brandOrange.opacity(0.35), lineWidth: 0.8)
                            )
                        }

                        // 3. Synopsis & Cast Info
                        if let desc = detail?.description, !desc.isEmpty {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(desc)
                                    .font(.system(size: 12.5, weight: .regular))
                                    .foregroundColor(KLTheme.textSecondary)
                                    .lineLimit(isExpandedSynopsis ? nil : 3)
                                    .onTapGesture {
                                        withAnimation(.easeInOut(duration: 0.2)) {
                                            isExpandedSynopsis.toggle()
                                        }
                                    }

                                if let casts = detail?.casts, !casts.isEmpty, casts != "Đang cập nhật" {
                                    Text("Diễn viên: \(casts)")
                                        .font(.system(size: 11, weight: .medium))
                                        .foregroundColor(KLTheme.textMuted)
                                        .lineLimit(1)
                                }
                            }
                        }

                        Divider()
                            .background(KLTheme.borderSubtle)

                        // 4. Server Language Switcher Tabs
                        if let servers = detail?.servers, servers.count > 1 {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("NGUỒN PHÁT & NGÔN NGỮ")
                                    .font(.system(size: 10.5, weight: .heavy))
                                    .tracking(0.6)
                                    .foregroundColor(KLTheme.textMuted)

                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 8) {
                                        ForEach(Array(servers.enumerated()), id: \.offset) { index, srv in
                                            let isSelected = index == selectedServerIndex
                                            Button {
                                                KLHaptics.selection()
                                                selectedServerIndex = index
                                                selectedChunkIndex = 0
                                            } label: {
                                                HStack(spacing: 5) {
                                                    Circle()
                                                        .fill(isSelected ? KLTheme.netflixRed : Color.clear)
                                                        .frame(width: 5, height: 5)
                                                    Text(srv.serverName)
                                                        .font(.system(size: 11.5, weight: isSelected ? .bold : .medium))
                                                }
                                                .foregroundColor(isSelected ? .white : KLTheme.textSecondary)
                                                .padding(.horizontal, 12)
                                                .padding(.vertical, 7)
                                                .background(isSelected ? KLTheme.netflixRed.opacity(0.25) : KLTheme.surfaceCard)
                                                .cornerRadius(8)
                                                .overlay(
                                                    RoundedRectangle(cornerRadius: 8)
                                                        .stroke(isSelected ? KLTheme.netflixRed : KLTheme.borderSubtle, lineWidth: 0.8)
                                                )
                                            }
                                            .buttonStyle(.plain)
                                        }
                                    }
                                }
                            }
                        }

                        // 5. Episode Chunk Selector Strip (For long series > 30 episodes)
                        if totalChunks > 1 {
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Text("CHỌN NHÓM TẬP")
                                        .font(.system(size: 10.5, weight: .heavy))
                                        .tracking(0.6)
                                        .foregroundColor(KLTheme.textMuted)
                                    Spacer()
                                    Text("\(allCurrentEpisodes.count) TẬP")
                                        .font(.system(size: 10.5, weight: .bold, design: .monospaced))
                                        .foregroundColor(KLTheme.imdbGold)
                                }

                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 8) {
                                        ForEach(0..<totalChunks, id: \.self) { chunkIdx in
                                            let isSelected = chunkIdx == selectedChunkIndex
                                            let fromEp = chunkIdx * chunkSize + 1
                                            let toEp = min((chunkIdx + 1) * chunkSize, allCurrentEpisodes.count)

                                            Button {
                                                KLHaptics.selection()
                                                selectedChunkIndex = chunkIdx
                                            } label: {
                                                Text("Tập \(fromEp) - \(toEp)")
                                                    .font(.system(size: 11.5, weight: isSelected ? .bold : .medium))
                                                    .foregroundColor(isSelected ? .white : KLTheme.textSecondary)
                                                    .padding(.horizontal, 11)
                                                    .padding(.vertical, 6)
                                                    .background(isSelected ? Color.white.opacity(0.18) : KLTheme.surfaceCard)
                                                    .cornerRadius(7)
                                                    .overlay(
                                                        RoundedRectangle(cornerRadius: 7)
                                                            .stroke(isSelected ? Color.white : KLTheme.borderSubtle, lineWidth: 0.8)
                                                    )
                                            }
                                            .buttonStyle(.plain)
                                        }
                                    }
                                }
                            }
                        }

                        // 6. Episode Grid (3 Columns)
                        VStack(alignment: .leading, spacing: 8) {
                            Text("DANH SÁCH TẬP")
                                .font(.system(size: 10.5, weight: .heavy))
                                .tracking(0.6)
                                .foregroundColor(KLTheme.textMuted)

                            if isLoading {
                                HStack {
                                    Spacer()
                                    ProgressView().tint(KLTheme.netflixRed)
                                    Spacer()
                                }
                                .padding(.vertical, 30)
                            } else if visibleEpisodes.isEmpty {
                                Text("Chưa có tập phim nào")
                                    .font(.system(size: 12))
                                    .foregroundColor(KLTheme.textMuted)
                                    .padding(.vertical, 20)
                            } else {
                                LazyVGrid(columns: [
                                    GridItem(.flexible(), spacing: 10),
                                    GridItem(.flexible(), spacing: 10),
                                    GridItem(.flexible(), spacing: 10)
                                ], spacing: 10) {
                                    ForEach(visibleEpisodes) { ep in
                                        let isCurrentlyPlaying = activePlayingEpisode?.slug == ep.slug
                                        let isWatched = storage.watchHistory.contains {
                                            $0.filmSlug == film.slug && $0.episodeSlug == ep.slug
                                        }

                                        Button {
                                            KLHaptics.medium()
                                            startPlaying(episode: ep, resumeSeconds: 0)
                                        } label: {
                                            HStack(spacing: 4) {
                                                Image(systemName: isCurrentlyPlaying ? "waveform" : (isWatched ? "checkmark.circle.fill" : "play.fill"))
                                                    .font(.system(size: 9.5, weight: .bold))
                                                    .foregroundColor(isCurrentlyPlaying ? KLTheme.brandOrange : (isWatched ? KLTheme.netflixGreen : KLTheme.netflixRed))

                                                Text(ep.name)
                                                    .font(.system(size: 12, weight: isCurrentlyPlaying ? .black : .bold))
                                                    .foregroundColor(isCurrentlyPlaying ? KLTheme.brandOrange : .white)
                                                    .lineLimit(1)
                                            }
                                            .frame(maxWidth: .infinity)
                                            .padding(.vertical, 11)
                                            .background(isCurrentlyPlaying ? KLTheme.brandOrange.opacity(0.18) : (isWatched ? KLTheme.netflixRed.opacity(0.14) : KLTheme.surfaceCard))
                                            .cornerRadius(9)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 9)
                                                    .stroke(isCurrentlyPlaying ? KLTheme.brandOrange : (isWatched ? KLTheme.netflixRed.opacity(0.4) : KLTheme.borderSubtle), lineWidth: isCurrentlyPlaying ? 1.5 : 0.8)
                                            )
                                        }
                                        .buttonStyle(KLScaleButtonStyle())
                                    }
                                }
                            }
                        }
                    }
                    .padding(16)
                    .padding(.bottom, 40)
                }
            }
        }
        .task {
            isFavFilm = storage.isFavoriteFilm(slug: film.slug)
            isLoading = true
            let d = await PhimService.shared.fetchFilmDetail(slug: film.slug)
            self.detail = d
            isLoading = false

            // Auto-detect resume progress if passed
            if let saved = savedProgress {
                if let ep = findEpisode(for: saved, in: d.servers) {
                    self.activeResumeSeconds = Double(saved.positionMs) / 1000.0
                    // If tapped directly from Continue Watching, auto-start in 16:9 player
                    if initialResumeProgress != nil {
                        self.activePlayingEpisode = ep
                    }
                }
            }
        }
        .fullScreenCover(isPresented: $isFullscreenPlayerPresented) {
            if let activeEp = activePlayingEpisode {
                let directUrl = activeEp.m3u8.isEmpty ? activeEp.embed : activeEp.m3u8
                HLSPlayerView(
                    title: film.name,
                    subtitle: "\(film.quality) · \(activeEp.name)",
                    roomNum: nil,
                    directUrl: directUrl,
                    streamReferer: nil,
                    room: nil,
                    initialTimeSeconds: activeResumeSeconds,
                    isFullscreen: true,
                    onToggleFullscreen: {
                        isFullscreenPlayerPresented = false
                    },
                    onClose: {
                        isFullscreenPlayerPresented = false
                    },
                    onProgressUpdate: { currentSec, durationSec in
                        activeResumeSeconds = currentSec
                        saveProgress(episode: activeEp, currentSec: currentSec, durationSec: durationSec)
                    }
                )
                .id("fullscreen-\(activeEp.slug)")
            }
        }
    }

    // MARK: - Poster Header View
    @ViewBuilder
    private func renderPosterHeader() -> some View {
        HStack(alignment: .top, spacing: 14) {
            // Poster Thumbnail (2:3)
            AsyncImage(url: URL(string: film.posterUrl.isEmpty ? film.thumbUrl : film.posterUrl)) { phase in
                if let image = phase.image {
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } else {
                    ZStack {
                        KLTheme.surfaceCard
                        Image(systemName: "film")
                            .font(.system(size: 24))
                            .foregroundColor(KLTheme.textMuted)
                    }
                }
            }
            .frame(width: 92, height: 136)
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(KLTheme.borderSubtle, lineWidth: 0.8)
            )
            .clipped()

            VStack(alignment: .leading, spacing: 6) {
                // Badges Row
                HStack(spacing: 5) {
                    KLPillBadge(
                        text: "★ \(film.imdbScore)",
                        fg: .black,
                        bg: KLTheme.imdbGold,
                        border: .clear
                    )
                    KLPillBadge(
                        text: film.quality,
                        fg: .white,
                        bg: KLTheme.netflixRed,
                        border: .clear
                    )
                    KLPillBadge(
                        text: film.year,
                        fg: KLTheme.textSecondary,
                        bg: Color.white.opacity(0.08),
                        border: .clear
                    )
                }

                Text(film.name)
                    .font(.system(size: 18, weight: .heavy))
                    .foregroundColor(.white)
                    .lineLimit(2)

                if !film.originalName.isEmpty {
                    Text(film.originalName)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(KLTheme.textMuted)
                        .lineLimit(1)
                }

                let timeText = !(detail?.time ?? "").isEmpty ? (detail?.time ?? "") : film.currentEpisode
                let countryText = !(detail?.country ?? "").isEmpty ? (detail?.country ?? "") : film.language
                Text("\(timeText) · \(countryText)")
                    .font(.system(size: 11.5, weight: .semibold))
                    .foregroundColor(KLTheme.netflixGreen)

                // Quick Action Buttons
                HStack(spacing: 8) {
                    Button {
                        if let first = allCurrentEpisodes.first {
                            KLHaptics.medium()
                            startPlaying(episode: first, resumeSeconds: 0)
                        }
                    } label: {
                        HStack(spacing: 5) {
                            Image(systemName: "play.fill")
                                .font(.system(size: 11, weight: .bold))
                            Text("PHÁT TẬP 1")
                                .font(.system(size: 11.5, weight: .black))
                        }
                        .foregroundColor(.black)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(Color.white)
                        .cornerRadius(7)
                    }
                    .disabled(allCurrentEpisodes.isEmpty)

                    Button {
                        KLHaptics.selection()
                        storage.toggleFavoriteFilm(slug: film.slug)
                        isFavFilm.toggle()
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: isFavFilm ? "checkmark" : "plus")
                                .font(.system(size: 11, weight: .bold))
                            Text(isFavFilm ? "ĐÃ LƯU" : "DANH SÁCH")
                                .font(.system(size: 11, weight: .bold))
                        }
                        .foregroundColor(isFavFilm ? KLTheme.imdbGold : .white)
                        .padding(.horizontal, 11)
                        .padding(.vertical, 8)
                        .background(Color.white.opacity(0.10))
                        .cornerRadius(7)
                    }
                }
                .padding(.top, 2)
            }
        }
    }

    // MARK: - Actions & Helpers
    private func startPlaying(episode: EpisodeItem, resumeSeconds: Double) {
        self.activePlayingEpisode = episode
        self.activeResumeSeconds = resumeSeconds
        self.onSelectEpisode?(episode)
        saveProgress(episode: episode, currentSec: resumeSeconds, durationSec: 2700)
    }

    private func resumeSavedProgress(_ saved: WatchProgress) {
        KLHaptics.medium()
        if let ep = findEpisode(for: saved, in: detail?.servers ?? []) {
            startPlaying(episode: ep, resumeSeconds: Double(saved.positionMs) / 1000.0)
        } else if let first = allCurrentEpisodes.first {
            startPlaying(episode: first, resumeSeconds: Double(saved.positionMs) / 1000.0)
        }
    }

    private func findEpisode(for progress: WatchProgress, in servers: [EpisodeServer]) -> EpisodeItem? {
        for srv in servers {
            if let found = srv.episodes.first(where: { $0.slug == progress.episodeSlug || $0.name == progress.episodeName }) {
                return found
            }
        }
        return nil
    }

    private func saveProgress(episode: EpisodeItem, currentSec: Double, durationSec: Double) {
        let posMs = Int64(currentSec * 1000)
        let durMs = Int64(durationSec * 1000)
        let progress = WatchProgress(
            filmSlug: film.slug,
            filmName: film.name,
            posterUrl: film.posterUrl.isEmpty ? film.thumbUrl : film.posterUrl,
            episodeName: episode.name,
            episodeSlug: episode.slug,
            embedUrl: episode.embed,
            m3u8Url: episode.m3u8,
            positionMs: posMs,
            durationMs: durMs > 0 ? durMs : 45 * 60 * 1000,
            updatedAt: Date()
        )
        storage.saveWatchProgress(progress)
    }

    private func formatTime(_ seconds: Double) -> String {
        guard !seconds.isNaN && !seconds.isInfinite else { return "00:00" }
        let total = Int(seconds)
        let m = total / 60
        let s = total % 60
        let h = total / 3600
        if h > 0 {
            return String(format: "%02d:%02d:%02d", h, m % 60, s)
        } else {
            return String(format: "%02d:%02d", m, s)
        }
    }
}
