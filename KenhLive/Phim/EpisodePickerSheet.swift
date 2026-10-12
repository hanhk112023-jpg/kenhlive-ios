import SwiftUI

struct EpisodePickerSheet: View {
    let film: FilmItem
    let onSelectEpisode: (EpisodeItem) -> Void
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var storage = StorageManager.shared

    @State private var detail: FilmDetailResult? = nil
    @State private var selectedServerIndex: Int = 0
    @State private var selectedChunkIndex: Int = 0
    @State private var isExpandedSynopsis: Bool = false
    @State private var isLoading: Bool = true

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

    var body: some View {
        ZStack {
            KLTheme.bgDeep.ignoresSafeArea()

            VStack(alignment: .leading, spacing: 0) {
                // 1. Top Film Metadata Header with Poster
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 14) {
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
                                            dismiss()
                                            onSelectEpisode(first)
                                        }
                                    } label: {
                                        HStack(spacing: 5) {
                                            Image(systemName: "play.fill")
                                                .font(.system(size: 11, weight: .bold))
                                            Text("PHÁT NGAY")
                                                .font(.system(size: 11.5, weight: .black))
                                        }
                                        .foregroundColor(.black)
                                        .padding(.horizontal, 14)
                                        .padding(.vertical, 8)
                                        .background(Color.white)
                                        .cornerRadius(7)
                                    }
                                    .disabled(allCurrentEpisodes.isEmpty)

                                    let isFav = storage.isFavoriteFilm(slug: film.slug)
                                    Button {
                                        KLHaptics.selection()
                                        storage.toggleFavoriteFilm(slug: film.slug)
                                    } label: {
                                        HStack(spacing: 4) {
                                            Image(systemName: isFav ? "checkmark" : "plus")
                                                .font(.system(size: 11, weight: .bold))
                                            Text(isFav ? "ĐÃ LƯU" : "DANH SÁCH")
                                                .font(.system(size: 11, weight: .bold))
                                        }
                                        .foregroundColor(isFav ? KLTheme.imdbGold : .white)
                                        .padding(.horizontal, 11)
                                        .padding(.vertical, 8)
                                        .background(Color.white.opacity(0.10))
                                        .cornerRadius(7)
                                    }
                                }
                                .padding(.top, 2)
                            }
                        }

                        // Synopsis & Cast Info
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

                        if isLoading {
                            HStack {
                                Spacer()
                                VStack(spacing: 10) {
                                    ProgressView()
                                        .tint(KLTheme.netflixRed)
                                    Text("Đang tải danh sách tập phim...")
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundColor(KLTheme.textMuted)
                                }
                                .padding(.vertical, 40)
                                Spacer()
                            }
                        } else {
                            // 2. Server Switcher Tabs (Vietsub / Thuyết Minh / Lồng Tiếng)
                            if let servers = detail?.servers, servers.count > 1 {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("CHỌN NGÔN NGỮ / MÁY CHỦ")
                                        .font(.system(size: 10.5, weight: .heavy))
                                        .tracking(0.8)
                                        .foregroundColor(KLTheme.textMuted)

                                    ScrollView(.horizontal, showsIndicators: false) {
                                        HStack(spacing: 8) {
                                            ForEach(Array(servers.enumerated()), id: \.offset) { idx, srv in
                                                let active = selectedServerIndex == idx
                                                Button {
                                                    KLHaptics.selection()
                                                    selectedServerIndex = idx
                                                    selectedChunkIndex = 0
                                                } label: {
                                                    HStack(spacing: 5) {
                                                        Image(systemName: "waveform")
                                                            .font(.system(size: 10, weight: .bold))
                                                        Text("\(srv.serverName) (\(srv.episodes.count) tập)")
                                                            .font(.system(size: 12, weight: .bold))
                                                    }
                                                    .foregroundColor(active ? .white : KLTheme.textSecondary)
                                                    .padding(.horizontal, 12)
                                                    .padding(.vertical, 7)
                                                    .background(active ? KLTheme.netflixRed : KLTheme.surfaceCard)
                                                    .cornerRadius(8)
                                                }
                                                .buttonStyle(.plain)
                                            }
                                        }
                                    }
                                }
                            }

                            // 3. Episode Range Chunk Picker (e.g. 1-30, 31-60 for long series)
                            if totalChunks > 1 {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("CHỌN KHOẢNG TẬP (\(allCurrentEpisodes.count) TẬP)")
                                        .font(.system(size: 10.5, weight: .heavy))
                                        .tracking(0.8)
                                        .foregroundColor(KLTheme.textMuted)

                                    ScrollView(.horizontal, showsIndicators: false) {
                                        HStack(spacing: 8) {
                                            ForEach(0..<totalChunks, id: \.self) { chunkIdx in
                                                let startNum = chunkIdx * chunkSize + 1
                                                let endNum = min((chunkIdx + 1) * chunkSize, allCurrentEpisodes.count)
                                                let active = selectedChunkIndex == chunkIdx

                                                Button {
                                                    KLHaptics.selection()
                                                    selectedChunkIndex = chunkIdx
                                                } label: {
                                                    Text("Tập \(startNum) - \(endNum)")
                                                        .font(.system(size: 11.5, weight: .bold, design: .monospaced))
                                                        .foregroundColor(active ? .black : KLTheme.textSecondary)
                                                        .padding(.horizontal, 11)
                                                        .padding(.vertical, 6)
                                                        .background(active ? KLTheme.imdbGold : KLTheme.surfaceCard)
                                                        .cornerRadius(7)
                                                }
                                                .buttonStyle(.plain)
                                            }
                                        }
                                    }
                                }
                            } else {
                                Text("DANH SÁCH TẬP PHIM (\(allCurrentEpisodes.count))")
                                    .font(.system(size: 10.5, weight: .heavy))
                                    .tracking(0.8)
                                    .foregroundColor(KLTheme.textMuted)
                            }

                            // 4. Episode Grid (3 Columns)
                            LazyVGrid(columns: [
                                GridItem(.flexible(), spacing: 10),
                                GridItem(.flexible(), spacing: 10),
                                GridItem(.flexible(), spacing: 10)
                            ], spacing: 10) {
                                ForEach(visibleEpisodes) { ep in
                                    let isWatched = storage.watchHistory.contains {
                                        $0.filmSlug == film.slug && $0.episodeSlug == ep.slug
                                    }

                                    Button {
                                        KLHaptics.medium()
                                        dismiss()
                                        onSelectEpisode(ep)
                                    } label: {
                                        HStack(spacing: 4) {
                                            Image(systemName: isWatched ? "checkmark.circle.fill" : "play.fill")
                                                .font(.system(size: 10, weight: .bold))
                                                .foregroundColor(isWatched ? KLTheme.netflixGreen : KLTheme.netflixRed)

                                            Text(ep.name)
                                                .font(.system(size: 12.5, weight: .bold))
                                                .foregroundColor(.white)
                                                .lineLimit(1)
                                        }
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 11)
                                        .background(isWatched ? KLTheme.netflixRed.opacity(0.16) : KLTheme.surfaceCard)
                                        .cornerRadius(9)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 9)
                                                .stroke(isWatched ? KLTheme.netflixRed.opacity(0.5) : KLTheme.borderSubtle, lineWidth: 0.8)
                                        )
                                    }
                                    .buttonStyle(KLScaleButtonStyle())
                                }
                            }
                        }
                    }
                    .padding(16)
                }
            }
        }
        .task {
            isLoading = true
            detail = await PhimService.shared.fetchFilmDetail(slug: film.slug)
            isLoading = false
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }
}
