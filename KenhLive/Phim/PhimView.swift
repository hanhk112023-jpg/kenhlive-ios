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
        KLFilterItem(id: "tat-ca", title: "Tất Cả"),
        KLFilterItem(id: "lich-su", title: "Lịch Sử Xem"),
        KLFilterItem(id: "phim-moi", title: "Mới Cập Nhật"),
        KLFilterItem(id: "phim-bo", title: "Phim Bộ"),
        KLFilterItem(id: "phim-le", title: "Phim Lẻ"),
        KLFilterItem(id: "hoat-hinh", title: "Hoạt Hình & Anime"),
        KLFilterItem(id: "hanh-dong", title: "Hành Động"),
        KLFilterItem(id: "tinh-cam", title: "Tình Cảm"),
        KLFilterItem(id: "co-trang", title: "Cổ Trang")
    ]

    private var currentHero: FilmItem? {
        guard !featuredFilms.isEmpty else { return sections.first?.films.first }
        return featuredFilms[heroIndex % featuredFilms.count]
    }

    var body: some View {
        ZStack {
            KLTheme.bgDeep.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 22) {
                    // 1. Minimalist Cinema Header
                    HStack(alignment: .lastTextBaseline) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("RẠP PHIM TẠI GIA")
                                .font(.system(size: 11, weight: .black, design: .rounded))
                                .tracking(1.8)
                                .foregroundColor(KLTheme.brandOrange)

                            Text("Kho Phim Điện Ảnh")
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(KLTheme.textPrimary)
                        }

                        Spacer()

                        Text("4K · VIETSUB")
                            .font(.system(size: 10.5, weight: .bold, design: .monospaced))
                            .foregroundColor(KLTheme.imdbGold)
                            .padding(.horizontal, 9)
                            .padding(.vertical, 4)
                            .background(KLTheme.imdbGold.opacity(0.12))
                            .cornerRadius(6)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 12)

                    // 2. Category Filter Strip
                    KLFilterStrip(items: filterPills, selection: $selectedFilter)
                        .onChange(of: selectedFilter) { newCat in
                            Task { await loadCategory(newCat) }
                        }

                    // 3. Cinema Hero Spotlight Banner
                    if let hero = currentHero {
                        CinemaHeroCard(
                            film: hero,
                            synopsis: heroSynopsis,
                            currentIndex: heroIndex,
                            totalCount: max(1, featuredFilms.count),
                            isFavorite: storage.isFavoriteFilm(slug: hero.slug),
                            onPlayNow: {
                                Task {
                                    let detail = await PhimService.shared.fetchFilmDetail(slug: hero.slug)
                                    if let firstEp = detail.episodes.first {
                                        activePlayback = ActiveVodPlayback(film: hero, episode: firstEp)
                                    }
                                }
                            },
                            onOpenEpisodes: {
                                selectedFilmForEpisodes = hero
                            },
                            onToggleFavorite: {
                                storage.toggleFavoriteFilm(slug: hero.slug)
                            },
                            onCycleNext: {
                                if featuredFilms.count > 1 {
                                    withAnimation(.easeInOut(duration: 0.2)) {
                                        heroIndex = (heroIndex + 1) % featuredFilms.count
                                    }
                                    Task { await loadHeroSynopsis() }
                                }
                            }
                        )
                    }

                    // 4. Continue Watching Rail ("Tiếp Tục Xem")
                    if !storage.watchHistory.isEmpty && (selectedFilter == "tat-ca" || selectedFilter == "lich-su") {
                        ContinueWatchingRail(items: storage.watchHistory) { item in
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

                    // 5. Film Catalog Sections
                    ForEach(sections) { section in
                        FilmSectionRow(
                            title: section.title,
                            films: section.films,
                            onSelectFilm: { film in
                                selectedFilmForEpisodes = film
                            }
                        )
                    }

                    Spacer(minLength: 90)
                }
            }
            .refreshable {
                await loadCategory(selectedFilter)
            }

            if isLoading && sections.isEmpty {
                ProgressView()
                    .tint(KLTheme.brandOrange)
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
                sections = [PhimSection(title: "Phim Đã Lưu Yêu Thích", films: favFilms)]
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

// MARK: - 16:9 Cinema Hero Spotlight Card (Minimalist Typography)
private struct CinemaHeroCard: View {
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
        ZStack(alignment: .bottomLeading) {
            AsyncImage(url: URL(string: film.posterUrl.isEmpty ? film.thumbUrl : film.posterUrl)) { phase in
                if let image = phase.image {
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } else {
                    LinearGradient(
                        colors: [Color(red: 0.16, green: 0.10, blue: 0.22), KLTheme.bgDeep],
                        startPoint: .topTrailing,
                        endPoint: .bottomLeading
                    )
                }
            }
            .frame(height: 270)
            .clipped()

            LinearGradient(
                colors: [
                    KLTheme.bgDeep.opacity(0.10),
                    KLTheme.bgDeep.opacity(0.75),
                    KLTheme.bgDeep
                ],
                startPoint: .top,
                endPoint: .bottom
            )

            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 6) {
                    KLPillBadge(text: "TOP THỊNH HÀNH", fg: .white, bg: KLTheme.liveRed, border: .clear)
                    KLPillBadge(text: "IMDb \(film.imdbScore)", fg: KLTheme.imdbGold, bg: Color.black.opacity(0.65), border: KLTheme.imdbGold.opacity(0.35))
                    KLPillBadge(text: film.year, fg: .white, bg: Color.black.opacity(0.55), border: KLTheme.borderSubtle)
                    KLPillBadge(text: "\(film.quality) · \(film.language)", fg: KLTheme.accentCyan, bg: Color.black.opacity(0.55), border: KLTheme.accentCyan.opacity(0.3))

                    Spacer()

                    if totalCount > 1 {
                        Text("\(currentIndex + 1)/\(totalCount)")
                            .font(.system(size: 10.5, weight: .bold, design: .monospaced))
                            .foregroundColor(KLTheme.textSecondary)
                            .padding(.horizontal, 7)
                            .padding(.vertical, 3)
                            .background(Color.black.opacity(0.55))
                            .cornerRadius(5)
                    }
                }

                Text(film.name)
                    .font(.system(size: 22, weight: .heavy))
                    .foregroundColor(.white)
                    .lineLimit(1)

                Text(synopsis.isEmpty ? "\(film.originalName.isEmpty ? film.name : film.originalName) — Siêu phẩm điện ảnh chất lượng cao trọn bộ trên KenhLive." : synopsis)
                    .font(.system(size: 12, weight: .regular))
                    .foregroundColor(KLTheme.textSecondary)
                    .lineLimit(2)

                HStack(spacing: 8) {
                    Button(action: onPlayNow) {
                        Text("XEM NGAY")
                            .font(.system(size: 12, weight: .bold))
                            .tracking(0.5)
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(KLTheme.brandOrange)
                            .cornerRadius(8)
                    }

                    Button(action: onOpenEpisodes) {
                        Text("DANH SÁCH TẬP")
                            .font(.system(size: 11.5, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 13)
                            .padding(.vertical, 10)
                            .background(Color.white.opacity(0.10))
                            .cornerRadius(8)
                    }

                    Button(action: onToggleFavorite) {
                        Text(isFavorite ? "ĐÃ LƯU" : "LƯU")
                            .font(.system(size: 11.5, weight: .bold))
                            .foregroundColor(KLTheme.imdbGold)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 10)
                            .background(KLTheme.imdbGold.opacity(0.12))
                            .cornerRadius(8)
                    }

                    if totalCount > 1 {
                        Button(action: onCycleNext) {
                            Text("ĐỔI PHIM")
                                .font(.system(size: 11.5, weight: .semibold))
                                .foregroundColor(KLTheme.textSecondary)
                                .padding(.horizontal, 11)
                                .padding(.vertical, 10)
                                .background(Color.white.opacity(0.06))
                                .cornerRadius(8)
                        }
                    }
                }
                .padding(.top, 4)
            }
            .padding(16)
        }
        .background(KLTheme.surfaceCard)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(KLTheme.borderSubtle, lineWidth: 1)
        )
        .padding(.horizontal, 16)
    }
}

// MARK: - Continue Watching Row
private struct ContinueWatchingRail: View {
    let items: [WatchProgress]
    let onTap: (WatchProgress) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            KLSectionHeader(
                title: "Tiếp Tục Xem",
                subtitle: "Khôi phục ngay vị trí đang xem",
                trailingText: "\(items.count) PHIM"
            )

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(items) { item in
                        Button {
                            onTap(item)
                        } label: {
                            VStack(alignment: .leading, spacing: 8) {
                                Text(item.filmName)
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(.white)
                                    .lineLimit(1)

                                Text("\(item.episodeName) · Đã xem \(Int(item.progressPercent * 100))%")
                                    .font(.system(size: 11.5, weight: .medium))
                                    .foregroundColor(KLTheme.brandOrange)

                                GeometryReader { geo in
                                    ZStack(alignment: .leading) {
                                        Capsule()
                                            .fill(Color.white.opacity(0.12))
                                            .frame(height: 4)
                                        Capsule()
                                            .fill(KLTheme.brandOrange)
                                            .frame(width: geo.size.width * item.progressPercent, height: 4)
                                    }
                                }
                                .frame(height: 4)
                            }
                            .padding(14)
                            .frame(width: 220)
                            .background(KLTheme.surfaceCard)
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(KLTheme.borderSubtle, lineWidth: 0.8)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 16)
            }
        }
    }
}

// MARK: - Horizontal Poster Carousel
private struct FilmSectionRow: View {
    let title: String
    let films: [FilmItem]
    let onSelectFilm: (FilmItem) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            KLSectionHeader(
                title: title,
                trailingText: "\(films.count) PHIM"
            )

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(films) { film in
                        Button {
                            onSelectFilm(film)
                        } label: {
                            VStack(alignment: .leading, spacing: 7) {
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
                                    .frame(width: 132, height: 186)
                                    .clipped()
                                    .cornerRadius(12)

                                    // Badges Overlay
                                    VStack {
                                        HStack {
                                            Text(film.imdbScore)
                                                .font(.system(size: 10, weight: .heavy, design: .rounded))
                                                .foregroundColor(KLTheme.imdbGold)
                                                .padding(.horizontal, 6)
                                                .padding(.vertical, 3)
                                                .background(Color.black.opacity(0.72))
                                                .cornerRadius(5)

                                            Spacer()

                                            Text(film.quality)
                                                .font(.system(size: 9.5, weight: .bold))
                                                .foregroundColor(.white)
                                                .padding(.horizontal, 6)
                                                .padding(.vertical, 3)
                                                .background(Color.black.opacity(0.72))
                                                .cornerRadius(5)
                                        }
                                        .padding(6)

                                        Spacer()

                                        HStack {
                                            Text(film.currentEpisode.isEmpty ? "Full" : film.currentEpisode)
                                                .font(.system(size: 9.5, weight: .bold))
                                                .foregroundColor(KLTheme.brandOrange)
                                                .padding(.horizontal, 6)
                                                .padding(.vertical, 3)
                                                .background(Color.black.opacity(0.78))
                                                .cornerRadius(5)
                                            Spacer()
                                        }
                                        .padding(6)
                                    }
                                }
                                .frame(width: 132, height: 186)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(KLTheme.borderSubtle, lineWidth: 0.8)
                                )

                                Text(film.name)
                                    .font(.system(size: 12.5, weight: .bold))
                                    .foregroundColor(.white)
                                    .lineLimit(2)
                                    .multilineTextAlignment(.leading)
                                    .frame(width: 132, height: 32, alignment: .topLeading)

                                Text("\(film.year) · \(film.language)")
                                    .font(.system(size: 10.5, weight: .regular))
                                    .foregroundColor(KLTheme.textMuted)
                                    .lineLimit(1)
                            }
                            .frame(width: 132)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 16)
            }
        }
    }
}
