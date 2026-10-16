import SwiftUI

// MARK: - Cinema Netflix / Liquid Glass Movie Experience
struct PhimView: View {
    @ObservedObject private var storage = StorageManager.shared
    @State private var selectedFilter: String = "tat-ca"
    @State private var sections: [PhimSection] = []
    @State private var categoryFilms: [FilmItem] = []
    @State private var featuredFilms: [FilmItem] = []
    @State private var heroIndex: Int = 0
    @State private var isLoading: Bool = true

    // Category Loading State
    @State private var isLoadingCategory: Bool = false
    @State private var categoryLoadingTask: Task<Void, Never>? = nil

    // Search state
    @State private var searchQuery: String = ""
    @State private var searchResults: [FilmItem] = []
    @State private var isSearching: Bool = false
    @State private var searchTask: Task<Void, Never>? = nil

    @State private var selectedFilmForEpisodes: FilmItem? = nil
    @State private var initialResumeProgressForSheet: WatchProgress? = nil
    @State private var autoPlayForSheet: Bool = false

    var onSelectTab: ((KLTab) -> Void)? = nil

    private let filterPills: [KLFilterItem<String>] = [
        KLFilterItem(id: "tat-ca", title: "Trang Chủ Phim"),
        KLFilterItem(id: "lich-su", title: "Đã Lưu & Xem Gần Đây"),
        KLFilterItem(id: "phim-moi", title: "Mới Cập Nhật"),
        KLFilterItem(id: "phim-bo", title: "Phim Bộ Hot"),
        KLFilterItem(id: "phim-le", title: "Phim Lẻ Chiếu Rạp"),
        KLFilterItem(id: "hoat-hinh", title: "Hoạt Hình & Anime"),
        KLFilterItem(id: "han-quoc", title: "Hàn Quốc"),
        KLFilterItem(id: "trung-quoc", title: "Trung Quốc"),
        KLFilterItem(id: "au-my", title: "Âu Mỹ Bom Tấn"),
        KLFilterItem(id: "hanh-dong", title: "Hành Động"),
        KLFilterItem(id: "co-trang", title: "Cổ Trang"),
        KLFilterItem(id: "tinh-cam", title: "Tình Cảm"),
        KLFilterItem(id: "kinh-di", title: "Kinh Dị")
    ]

    // Featured Curated Collection Cards ("Bạn đang quan tâm gì?")
    private let curatedCollections: [CuratedCollection] = [
        CuratedCollection(
            title: "Thể Thao Live",
            countText: "4 Nhà Đài",
            gradient: [Color(red: 0.95, green: 0.35, blue: 0.12), Color(red: 0.98, green: 0.55, blue: 0.15)],
            categorySlug: "sports",
            searchKeyword: ""
        ),
        CuratedCollection(
            title: "Truyền Hình VTV",
            countText: "VTV, K+, HTV",
            gradient: [Color(red: 0.12, green: 0.45, blue: 0.85), Color(red: 0.25, green: 0.65, blue: 0.95)],
            categorySlug: "iptv",
            searchKeyword: ""
        ),
        CuratedCollection(
            title: "Marvel",
            countText: "32 phim",
            gradient: [Color(red: 0.48, green: 0.17, blue: 0.75), Color(red: 0.62, green: 0.31, blue: 0.87)],
            categorySlug: "au-my",
            searchKeyword: "Marvel"
        ),
        CuratedCollection(
            title: "IMDb Top 100 Movies",
            countText: "52 phim",
            gradient: [Color(red: 0.91, green: 0.44, blue: 0.32), Color(red: 0.90, green: 0.22, blue: 0.27)],
            categorySlug: "phim-le",
            searchKeyword: "Top"
        ),
        CuratedCollection(
            title: "DC Comic",
            countText: "39 phim",
            gradient: [Color(red: 0.11, green: 0.21, blue: 0.34), Color(red: 0.27, green: 0.48, blue: 0.62)],
            categorySlug: "au-my",
            searchKeyword: "Batman"
        ),
        CuratedCollection(
            title: "Hoạt Hình & Anime",
            countText: "48 phim",
            gradient: [Color(red: 0.16, green: 0.62, blue: 0.56), Color(red: 0.15, green: 0.27, blue: 0.33)],
            categorySlug: "hoat-hinh",
            searchKeyword: "Anime"
        ),
        CuratedCollection(
            title: "Chiếu Rạp Bom Tấn",
            countText: "48 phim",
            gradient: [Color(red: 0.96, green: 0.64, blue: 0.38), Color(red: 0.83, green: 0.64, blue: 0.45)],
            categorySlug: "phim-le",
            searchKeyword: "Chiếu Rạp"
        ),
        CuratedCollection(
            title: "K-Drama Hot",
            countText: "48 phim",
            gradient: [Color(red: 0.97, green: 0.15, blue: 0.52), Color(red: 0.45, green: 0.04, blue: 0.72)],
            categorySlug: "han-quoc",
            searchKeyword: "Hàn Quốc"
        ),
        CuratedCollection(
            title: "Cổ Trang Trung Quốc",
            countText: "48 phim",
            gradient: [Color(red: 0.62, green: 0.16, blue: 0.17), Color(red: 0.33, green: 0.04, blue: 0.05)],
            categorySlug: "trung-quoc",
            searchKeyword: "Cổ Trang"
        )
    ]

    private var currentHero: FilmItem? {
        guard !featuredFilms.isEmpty else { return sections.first?.films.first }
        return featuredFilms[heroIndex % featuredFilms.count]
    }

    var body: some View {
        ZStack {
            Color(red: 0.07, green: 0.07, blue: 0.09).ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 22) {
                    // 1. Full-Bleed Cinema Hero Banner (Featured Title, Subtitle, Badges & "Xem chi tiết" CTA)
                    renderHeroCarouselBanner()

                    // 2. Main Cinema Catalog ("Bạn đang quan tâm gì?" -> "Top tuần" -> Curated Shelves)
                    renderMainCinemaCatalog()

                    Spacer(minLength: 110)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .edgesIgnoringSafeArea(.top)
            .refreshable {
                await loadHomeSections()
            }

            if isLoading && sections.isEmpty && categoryFilms.isEmpty {
                ProgressView()
                    .tint(KLTheme.brandOrange)
                    .scaleEffect(1.3)
            }
        }
        .task {
            if sections.isEmpty {
                await selectCategory(selectedFilter)
            }
        }
        .sheet(item: $selectedFilmForEpisodes) { film in
            EpisodePickerSheet(
                film: film,
                initialResumeProgress: initialResumeProgressForSheet ?? storage.getProgress(for: film.slug),
                autoPlay: autoPlayForSheet
            )
        }
    }

    // MARK: - 1. Full-Bleed Cinema Hero Banner
    @ViewBuilder
    private func renderHeroCarouselBanner() -> some View {
        if let hero = currentHero {
            ZStack(alignment: .bottom) {
                // Background Poster Art with Cinematic Gradient Overlay
                AsyncImage(url: URL(string: hero.posterUrl.isEmpty ? hero.thumbUrl : hero.posterUrl)) { phase in
                    if let img = phase.image {
                        img
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } else {
                        Color(red: 0.12, green: 0.10, blue: 0.15)
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 480)
                .clipped()

                // Multi-Layer Cinema Scrim Gradient
                LinearGradient(
                    stops: [
                        .init(color: Color.clear, location: 0.0),
                        .init(color: Color(red: 0.07, green: 0.07, blue: 0.09).opacity(0.35), location: 0.45),
                        .init(color: Color(red: 0.07, green: 0.07, blue: 0.09).opacity(0.85), location: 0.8),
                        .init(color: Color(red: 0.07, green: 0.07, blue: 0.09), location: 1.0)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )

                // Foreground Content (Title, Subtitle, Badges, CTA, Carousel Dots)
                VStack(spacing: 9) {
                    // Main Title
                    Text(hero.name)
                        .font(.system(size: 26, weight: .heavy, design: .rounded))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                        .shadow(color: .black.opacity(0.85), radius: 6, x: 0, y: 2)
                        .padding(.horizontal, 24)

                    // English Subtitle
                    Text(hero.originalName.isEmpty ? "Cinema High Quality" : hero.originalName)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(Color.white.opacity(0.72))
                        .lineLimit(1)
                        .padding(.horizontal, 20)

                    // Information Badges Row (Year · Quality · IMDb)
                    HStack(spacing: 8) {
                        // Year Pill
                        Text(hero.year)
                            .font(.system(size: 11.5, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 9)
                            .padding(.vertical, 4.5)
                            .background(Color.black.opacity(0.65))
                            .clipShape(Capsule())
                            .overlay(
                                Capsule().stroke(Color.white.opacity(0.28), lineWidth: 0.8)
                            )

                        // Quality Pill: Cyan Blue "Full HD (PĐ)" or Gold "4K (PĐ-TM)"
                        Text(hero.quality.contains("4K") ? "4K (PĐ-TM)" : "Full HD (PĐ)")
                            .font(.system(size: 11, weight: .heavy))
                            .foregroundColor(.white)
                            .padding(.horizontal, 9)
                            .padding(.vertical, 4.5)
                            .background(hero.quality.contains("4K") ? Color(red: 0.96, green: 0.77, blue: 0.10) : Color(red: 0.0, green: 0.52, blue: 0.82))
                            .clipShape(Capsule())

                        // IMDb Rating Pill (Solid Gold)
                        HStack(spacing: 3) {
                            Text("IMDb")
                                .font(.system(size: 9.5, weight: .black))
                            Text(hero.imdbScore)
                                .font(.system(size: 11, weight: .heavy))
                        }
                        .foregroundColor(.black)
                        .padding(.horizontal, 8.5)
                        .padding(.vertical, 4.5)
                        .background(Color(red: 0.96, green: 0.77, blue: 0.10))
                        .clipShape(Capsule())
                    }
                    .padding(.top, 2)

                    // Call-To-Action Button: "Xem chi tiết"
                    Button {
                        KLHaptics.medium()
                        autoPlayForSheet = false
                        initialResumeProgressForSheet = storage.getProgress(for: hero.slug)
                        selectedFilmForEpisodes = hero
                    } label: {
                        Text("Xem chi tiết")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.black)
                            .padding(.horizontal, 32)
                            .padding(.vertical, 11)
                            .background(Color.white)
                            .clipShape(Capsule())
                            .shadow(color: Color.black.opacity(0.5), radius: 8, x: 0, y: 3)
                    }
                    .buttonStyle(.plain)
                    .padding(.top, 4)

                    // Carousel Pagination Dots (7 Dots)
                    let totalDots = min(7, max(1, featuredFilms.count))
                    HStack(spacing: 7) {
                        ForEach(0..<totalDots, id: \.self) { dotIdx in
                            let isCurrent = (heroIndex % totalDots) == dotIdx
                            Circle()
                                .fill(isCurrent ? Color.white : Color.white.opacity(0.28))
                                .frame(width: isCurrent ? 7.5 : 5, height: isCurrent ? 7.5 : 5)
                                .onTapGesture {
                                    KLHaptics.light()
                                    withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                        heroIndex = dotIdx
                                    }
                                }
                        }
                    }
                    .padding(.top, 8)
                    .padding(.bottom, 12)
                }
            }
            .frame(height: 410)
            .gesture(
                DragGesture(minimumDistance: 35)
                    .onEnded { value in
                        if value.translation.width < -40 && featuredFilms.count > 1 {
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                heroIndex = (heroIndex + 1) % featuredFilms.count
                            }
                        } else if value.translation.width > 40 && featuredFilms.count > 1 {
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                heroIndex = (heroIndex - 1 + featuredFilms.count) % featuredFilms.count
                            }
                        }
                    }
            )
        }
    }

    // MARK: - 2. Main Cinema Catalog
    @ViewBuilder
    private func renderMainCinemaCatalog() -> some View {
        VStack(alignment: .leading, spacing: 24) {
            // Section A: "Bạn đang quan tâm gì?" (Featured Gradient Collection Cards)
            renderCuratedCollectionsSection()

            // Section B: "Top tuần" (Trending Weekly Leaderboard with Large Numerals 1, 2, 3...)
            if let topWeekSection = sections.first {
                renderWeeklyLeaderboardSection(topWeekSection)
            }

            // Section C: Continue Watching Rail (if history exists)
            if !storage.watchHistory.isEmpty {
                ContinueWatchingRail(items: storage.watchHistory) { item in
                    KLHaptics.medium()
                    let film = FilmItem(
                        name: item.filmName,
                        slug: item.filmSlug,
                        originalName: "",
                        thumbUrl: item.posterUrl,
                        posterUrl: item.posterUrl,
                        quality: "HD",
                        year: ""
                    )
                    autoPlayForSheet = true
                    initialResumeProgressForSheet = item
                    selectedFilmForEpisodes = film
                }
            }

            // Section D: Remaining Curated Cinema Shelves ("Drama xứ kim chi", "Phim Lẻ", "Hoạt Hình"...)
            ForEach(Array(sections.dropFirst())) { section in
                CinemaShelfRow(
                    title: section.title,
                    subtitle: section.subtitle,
                    films: section.films,
                    onSelectFilm: { film in
                        KLHaptics.light()
                        autoPlayForSheet = false
                        initialResumeProgressForSheet = nil
                        selectedFilmForEpisodes = film
                    },
                    onSeeAll: {
                        navigateToSectionCategory(sectionTitle: section.title)
                    }
                )
            }
        }
    }

    // MARK: - Section A: "Bạn đang quan tâm gì?"
    @ViewBuilder
    private func renderCuratedCollectionsSection() -> some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Text("Bạn đang quan tâm gì?")
                    .font(.system(size: 18, weight: .heavy, design: .rounded))
                    .foregroundColor(.white)

                Spacer()

                Button {
                    KLHaptics.selection()
                    Task { await selectCategory("phim-moi") }
                } label: {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.white)
                        .frame(width: 28, height: 28)
                        .background(Color.white.opacity(0.12))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 16)

            // Horizontal Scroll of Gradient Cards
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(curatedCollections) { col in
                        Button {
                            KLHaptics.medium()
                            if col.categorySlug == "sports" {
                                onSelectTab?(.sports)
                            } else if col.categorySlug == "iptv" {
                                onSelectTab?(.iptv)
                            } else {
                                Task { await selectCategory(col.categorySlug) }
                            }
                        } label: {
                            VStack(alignment: .leading) {
                                Text(col.title)
                                    .font(.system(size: 15, weight: .heavy))
                                    .foregroundColor(.white)
                                    .lineLimit(2)
                                    .multilineTextAlignment(.leading)

                                Spacer()

                                Text(col.countText)
                                    .font(.system(size: 11.5, weight: .semibold))
                                    .foregroundColor(Color.white.opacity(0.85))
                            }
                            .padding(14)
                            .frame(width: 155, height: 86, alignment: .leading)
                            .background(
                                LinearGradient(
                                    colors: col.gradient,
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .cornerRadius(18)
                            .overlay(
                                RoundedRectangle(cornerRadius: 18)
                                    .stroke(Color.white.opacity(0.18), lineWidth: 0.8)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 16)
            }
        }
    }

    // MARK: - Section B: "Top tuần" (Trending Leaderboard with Enormous Rank Numerals)
    @ViewBuilder
    private func renderWeeklyLeaderboardSection(_ section: PhimSection) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Text("Top tuần")
                    .font(.system(size: 18, weight: .heavy, design: .rounded))
                    .foregroundColor(.white)

                Spacer()

                Button {
                    KLHaptics.selection()
                    Task { await selectCategory("phim-moi") }
                } label: {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.white)
                        .frame(width: 28, height: 28)
                        .background(Color.white.opacity(0.12))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 16)

            // Horizontal Scroll of Leaderboard Poster Cards
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 14) {
                    ForEach(Array(section.films.prefix(10).enumerated()), id: \.element.id) { index, film in
                        let rank = index + 1
                        Button {
                            KLHaptics.light()
                            autoPlayForSheet = false
                            initialResumeProgressForSheet = nil
                            selectedFilmForEpisodes = film
                        } label: {
                            VStack(alignment: .leading, spacing: 6) {
                                // Poster Art with Badges & Large Rank Number
                                ZStack(alignment: .bottomLeading) {
                                    // Poster Image
                                    AsyncImage(url: URL(string: film.posterUrl.isEmpty ? film.thumbUrl : film.posterUrl)) { phase in
                                        if let img = phase.image {
                                            img
                                                .resizable()
                                                .aspectRatio(contentMode: .fill)
                                        } else {
                                            Color(red: 0.14, green: 0.14, blue: 0.18)
                                        }
                                    }
                                    .frame(width: 155, height: 225)
                                    .clipped()

                                    // Gradient Shadow Vignette for readability
                                    LinearGradient(
                                        colors: [.clear, Color.black.opacity(0.35), Color.black.opacity(0.92)],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )

                                    // Top Badges (Duration on left, Quality on right)
                                    VStack {
                                        HStack {
                                            // Duration pill
                                            HStack(spacing: 3) {
                                                Image(systemName: "clock")
                                                    .font(.system(size: 9))
                                                Text(film.time.isEmpty ? "120" : film.time.replacingOccurrences(of: " phút", with: ""))
                                                    .font(.system(size: 9.5, weight: .bold))
                                            }
                                            .foregroundColor(.white)
                                            .padding(.horizontal, 6)
                                            .padding(.vertical, 3)
                                            .background(Color.black.opacity(0.65))
                                            .clipShape(Capsule())

                                            Spacer()

                                            // Resolution pill (Blue or Gold)
                                            Text(rank % 2 == 1 ? "Full HD (PĐ-TM)" : "4K (PĐ-TM)")
                                                .font(.system(size: 8.5, weight: .heavy))
                                                .foregroundColor(rank % 2 == 1 ? Color(red: 0.45, green: 0.85, blue: 1.0) : Color(red: 0.96, green: 0.77, blue: 0.10))
                                                .padding(.horizontal, 6)
                                                .padding(.vertical, 3)
                                                .background(Color.black.opacity(0.72))
                                                .clipShape(Capsule())
                                        }
                                        .padding(7)

                                        Spacer()
                                    }

                                    // Enormous Stylized Rank Number (1, 2, 3...)
                                    Text("\(rank)")
                                        .font(.system(size: 64, weight: .black, design: .rounded))
                                        .foregroundColor(.white)
                                        .shadow(color: .black.opacity(0.95), radius: 6, x: 2, y: 3)
                                        .offset(x: 8, y: -28)

                                    // Bottom Info Row inside Poster
                                    HStack(spacing: 4) {
                                        Spacer()

                                        // Year
                                        Text(film.year)
                                            .font(.system(size: 9, weight: .bold))
                                            .foregroundColor(.white)
                                            .padding(.horizontal, 5)
                                            .padding(.vertical, 2)
                                            .background(Color.black.opacity(0.75))
                                            .clipShape(Capsule())

                                        // Star Rating
                                        HStack(spacing: 2) {
                                            Image(systemName: "star.fill")
                                                .font(.system(size: 7.5))
                                                .foregroundColor(Color(red: 0.96, green: 0.77, blue: 0.10))
                                            Text("4.5")
                                                .font(.system(size: 9, weight: .bold))
                                                .foregroundColor(.white)
                                        }
                                        .padding(.horizontal, 5)
                                        .padding(.vertical, 2)
                                        .background(Color.black.opacity(0.75))
                                        .clipShape(Capsule())

                                        // Solid Yellow IMDb Pill
                                        HStack(spacing: 2) {
                                            Text("IMDb")
                                                .font(.system(size: 8, weight: .black))
                                            Text(film.imdbScore)
                                                .font(.system(size: 9, weight: .heavy))
                                        }
                                        .foregroundColor(.black)
                                        .padding(.horizontal, 5)
                                        .padding(.vertical, 2)
                                        .background(Color(red: 0.96, green: 0.77, blue: 0.10))
                                        .clipShape(Capsule())
                                    }
                                    .padding(.horizontal, 6)
                                    .padding(.bottom, 7)
                                }
                                .frame(width: 155, height: 225)
                                .cornerRadius(16)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(Color.white.opacity(0.12), lineWidth: 0.8)
                                )

                                // Primary & Original Title underneath
                                Text(film.name)
                                    .font(.system(size: 13, weight: .bold))
                                    .foregroundColor(.white)
                                    .lineLimit(1)
                                    .frame(width: 155, alignment: .leading)

                                Text(film.originalName.isEmpty ? film.language : film.originalName)
                                    .font(.system(size: 11, weight: .regular))
                                    .foregroundColor(KLTheme.textMuted)
                                    .lineLimit(1)
                                    .frame(width: 155, alignment: .leading)
                            }
                            .frame(width: 155)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 16)
            }
        }
    }

    // MARK: - Section D: Curated Cinema Shelf Row
    private struct CinemaShelfRow: View {
        let title: String
        let subtitle: String
        let films: [FilmItem]
        let onSelectFilm: (FilmItem) -> Void
        let onSeeAll: () -> Void

        var body: some View {
            VStack(alignment: .leading, spacing: 12) {
                // Header with title and circular chevron ( > )
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(title)
                            .font(.system(size: 18, weight: .heavy, design: .rounded))
                            .foregroundColor(.white)
                        if !subtitle.isEmpty {
                            Text(subtitle)
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(KLTheme.textMuted)
                        }
                    }

                    Spacer()

                    Button(action: onSeeAll) {
                        Image(systemName: "chevron.right")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.white)
                            .frame(width: 28, height: 28)
                            .background(Color.white.opacity(0.12))
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 16)

                // Horizontal Scroll
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(films) { film in
                            Button {
                                onSelectFilm(film)
                            } label: {
                                VStack(alignment: .leading, spacing: 6) {
                                    ZStack(alignment: .bottomLeading) {
                                        AsyncImage(url: URL(string: film.posterUrl.isEmpty ? film.thumbUrl : film.posterUrl)) { phase in
                                            if let img = phase.image {
                                                img
                                                    .resizable()
                                                    .aspectRatio(contentMode: .fill)
                                            } else {
                                                Color(red: 0.14, green: 0.14, blue: 0.18)
                                            }
                                        }
                                        .frame(width: 135, height: 195)
                                        .clipped()

                                        // Gradient Scrim
                                        LinearGradient(
                                            colors: [.clear, Color.black.opacity(0.85)],
                                            startPoint: .top,
                                            endPoint: .bottom
                                        )

                                        // Badges
                                        VStack {
                                            HStack {
                                                Spacer()
                                                Text("4K (PĐ-TM)")
                                                    .font(.system(size: 8, weight: .heavy))
                                                    .foregroundColor(Color(red: 0.96, green: 0.77, blue: 0.10))
                                                    .padding(.horizontal, 5)
                                                    .padding(.vertical, 2.5)
                                                    .background(Color.black.opacity(0.75))
                                                    .clipShape(Capsule())
                                            }
                                            .padding(6)

                                            Spacer()

                                            // Bottom Info Bar inside Poster
                                            HStack(spacing: 4) {
                                                Text(film.year)
                                                    .font(.system(size: 8.5, weight: .bold))
                                                    .foregroundColor(.white)
                                                    .padding(.horizontal, 5)
                                                    .padding(.vertical, 2)
                                                    .background(Color.black.opacity(0.75))
                                                    .clipShape(Capsule())

                                                Spacer()

                                                HStack(spacing: 2) {
                                                    Text("IMDb")
                                                        .font(.system(size: 7.5, weight: .black))
                                                    Text(film.imdbScore)
                                                        .font(.system(size: 8.5, weight: .heavy))
                                                }
                                                .foregroundColor(.black)
                                                .padding(.horizontal, 5)
                                                .padding(.vertical, 2)
                                                .background(Color(red: 0.96, green: 0.77, blue: 0.10))
                                                .clipShape(Capsule())
                                            }
                                            .padding(6)
                                        }
                                    }
                                    .frame(width: 135, height: 195)
                                    .cornerRadius(14)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 14)
                                            .stroke(Color.white.opacity(0.12), lineWidth: 0.8)
                                    )

                                    Text(film.name)
                                        .font(.system(size: 12.5, weight: .bold))
                                        .foregroundColor(.white)
                                        .lineLimit(1)
                                        .frame(width: 135, alignment: .leading)

                                    Text(film.originalName.isEmpty ? film.language : film.originalName)
                                        .font(.system(size: 10.5, weight: .regular))
                                        .foregroundColor(KLTheme.textMuted)
                                        .lineLimit(1)
                                        .frame(width: 135, alignment: .leading)
                                }
                                .frame(width: 135)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 16)
                }
            }
        }
    }

    // MARK: - Filtered Category Grid View
    @ViewBuilder
    private func renderCategoryGridView() -> some View {
        VStack(alignment: .leading, spacing: 14) {
            let title = filterPills.first(where: { $0.id == selectedFilter })?.title ?? "Danh Mục Phim"
            HStack {
                HStack(spacing: 6) {
                    Circle()
                        .fill(KLTheme.brandOrange)
                        .frame(width: 6, height: 6)
                    Text(title.uppercased())
                        .font(.system(size: 13, weight: .heavy))
                        .tracking(0.6)
                        .foregroundColor(.white)
                }

                Spacer()

                if isLoadingCategory {
                    ProgressView().tint(KLTheme.brandOrange).scaleEffect(0.85)
                } else {
                    Text("\(categoryFilms.count) PHIM")
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .foregroundColor(KLTheme.imdbGold)
                }
            }
            .padding(.horizontal, 16)

            if isLoadingCategory && categoryFilms.isEmpty {
                // 12-Cell Skeleton Grid (Instant visual feedback)
                LazyVGrid(columns: [
                    GridItem(.flexible(), spacing: 10),
                    GridItem(.flexible(), spacing: 10),
                    GridItem(.flexible(), spacing: 10)
                ], spacing: 14) {
                    ForEach(0..<12, id: \.self) { _ in
                        VStack(alignment: .leading, spacing: 6) {
                            KLSkeletonView(height: 155, cornerRadius: 8)
                            KLSkeletonView(height: 12, cornerRadius: 3)
                            KLSkeletonView(height: 10, cornerRadius: 3)
                                .frame(width: 80)
                        }
                    }
                }
                .padding(.horizontal, 16)
            } else if categoryFilms.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "film.stack")
                        .font(.system(size: 38))
                        .foregroundColor(KLTheme.textMuted)

                    Text("Chưa có phim trong mục \(title)")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(KLTheme.textSecondary)

                    Button {
                        KLHaptics.medium()
                        Task { await selectCategory(selectedFilter) }
                    } label: {
                        Text("TẢI LẠI")
                            .font(.system(size: 11.5, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(KLTheme.brandOrange)
                            .cornerRadius(8)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
            } else {
                LazyVGrid(columns: [
                    GridItem(.flexible(), spacing: 10),
                    GridItem(.flexible(), spacing: 10),
                    GridItem(.flexible(), spacing: 10)
                ], spacing: 14) {
                    ForEach(categoryFilms) { film in
                        Button {
                            KLHaptics.light()
                            autoPlayForSheet = false
                            initialResumeProgressForSheet = nil
                            selectedFilmForEpisodes = film
                        } label: {
                            PosterCell(film: film)
                        }
                        .buttonStyle(KLScaleButtonStyle())
                    }
                }
                .padding(.horizontal, 16)
            }
        }
    }

    // MARK: - Search Results View
    @ViewBuilder
    private func renderSearchResultsView() -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("KẾT QUẢ TÌM KIẾM")
                    .font(.system(size: 11, weight: .heavy))
                    .tracking(0.8)
                    .foregroundColor(KLTheme.textMuted)

                Spacer()

                if isSearching {
                    ProgressView().tint(KLTheme.brandOrange).scaleEffect(0.8)
                } else {
                    Text("\(searchResults.count) PHIM")
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .foregroundColor(KLTheme.imdbGold)
                }
            }
            .padding(.horizontal, 16)

            if searchResults.isEmpty && !isSearching {
                VStack(spacing: 12) {
                    Image(systemName: "film.stack")
                        .font(.system(size: 38))
                        .foregroundColor(KLTheme.textMuted)

                    Text("Không tìm thấy phim phù hợp với \"\(searchQuery)\"")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(KLTheme.textSecondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
            } else {
                LazyVGrid(columns: [
                    GridItem(.flexible(), spacing: 10),
                    GridItem(.flexible(), spacing: 10),
                    GridItem(.flexible(), spacing: 10)
                ], spacing: 14) {
                    ForEach(searchResults) { film in
                        Button {
                            KLHaptics.light()
                            selectedFilmForEpisodes = film
                        } label: {
                            PosterCell(film: film)
                        }
                        .buttonStyle(KLScaleButtonStyle())
                    }
                }
                .padding(.horizontal, 16)
            }
        }
    }

    // MARK: - My List & Watch History View
    @ViewBuilder
    private func renderMyListView() -> some View {
        VStack(alignment: .leading, spacing: 18) {
            if !storage.watchHistory.isEmpty {
                ContinueWatchingRail(items: storage.watchHistory) { item in
                    KLHaptics.medium()
                    let film = FilmItem(
                        name: item.filmName,
                        slug: item.filmSlug,
                        originalName: "",
                        thumbUrl: item.posterUrl,
                        posterUrl: item.posterUrl,
                        quality: "HD",
                        year: ""
                    )
                    autoPlayForSheet = true
                    initialResumeProgressForSheet = item
                    selectedFilmForEpisodes = film
                }
            }

            let favSlugs = storage.favoriteFilmSlugs
            let allLoaded = (sections.flatMap { $0.films } + categoryFilms + featuredFilms)
            let favFilms = allLoaded.filter { favSlugs.contains($0.slug) }

            VStack(alignment: .leading, spacing: 12) {
                Text("PHIM ĐÃ LƯU TRONG DANH SÁCH (\(favSlugs.count))")
                    .font(.system(size: 11.5, weight: .heavy))
                    .tracking(0.8)
                    .foregroundColor(KLTheme.textMuted)
                    .padding(.horizontal, 16)

                if favFilms.isEmpty {
                    VStack(spacing: 10) {
                        Image(systemName: "bookmark")
                            .font(.system(size: 32))
                            .foregroundColor(KLTheme.textMuted)
                        Text("Chưa có phim nào được lưu vào danh sách")
                            .font(.system(size: 12.5, weight: .medium))
                            .foregroundColor(KLTheme.textSecondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 30)
                } else {
                    LazyVGrid(columns: [
                        GridItem(.flexible(), spacing: 10),
                        GridItem(.flexible(), spacing: 10),
                        GridItem(.flexible(), spacing: 10)
                    ], spacing: 14) {
                        ForEach(favFilms) { film in
                            Button {
                                KLHaptics.light()
                                selectedFilmForEpisodes = film
                            } label: {
                                PosterCell(film: film)
                            }
                            .buttonStyle(KLScaleButtonStyle())
                        }
                    }
                    .padding(.horizontal, 16)
                }
            }
        }
    }

    // MARK: - Actions & Category Switching
    private func selectCategory(_ slug: String) async {
        selectedFilter = slug
        categoryLoadingTask?.cancel()

        if slug == "tat-ca" {
            if sections.isEmpty {
                await loadHomeSections()
            }
        } else if slug == "lich-su" {
            // Local watch history & bookmarks view
        } else {
            isLoadingCategory = true

            // Fast 0ms cache retrieval
            if let cached = PhimService.shared.getCachedCategory(slug: slug), !cached.isEmpty {
                self.categoryFilms = cached
                self.isLoadingCategory = false
            }

            categoryLoadingTask = Task {
                let list = await PhimService.shared.fetchCategoryFilms(slug: slug)
                if !Task.isCancelled {
                    await MainActor.run {
                        self.categoryFilms = list
                        self.isLoadingCategory = false
                    }
                }
            }
        }
    }

    private func loadHomeSections() async {
        isLoading = true
        let initial = await PhimService.shared.fetchQuickInitialSections()
        if !initial.isEmpty {
            sections = initial
            featuredFilms = Array((initial.first?.films ?? []).prefix(10))
            heroIndex = 0
            isLoading = false
        }

        let full = await PhimService.shared.fetchHomeSections()
        if !full.isEmpty {
            sections = full
            if featuredFilms.isEmpty {
                featuredFilms = Array((full.first?.films ?? []).prefix(10))
            }
        }
        isLoading = false
    }

    private func navigateToSectionCategory(sectionTitle: String) {
        KLHaptics.selection()
        let targetSlug: String
        if sectionTitle.contains("Mới") { targetSlug = "phim-moi" }
        else if sectionTitle.contains("Bộ") { targetSlug = "phim-bo" }
        else if sectionTitle.contains("Lẻ") { targetSlug = "phim-le" }
        else if sectionTitle.contains("Hoạt Hình") { targetSlug = "hoat-hinh" }
        else if sectionTitle.contains("Hàn Quốc") { targetSlug = "han-quoc" }
        else if sectionTitle.contains("Trung Quốc") { targetSlug = "trung-quoc" }
        else if sectionTitle.contains("Âu Mỹ") { targetSlug = "au-my" }
        else if sectionTitle.contains("Hành Động") { targetSlug = "hanh-dong" }
        else { targetSlug = "tat-ca" }

        Task { await selectCategory(targetSlug) }
    }

    private func performSearch(query: String) {
        searchTask?.cancel()
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            searchResults = []
            isSearching = false
            return
        }

        isSearching = true
        searchTask = Task {
            try? await Task.sleep(nanoseconds: 350_000_000)
            guard !Task.isCancelled else { return }
            let results = await PhimService.shared.searchFilms(keyword: trimmed)
            if !Task.isCancelled {
                searchResults = results
                isSearching = false
            }
        }
    }
}

// MARK: - Curated Collection Item Model
private struct CuratedCollection: Identifiable {
    var id: String { title }
    let title: String
    let countText: String
    let gradient: [Color]
    let categorySlug: String
    let searchKeyword: String
}

// MARK: - Standard Poster Cell (2:3 Aspect Ratio)
private struct PosterCell: View {
    let film: FilmItem

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            ZStack {
                AsyncImage(url: URL(string: film.posterUrl.isEmpty ? film.thumbUrl : film.posterUrl)) { phase in
                    if let img = phase.image {
                        img
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } else {
                        KLTheme.surfaceCard
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 155)
                .clipped()

                // Corner Badges Overlay
                VStack {
                    HStack {
                        Text("★ \(film.imdbScore)")
                            .font(.system(size: 9, weight: .heavy, design: .rounded))
                            .foregroundColor(KLTheme.imdbGold)
                            .padding(.horizontal, 4.5)
                            .padding(.vertical, 2)
                            .background(Color.black.opacity(0.80))
                            .cornerRadius(3.5)

                        Spacer()

                        Text(film.quality)
                            .font(.system(size: 8.5, weight: .black))
                            .foregroundColor(.white)
                            .padding(.horizontal, 4.5)
                            .padding(.vertical, 2)
                            .background(KLTheme.netflixRed)
                            .cornerRadius(3.5)
                    }
                    .padding(5)

                    Spacer()

                    HStack {
                        Text(film.currentEpisode.isEmpty ? "Full" : film.currentEpisode)
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 5)
                            .padding(.vertical, 2)
                            .background(Color.black.opacity(0.80))
                            .cornerRadius(3.5)
                        Spacer()
                    }
                    .padding(5)
                }
            }
            .frame(height: 155)
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.white.opacity(0.12), lineWidth: 0.8)
            )

            Text(film.name)
                .font(.system(size: 11.5, weight: .bold))
                .foregroundColor(.white)
                .lineLimit(1)

            Text("\(film.year) · \(film.language)")
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(KLTheme.textMuted)
                .lineLimit(1)
        }
    }
}

// MARK: - Continue Watching Rail
private struct ContinueWatchingRail: View {
    let items: [WatchProgress]
    let onTap: (WatchProgress) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 11) {
            KLSectionHeader(
                title: "Tiếp Tục Xem",
                subtitle: "Khôi phục ngay tập phim đang xem dở",
                trailingText: "\(items.count) PHIM",
                accentColor: KLTheme.brandOrange
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
                                        .foregroundColor(KLTheme.brandOrange)
                                    Spacer()
                                    Text("\(Int(item.progressPercent * 100))%")
                                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                                        .foregroundColor(KLTheme.textSecondary)
                                }

                                Text(item.filmName)
                                    .font(.system(size: 13.5, weight: .bold))
                                    .foregroundColor(.white)
                                    .lineLimit(1)

                                Text(item.episodeName)
                                    .font(.system(size: 11, weight: .medium))
                                    .foregroundColor(KLTheme.textSecondary)

                                GeometryReader { geo in
                                    ZStack(alignment: .leading) {
                                        Capsule()
                                            .fill(Color.white.opacity(0.16))
                                            .frame(height: 4)
                                        Capsule()
                                            .fill(KLTheme.brandOrange)
                                            .frame(width: geo.size.width * max(0.08, item.progressPercent), height: 4)
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
                        .buttonStyle(KLScaleButtonStyle())
                    }
                }
                .padding(.horizontal, 16)
            }
        }
    }
}
