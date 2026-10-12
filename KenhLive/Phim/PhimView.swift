import SwiftUI

struct PhimView: View {
    @ObservedObject private var storage = StorageManager.shared
    @State private var selectedFilter: String = "tat-ca"
    @State private var sections: [PhimSection] = []
    @State private var featuredFilms: [FilmItem] = []
    @State private var heroIndex: Int = 0
    @State private var heroSynopsis: String = ""
    @State private var isLoading: Bool = true

    @State private var selectedFilmForEpisodes: FilmItem? = nil
    @State private var activePlayback: ActiveVodPlayback? = nil

    struct ActiveVodPlayback: Identifiable {
        let id = UUID()
        let film: FilmItem
        let episode: EpisodeItem
    }

    private let filterPills: [KLFilterItem<String>] = [
        KLFilterItem(id: "tat-ca", title: "Trang Chủ Phim"),
        KLFilterItem(id: "lich-su", title: "Danh Sách Của Tôi"),
        KLFilterItem(id: "phim-moi", title: "Mới Cập Nhật"),
        KLFilterItem(id: "phim-bo", title: "Phim Bộ"),
        KLFilterItem(id: "phim-le", title: "Phim Lẻ"),
        KLFilterItem(id: "hoat-hinh", title: "Hoạt Hình & Anime"),
        KLFilterItem(id: "hanh-dong", title: "Hành Động"),
        KLFilterItem(id: "tinh-cam", title: "Tình Cảm"),
        KLFilterItem(id: "co-trang", title: "Cổ Trang"),
        KLFilterItem(id: "kinh-di", title: "Kinh Dị")
    ]

    private var currentHero: FilmItem? {
        guard !featuredFilms.isEmpty else { return sections.first?.films.first }
        return featuredFilms[heroIndex % featuredFilms.count]
    }

    var body: some View {
        ZStack {
            KLTheme.bgDeep.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 20) {
                    // 1. Netflix Editorial Header
                    HStack(alignment: .center) {
                        HStack(spacing: 8) {
                            Text("K")
                                .font(.system(size: 16, weight: .black, design: .rounded))
                                .foregroundColor(.white)
                                .frame(width: 24, height: 24)
                                .background(KLTheme.netflixRed)
                                .cornerRadius(5)

                            VStack(alignment: .leading, spacing: 1) {
                                Text("RẠP PHIM ĐIỆN ẢNH")
                                    .font(.system(size: 10, weight: .black, design: .rounded))
                                    .tracking(1.6)
                                    .foregroundColor(KLTheme.netflixRed)

                                Text("Kho Phim Netflix Cinema")
                                    .font(.system(size: 22, weight: .heavy))
                                    .foregroundColor(.white)
                            }
                        }

                        Spacer()

                        KLPillBadge(
                            text: "4K · VIETSUB",
                            fg: KLTheme.imdbGold,
                            bg: KLTheme.imdbGold.opacity(0.14),
                            border: KLTheme.imdbGold.opacity(0.4)
                        )
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 10)

                    // 2. Category Filter Strip
                    KLFilterStrip(items: filterPills, selection: $selectedFilter)
                        .onChange(of: selectedFilter) { newCat in
                            Task { await loadCategory(newCat) }
                        }

                    // 3. Netflix Cinema Billboard Hero
                    if let hero = currentHero {
                        NetflixBillboardHeroCard(
                            film: hero,
                            synopsis: heroSynopsis,
                            currentIndex: heroIndex,
                            totalCount: max(1, featuredFilms.count),
                            isFavorite: storage.isFavoriteFilm(slug: hero.slug),
                            onPlayNow: {
                                KLHaptics.medium()
                                Task {
                                    let detail = await PhimService.shared.fetchFilmDetail(slug: hero.slug)
                                    if let firstEp = detail.episodes.first {
                                        activePlayback = ActiveVodPlayback(film: hero, episode: firstEp)
                                    }
                                }
                            },
                            onOpenEpisodes: {
                                KLHaptics.light()
                                selectedFilmForEpisodes = hero
                            },
                            onToggleFavorite: {
                                KLHaptics.selection()
                                storage.toggleFavoriteFilm(slug: hero.slug)
                            },
                            onCycleNext: {
                                KLHaptics.light()
                                if featuredFilms.count > 1 {
                                    withAnimation(.spring(response: 0.32, dampingFraction: 0.82)) {
                                        heroIndex = (heroIndex + 1) % featuredFilms.count
                                    }
                                    Task { await loadHeroSynopsis() }
                                }
                            }
                        )
                    }

                    // 4. Continue Watching Rail (Netflix Red Progress)
                    if !storage.watchHistory.isEmpty && (selectedFilter == "tat-ca" || selectedFilter == "lich-su") {
                        ContinueWatchingRail(items: storage.watchHistory) { item in
                            KLHaptics.medium()
                            let film = FilmItem(
                                name: item.filmName,
                                slug: item.filmSlug,
                                thumbUrl: item.posterUrl,
                                posterUrl: item.posterUrl
                            )
                            let ep = EpisodeItem(name: item.episodeName, slug: item.episodeSlug, embed: item.embedUrl)
                            activePlayback = ActiveVodPlayback(film: film, episode: ep)
                        }
                    }

                    // 5. Film Catalog Sections (2:3 Netflix Posters)
                    ForEach(sections) { section in
                        FilmSectionRow(
                            title: section.title,
                            films: section.films,
                            watchHistory: storage.watchHistory,
                            onSelectFilm: { film in
                                KLHaptics.light()
                                selectedFilmForEpisodes = film
                            },
                            onSeeMore: {
                                KLHaptics.selection()
                                if section.title.contains("Mới") { selectedFilter = "phim-moi" }
                                else if section.title.contains("Bộ") { selectedFilter = "phim-bo" }
                                else if section.title.contains("Lẻ") { selectedFilter = "phim-le" }
                                else if section.title.contains("Hoạt Hình") { selectedFilter = "hoat-hinh" }
                                else if section.title.contains("Hành Động") { selectedFilter = "hanh-dong" }
                                else if section.title.contains("Tình Cảm") { selectedFilter = "tinh-cam" }
                                else if section.title.contains("Cổ Trang") { selectedFilter = "co-trang" }
                                else if section.title.contains("Kinh Dị") { selectedFilter = "kinh-di" }
                            }
                        )
                    }

                    Spacer(minLength: 90)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .refreshable {
                await loadCategory(selectedFilter)
            }

            if isLoading && sections.isEmpty {
                ProgressView()
                    .tint(KLTheme.netflixRed)
            }
        }
        .task {
            if sections.isEmpty {
                await loadCategory(selectedFilter)
            }
        }
        .sheet(item: $selectedFilmForEpisodes) { film in
            EpisodePickerSheet(film: film) { ep in
                activePlayback = ActiveVodPlayback(film: film, episode: ep)
            }
        }
        .fullScreenCover(item: $activePlayback) { item in
            VodWebPlayerView(film: item.film, episode: item.episode)
        }
    }

    private func loadCategory(_ slug: String) async {
        isLoading = true
        if slug == "tat-ca" {
            let home = await PhimService.shared.fetchHomeSections()
            sections = home
            featuredFilms = Array((home.first?.films ?? []).prefix(8))
            heroIndex = 0
            await loadHeroSynopsis()
        } else if slug == "lich-su" {
            let favSlugs = storage.favoriteFilmSlugs
            let allLoaded = sections.flatMap { $0.films }
            let favFilms = allLoaded.filter { favSlugs.contains($0.slug) }
            if !favFilms.isEmpty {
                sections = [PhimSection(title: "Phim Đã Lưu Trong Danh Sách", films: favFilms)]
            }
        } else {
            let list = await PhimService.shared.fetchCategoryFilms(slug: slug)
            let catTitle = filterPills.first(where: { $0.id == slug })?.title ?? "Danh Mục Phim"
            sections = [PhimSection(title: catTitle, films: list)]
            featuredFilms = Array(list.prefix(8))
            heroIndex = 0
            await loadHeroSynopsis()
        }
        isLoading = false
    }

    private func loadHeroSynopsis() async {
        guard let hero = currentHero else { return }
        heroSynopsis = hero.description ?? ""
        let detail = await PhimService.shared.fetchFilmDetail(slug: hero.slug)
        if !detail.description.isEmpty {
            heroSynopsis = detail.description
        }
    }
}

// MARK: - Netflix Cinema Billboard Hero Card (Synchronized with TV v7.4.3)
private struct NetflixBillboardHeroCard: View {
    let film: FilmItem
    let synopsis: String
    let currentIndex: Int
    let totalCount: Int
    let isFavorite: Bool
    let onPlayNow: () -> Void
    let onOpenEpisodes: () -> Void
    let onToggleFavorite: () -> Void
    let onCycleNext: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Spacer(minLength: 48)

            // Row 1: Netflix Series Brand Identifier + Index
            HStack(spacing: 7) {
                Text("K")
                    .font(.system(size: 11, weight: .black, design: .rounded))
                    .foregroundColor(.white)
                    .padding(.horizontal, 5)
                    .padding(.vertical, 2)
                    .background(KLTheme.netflixRed)
                    .cornerRadius(3)

                Text("B O M  T Ấ N  Đ I Ệ N  Ả N H")
                    .font(.system(size: 9.5, weight: .heavy, design: .rounded))
                    .foregroundColor(Color.white.opacity(0.85))

                Spacer()

                if totalCount > 1 {
                    Text("\(currentIndex + 1)/\(totalCount)")
                        .font(.system(size: 10.5, weight: .bold, design: .monospaced))
                        .foregroundColor(KLTheme.textSecondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Color.black.opacity(0.65))
                        .cornerRadius(5)
                }
            }

            // Row 2: Dramatic Movie Title
            Text(film.name)
                .font(.system(size: 24, weight: .black))
                .foregroundColor(.white)
                .lineLimit(2)
                .shadow(color: .black.opacity(0.9), radius: 6, x: 0, y: 2)

            // Row 3: Netflix Metadata Bar (98% Match · Year · 16+ · Quality · IMDb)
            HStack(spacing: 8) {
                Text("98% Phù Hợp")
                    .font(.system(size: 12, weight: .heavy))
                    .foregroundColor(KLTheme.netflixGreen)

                Text(film.year)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(Color.white.opacity(0.85))

                Text("16+")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 5)
                    .padding(.vertical, 1.5)
                    .overlay(
                        RoundedRectangle(cornerRadius: 3)
                            .stroke(Color.white.opacity(0.45), lineWidth: 1)
                    )

                Text(film.quality)
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 5)
                    .padding(.vertical, 1.5)
                    .background(Color.white.opacity(0.14))
                    .cornerRadius(3)
                    .overlay(
                        RoundedRectangle(cornerRadius: 3)
                            .stroke(Color.white.opacity(0.35), lineWidth: 0.8)
                    )

                Text("★ \(film.imdbScore)")
                    .font(.system(size: 11.5, weight: .heavy))
                    .foregroundColor(KLTheme.imdbGold)
            }

            // Row 4: Netflix TOP 10 Rank Badge
            HStack(spacing: 7) {
                Text("TOP 10")
                    .font(.system(size: 9.5, weight: .black))
                    .foregroundColor(.white)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2.5)
                    .background(KLTheme.netflixRed)
                    .cornerRadius(4)

                Text("Số #\(currentIndex + 1) trong Danh mục Phim Thịnh Hành Hôm Nay")
                    .font(.system(size: 11.5, weight: .bold))
                    .foregroundColor(.white)
                    .lineLimit(1)
            }

            // Row 5: Synopsis
            Text(synopsis.isEmpty ? "\(film.originalName.isEmpty ? film.name : film.originalName) — Trải nghiệm điện ảnh sắc nét chuẩn Netflix 4K Vietsub & Thuyết minh trên KenhLive." : synopsis)
                .font(.system(size: 12, weight: .regular))
                .foregroundColor(Color.white.opacity(0.78))
                .lineLimit(2)

            // Row 6: Netflix Action Buttons (White Play Button + Translucent Glass Secondary)
            HStack(spacing: 8) {
                // Iconic White Netflix Play Button
                Button(action: onPlayNow) {
                    HStack(spacing: 6) {
                        Text("▶")
                            .font(.system(size: 12, weight: .black))
                        Text("XEM NGAY")
                            .font(.system(size: 13, weight: .black))
                            .tracking(0.4)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 11)
                    .foregroundColor(.black)
                    .background(Color.white)
                    .cornerRadius(8)
                }
                .buttonStyle(KLScaleButtonStyle())

                // Secondary Episode Button
                Button(action: onOpenEpisodes) {
                    Text("ℹ CHỌN TẬP")
                        .font(.system(size: 12, weight: .bold))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 11)
                        .foregroundColor(.white)
                        .background(Color.white.opacity(0.18))
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.white.opacity(0.25), lineWidth: 0.8)
                        )
                }
                .buttonStyle(KLScaleButtonStyle())

                // Save Bookmark Button
                Button(action: onToggleFavorite) {
                    Text(isFavorite ? "✓ ĐÃ LƯU" : "+ LƯU")
                        .font(.system(size: 11.5, weight: .bold))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 11)
                        .foregroundColor(isFavorite ? KLTheme.imdbGold : .white)
                        .background(Color.white.opacity(0.14))
                        .cornerRadius(8)
                }
                .buttonStyle(KLScaleButtonStyle())

                // Next Film Cycle Button
                if totalCount > 1 {
                    Button(action: onCycleNext) {
                        Text("↻")
                            .font(.system(size: 14, weight: .black))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 9.5)
                            .foregroundColor(.white)
                            .background(Color.white.opacity(0.14))
                            .cornerRadius(8)
                    }
                    .buttonStyle(KLScaleButtonStyle())
                }
            }
            .padding(.top, 4)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            ZStack {
                AsyncImage(url: URL(string: film.posterUrl.isEmpty ? film.thumbUrl : film.posterUrl)) { phase in
                    if let image = phase.image {
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } else {
                        LinearGradient(
                            colors: [Color(red: 0.25, green: 0.05, blue: 0.10), KLTheme.bgDeep],
                            startPoint: .topTrailing,
                            endPoint: .bottomLeading
                        )
                    }
                }

                // Multi-stop Netflix Cinema Scrim
                LinearGradient(
                    colors: [
                        KLTheme.bgDeep.opacity(0.10),
                        KLTheme.bgDeep.opacity(0.55),
                        KLTheme.bgDeep.opacity(0.92),
                        KLTheme.bgDeep
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            }
        )
        .cornerRadius(18)
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(Color.white.opacity(0.14), lineWidth: 1)
        )
        .clipped()
        .padding(.horizontal, 16)
    }
}

// MARK: - Continue Watching Rail (Netflix Red Progress)
private struct ContinueWatchingRail: View {
    let items: [WatchProgress]
    let onTap: (WatchProgress) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            KLSectionHeader(
                title: "Tiếp Tục Xem",
                subtitle: "Khôi phục ngay tập phim đang xem dở",
                trailingText: "\(items.count) PHIM",
                accentColor: KLTheme.netflixRed
            )

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(items) { item in
                        Button {
                            onTap(item)
                        } label: {
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Text("▶ TIẾP TỤC")
                                        .font(.system(size: 9.5, weight: .black))
                                        .foregroundColor(KLTheme.netflixRed)
                                    Spacer()
                                    Text("\(Int(item.progressPercent * 100))%")
                                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                                        .foregroundColor(KLTheme.textSecondary)
                                }

                                Text(item.filmName)
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(.white)
                                    .lineLimit(1)

                                Text(item.episodeName)
                                    .font(.system(size: 11.5, weight: .medium))
                                    .foregroundColor(KLTheme.textSecondary)

                                GeometryReader { geo in
                                    ZStack(alignment: .leading) {
                                        Capsule()
                                            .fill(Color.white.opacity(0.16))
                                            .frame(height: 4)
                                        Capsule()
                                            .fill(KLTheme.netflixRed)
                                            .frame(width: geo.size.width * max(0.08, item.progressPercent), height: 4)
                                    }
                                }
                                .frame(height: 4)
                            }
                            .padding(14)
                            .frame(width: 225)
                            .background(KLTheme.surfaceCard)
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(KLTheme.borderSubtle, lineWidth: 0.8)
                            )
                        }
                        .buttonStyle(KLScaleButtonStyle())
                    }
                }
                .padding(.horizontal, 16)
            }
        }
    }
}

// MARK: - Horizontal 2:3 Netflix Poster Carousel
private struct FilmSectionRow: View {
    let title: String
    let films: [FilmItem]
    let watchHistory: [WatchProgress]
    let onSelectFilm: (FilmItem) -> Void
    var onSeeMore: (() -> Void)? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 11) {
            HStack(alignment: .firstTextBaseline) {
                HStack(spacing: 8) {
                    Rectangle()
                        .fill(KLTheme.netflixRed)
                        .frame(width: 3.5, height: 15)
                        .cornerRadius(2)

                    Text(title)
                        .font(.system(size: 15.5, weight: .heavy))
                        .foregroundColor(.white)
                }

                Spacer()

                if let onSeeMore = onSeeMore {
                    Button(action: onSeeMore) {
                        Text("Khám phá tất cả ›")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(KLTheme.textSecondary)
                    }
                }
            }
            .padding(.horizontal, 16)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(films) { film in
                        let progress = watchHistory.first(where: { $0.filmSlug == film.slug })?.progressPercent ?? 0

                        Button {
                            onSelectFilm(film)
                        } label: {
                            VStack(alignment: .leading, spacing: 6) {
                                // 2:3 Poster Frame (130 x 195)
                                ZStack {
                                    AsyncImage(url: URL(string: film.thumbUrl.isEmpty ? film.posterUrl : film.thumbUrl)) { phase in
                                        if let img = phase.image {
                                            img
                                                .resizable()
                                                .aspectRatio(contentMode: .fill)
                                        } else {
                                            KLTheme.surfaceCard
                                        }
                                    }
                                    .frame(width: 130, height: 195)
                                    .clipped()

                                    // Bottom Gradient Scrim on Poster
                                    VStack {
                                        Spacer()
                                        LinearGradient(
                                            colors: [.clear, Color.black.opacity(0.85)],
                                            startPoint: .top,
                                            endPoint: .bottom
                                        )
                                        .frame(height: 55)
                                    }

                                    // Corner Badges Overlay
                                    VStack {
                                        HStack {
                                            Text("★ \(film.imdbScore)")
                                                .font(.system(size: 9.5, weight: .heavy, design: .rounded))
                                                .foregroundColor(KLTheme.imdbGold)
                                                .padding(.horizontal, 5.5)
                                                .padding(.vertical, 2.5)
                                                .background(Color.black.opacity(0.78))
                                                .cornerRadius(4)

                                            Spacer()

                                            Text(film.quality)
                                                .font(.system(size: 9, weight: .black))
                                                .foregroundColor(.white)
                                                .padding(.horizontal, 5.5)
                                                .padding(.vertical, 2.5)
                                                .background(KLTheme.netflixRed)
                                                .cornerRadius(4)
                                        }
                                        .padding(6)

                                        Spacer()

                                        HStack {
                                            Text(film.currentEpisode.isEmpty ? "Full" : film.currentEpisode)
                                                .font(.system(size: 9.5, weight: .bold))
                                                .foregroundColor(.white)
                                                .padding(.horizontal, 6)
                                                .padding(.vertical, 2.5)
                                                .background(Color.black.opacity(0.78))
                                                .cornerRadius(4)
                                            Spacer()
                                        }
                                        .padding(.horizontal, 6)
                                        .padding(.bottom, progress > 0 ? 8 : 6)

                                        // Netflix Red Progress Bar at Poster Bottom
                                        if progress > 0 {
                                            GeometryReader { geo in
                                                ZStack(alignment: .leading) {
                                                    Rectangle()
                                                        .fill(Color.white.opacity(0.25))
                                                        .frame(height: 3.5)
                                                    Rectangle()
                                                        .fill(KLTheme.netflixRed)
                                                        .frame(width: geo.size.width * max(0.1, progress), height: 3.5)
                                                }
                                            }
                                            .frame(height: 3.5)
                                        }
                                    }
                                }
                                .frame(width: 130, height: 195)
                                .cornerRadius(10)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(Color.white.opacity(0.12), lineWidth: 0.8)
                                )

                                Text(film.name)
                                    .font(.system(size: 12.5, weight: .bold))
                                    .foregroundColor(.white)
                                    .lineLimit(1)
                                    .frame(width: 130, alignment: .leading)

                                Text("\(film.year) · \(film.language)")
                                    .font(.system(size: 10.5, weight: .medium))
                                    .foregroundColor(KLTheme.textMuted)
                                    .lineLimit(1)
                                    .frame(width: 130, alignment: .leading)
                            }
                            .frame(width: 130)
                        }
                        .buttonStyle(KLScaleButtonStyle())
                    }
                }
                .padding(.horizontal, 16)
            }
        }
    }
}
