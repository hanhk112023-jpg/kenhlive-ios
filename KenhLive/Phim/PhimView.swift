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

    // Category Loading & Pagination State
    @State private var isLoadingCategory: Bool = false
    @State private var categoryLoadingTask: Task<Void, Never>? = nil
    @State private var categoryPage: Int = 1
    @State private var canLoadMoreCategory: Bool = true
    @State private var isLoadingMoreCategory: Bool = false

    // Search state
    @State private var searchQuery: String = ""
    @State private var searchResults: [FilmItem] = []
    @State private var isSearching: Bool = false
    @State private var searchTask: Task<Void, Never>? = nil

    @State private var selectedFilmForEpisodes: FilmItem? = nil
    @State private var initialResumeProgressForSheet: WatchProgress? = nil
    @State private var autoPlayForSheet: Bool = false
    @State private var isShowingSearchSheet: Bool = false
    @State private var directResumeItem: WatchProgress? = nil
    @State private var selectedCuratedCollection: CuratedCollection? = nil

    // Home Infinite Feed
    @State private var infiniteHomeFilms: [FilmItem] = []
    @State private var homePage: Int = 2
    @State private var canLoadMoreHome: Bool = true
    @State private var isLoadingHomeMore: Bool = false

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
            countText: "4 Đài Trực Tiếp",
            gradient: [Color(red: 0.95, green: 0.35, blue: 0.12), Color(red: 0.98, green: 0.55, blue: 0.15)],
            categorySlug: "sports",
            searchKeyword: "",
            iconName: "sportscourt.fill",
            subtitle: "Socolive · Cola · Gà Vàng"
        ),
        CuratedCollection(
            title: "Chiếu Rạp Hot",
            countText: "48+ Bom Tấn",
            gradient: [Color(red: 0.12, green: 0.45, blue: 0.85), Color(red: 0.25, green: 0.65, blue: 0.95)],
            categorySlug: "phim-chieu-rap",
            searchKeyword: "",
            iconName: "film.fill",
            subtitle: "Phòng vé mới nhất"
        ),
        CuratedCollection(
            title: "Phim Bộ Châu Á",
            countText: "K-Drama & Hoa Ngữ",
            gradient: [Color(red: 0.97, green: 0.18, blue: 0.45), Color(red: 0.65, green: 0.08, blue: 0.75)],
            categorySlug: "phim-bo",
            searchKeyword: "",
            iconName: "sparkles.tv.fill",
            subtitle: "Gây sốt màn ảnh"
        ),
        CuratedCollection(
            title: "Anime & Hoạt Hình",
            countText: "Vietsub 4K",
            gradient: [Color(red: 0.16, green: 0.68, blue: 0.56), Color(red: 0.10, green: 0.85, blue: 0.65)],
            categorySlug: "hoat-hinh",
            searchKeyword: "",
            iconName: "sparkles",
            subtitle: "Cập nhật tập mới nhất"
        ),
        CuratedCollection(
            title: "Siêu Anh Hùng",
            countText: "Vũ Trụ Marvel & DC",
            gradient: [Color(red: 0.48, green: 0.17, blue: 0.78), Color(red: 0.68, green: 0.25, blue: 0.92)],
            categorySlug: "au-my",
            searchKeyword: "",
            iconName: "shield.lefthalf.filled",
            subtitle: "Kỹ xảo đỉnh cao"
        ),
        CuratedCollection(
            title: "IMDb Top 100",
            countText: "Kinh Điển Thế Giới",
            gradient: [Color(red: 0.95, green: 0.65, blue: 0.15), Color(red: 0.98, green: 0.82, blue: 0.25)],
            categorySlug: "phim-le",
            searchKeyword: "",
            iconName: "star.fill",
            subtitle: "Điểm đánh giá cao nhất"
        ),
        CuratedCollection(
            title: "Hành Động Bom Tấn",
            countText: "Võ Thuật & Đua Xe",
            gradient: [Color(red: 0.92, green: 0.22, blue: 0.18), Color(red: 0.98, green: 0.45, blue: 0.22)],
            categorySlug: "hanh-dong",
            searchKeyword: "",
            iconName: "flame.fill",
            subtitle: "Kịch tính đến nghẹt thở"
        ),
        CuratedCollection(
            title: "Kinh Dị & Giật Gân",
            countText: "Ám Ảnh Cực Độ",
            gradient: [Color(red: 0.28, green: 0.12, blue: 0.45), Color(red: 0.45, green: 0.15, blue: 0.65)],
            categorySlug: "kinh-di",
            searchKeyword: "",
            iconName: "eye.trianglebadge.exclamationmark.fill",
            subtitle: "Rùng rợn thót tim"
        )
    ]

    private var currentHero: FilmItem? {
        guard !featuredFilms.isEmpty else { return sections.first?.films.first }
        return featuredFilms[heroIndex % featuredFilms.count]
    }

    var body: some View {
        ZStack(alignment: .top) {
            Color(red: 0.07, green: 0.07, blue: 0.09).ignoresSafeArea()

            // FPT Play Ambient Radiant Header Glow
            KLAmbientHeaderGlow(color: KLTheme.fptOrange, height: 320, opacity: 0.28)

            ScrollView(showsIndicators: false) {
                LazyVStack(alignment: .leading, spacing: 22) {
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
                await loadHomeSections(forceRefresh: true)
            }

            if isLoading && sections.isEmpty && categoryFilms.isEmpty {
                ProgressView()
                    .tint(KLTheme.brandOrange)
                    .scaleEffect(1.3)
            }
        }
        .sheet(item: $selectedCuratedCollection) { col in
            CuratedCollectionDetailSheet(collection: col)
        }
        .fullScreenCover(isPresented: $isShowingSearchSheet) {
            CinemaSearchView(onDismiss: {
                isShowingSearchSheet = false
            })
        }
        .fullScreenCover(item: $directResumeItem) { item in
            let directUrl = item.m3u8Url.isEmpty ? item.embedUrl : item.m3u8Url
            HLSPlayerView(
                title: item.filmName,
                subtitle: item.episodeName.isEmpty ? "Tiếp tục xem" : item.episodeName,
                directUrl: directUrl,
                filmSlug: item.filmSlug,
                initialTimeSeconds: Double(item.positionMs) / 1000.0,
                isFullscreen: true,
                onClose: {
                    directResumeItem = nil
                },
                onProgressUpdate: { currentSec, durationSec in
                    let posMs = Int64(currentSec * 1000)
                    let durMs = Int64(durationSec * 1000)
                    let updated = WatchProgress(
                        filmSlug: item.filmSlug,
                        filmName: item.filmName,
                        posterUrl: item.posterUrl,
                        episodeName: item.episodeName,
                        episodeSlug: item.episodeSlug,
                        embedUrl: item.embedUrl,
                        m3u8Url: item.m3u8Url,
                        positionMs: posMs,
                        durationMs: durMs > 0 ? durMs : item.durationMs,
                        updatedAt: Date()
                    )
                    storage.saveWatchProgress(updated)
                }
            )
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
                // Background Poster Art with High-Speed Instant RAM Cache
                KLAsyncImage(
                    url: hero.posterUrl.isEmpty ? hero.thumbUrl : hero.posterUrl,
                    contentMode: .fill
                )
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

                    // Dual Call-To-Action Buttons (FPT Play Style: "Xem Ngay" & "Chi tiết")
                    HStack(spacing: 12) {
                        Button {
                            KLHaptics.medium()
                            autoPlayForSheet = true
                            initialResumeProgressForSheet = storage.getProgress(for: hero.slug)
                            selectedFilmForEpisodes = hero
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: "play.fill")
                                    .font(.system(size: 13, weight: .bold))
                                Text("Xem Ngay")
                                    .font(.system(size: 13.5, weight: .bold))
                            }
                            .foregroundColor(.black)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 10)
                            .background(
                                LinearGradient(
                                    colors: [Color(red: 1.0, green: 0.58, blue: 0.20), Color(red: 1.0, green: 0.38, blue: 0.05)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .clipShape(Capsule())
                            .shadow(color: Color(red: 1.0, green: 0.38, blue: 0.05).opacity(0.45), radius: 8, y: 2)
                        }
                        .buttonStyle(.plain)

                        Button {
                            KLHaptics.light()
                            autoPlayForSheet = false
                            initialResumeProgressForSheet = storage.getProgress(for: hero.slug)
                            selectedFilmForEpisodes = hero
                        } label: {
                            HStack(spacing: 5) {
                                Image(systemName: "info.circle")
                                    .font(.system(size: 13, weight: .medium))
                                Text("Chi tiết")
                                    .font(.system(size: 13, weight: .semibold))
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 18)
                            .padding(.vertical, 10)
                            .background(Color.white.opacity(0.18))
                            .clipShape(Capsule())
                        }
                        .buttonStyle(.plain)
                    }
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
            .frame(height: 420)
            .overlay(alignment: .top) {
                // Top Header Bar (KenhLive Brand Logo + Search Button - scrolls WITH the page!)
                HStack(alignment: .center) {
                    HStack(spacing: 7) {
                        Image(systemName: "film.stack.fill")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(KLTheme.brandOrange)
                        Text("KENHLIVE")
                            .font(.system(size: 17, weight: .black, design: .rounded))
                            .tracking(1.4)
                            .foregroundColor(.white)
                    }

                    Spacer()

                    Button {
                        KLHaptics.selection()
                        isShowingSearchSheet = true
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "magnifyingglass")
                                .font(.system(size: 12.5, weight: .bold))
                            Text("Tìm kiếm")
                                .font(.system(size: 12, weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 7.5)
                        .background(Color.black.opacity(0.52))
                        .clipShape(Capsule())
                        .overlay(
                            Capsule().stroke(Color.white.opacity(0.25), lineWidth: 0.8)
                        )
                        .shadow(color: Color.black.opacity(0.5), radius: 6, x: 0, y: 2)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 16)
                .padding(.top, 54)
            }
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

            // Section B: Continue Watching Rail with Cinematic Film Cards (if history exists)
            if !storage.watchHistory.isEmpty {
                ContinueWatchingRail(items: storage.watchHistory) { item in
                    KLHaptics.medium()
                    directResumeItem = item
                }
            }

            // Section C: "Top tuần" (Trending Weekly Leaderboard with Large Numerals 1, 2, 3...)
            if let topWeekSection = sections.first {
                renderWeeklyLeaderboardSection(topWeekSection)
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

            // Section E: Infinite Discover Grid at bottom of Home Screen
            if !sections.isEmpty {
                renderHomeInfiniteFeedSection()
            }
        }
    }

    // MARK: - Section E: Home Infinite Feed
    @ViewBuilder
    private func renderHomeInfiniteFeedSection() -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(KLTheme.brandOrange)

                    Text("KHÁM PHÁ THÊM PHIM MỚI")
                        .font(.system(size: 14, weight: .heavy, design: .rounded))
                        .foregroundColor(.white)
                }

                Spacer()

                if isLoadingHomeMore {
                    ProgressView().tint(KLTheme.brandOrange).scaleEffect(0.8)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 10)

            LazyVGrid(
                columns: [
                    GridItem(.flexible(), spacing: 10),
                    GridItem(.flexible(), spacing: 10),
                    GridItem(.flexible(), spacing: 10)
                ],
                spacing: 14
            ) {
                ForEach(Array(infiniteHomeFilms.enumerated()), id: \.element.id) { index, film in
                    Button {
                        KLHaptics.light()
                        autoPlayForSheet = false
                        initialResumeProgressForSheet = nil
                        selectedFilmForEpisodes = film
                    } label: {
                        PosterCell(film: film)
                    }
                    .buttonStyle(KLScaleButtonStyle())
                    .onAppear {
                        if index >= infiniteHomeFilms.count - 4 {
                            Task { await loadMoreHomeFilms() }
                        }
                    }
                }
            }
            .padding(.horizontal, 16)

            if canLoadMoreHome {
                HStack(spacing: 8) {
                    ProgressView().tint(KLTheme.brandOrange).scaleEffect(0.9)
                    Text("Đang tải thêm phim...")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(KLTheme.textSecondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 22)
                .id("home_inf_footer_\(homePage)_\(infiniteHomeFilms.count)")
                .onAppear {
                    Task { await loadMoreHomeFilms() }
                }
            }
        }
    }

    private func loadMoreHomeFilms() async {
        guard !isLoadingHomeMore, canLoadMoreHome else { return }
        isLoadingHomeMore = true
        let nextPage = homePage + 1
        let more = await PhimService.shared.fetchCategoryFilms(slug: "phim-moi", page: nextPage)
        await MainActor.run {
            if more.isEmpty {
                self.canLoadMoreHome = false
            } else {
                let existing = Set(self.infiniteHomeFilms.map { $0.slug })
                let unique = more.filter { !existing.contains($0.slug) }
                if !unique.isEmpty {
                    self.infiniteHomeFilms.append(contentsOf: unique)
                }
                self.homePage = nextPage
                if more.count < 8 {
                    self.canLoadMoreHome = false
                }
            }
            self.isLoadingHomeMore = false
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
                LazyHStack(spacing: 12) {
                    ForEach(curatedCollections) { col in
                        Button {
                            KLHaptics.medium()
                            if col.categorySlug == "sports" {
                                onSelectTab?(.sports)
                            } else {
                                selectedCuratedCollection = col
                            }
                        } label: {
                            VStack(alignment: .leading, spacing: 0) {
                                HStack {
                                    ZStack {
                                        Circle()
                                            .fill(Color.white.opacity(0.22))
                                            .frame(width: 32, height: 32)
                                        Image(systemName: col.iconName)
                                            .font(.system(size: 14, weight: .bold))
                                            .foregroundColor(.white)
                                    }

                                    Spacer()

                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 10, weight: .heavy))
                                        .foregroundColor(Color.white.opacity(0.70))
                                        .frame(width: 22, height: 22)
                                        .background(Color.white.opacity(0.14))
                                        .clipShape(Circle())
                                }

                                Spacer(minLength: 8)

                                Text(col.title)
                                    .font(.system(size: 14.5, weight: .heavy, design: .rounded))
                                    .foregroundColor(.white)
                                    .lineLimit(1)

                                Text("\(col.subtitle) · \(col.countText)")
                                    .font(.system(size: 10.5, weight: .medium))
                                    .foregroundColor(Color.white.opacity(0.85))
                                    .lineLimit(1)
                                    .padding(.top, 2)
                            }
                            .padding(12)
                            .frame(width: 172, height: 102, alignment: .leading)
                            .background(
                                LinearGradient(
                                    colors: col.gradient,
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .cornerRadius(16)
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(Color.white.opacity(0.24), lineWidth: 0.8)
                            )
                            .shadow(color: col.gradient.first?.opacity(0.35) ?? .clear, radius: 8, x: 0, y: 4)
                        }
                        .buttonStyle(KLScaleButtonStyle())
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 4)
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
                    navigateToSectionCategory(sectionTitle: "Top Phim Thịnh Hành")
                } label: {
                    HStack(spacing: 4) {
                        Text("Xem tất cả")
                            .font(.system(size: 11.5, weight: .bold))
                            .foregroundColor(Color.white.opacity(0.65))

                        Image(systemName: "chevron.right")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.white)
                            .frame(width: 24, height: 24)
                            .background(Color.white.opacity(0.12))
                            .clipShape(Circle())
                    }
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 16)

            // Horizontal Scroll of Leaderboard Poster Cards
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: 14) {
                    ForEach(Array(section.films.prefix(20).enumerated()), id: \.element.id) { index, film in
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
                                    KLAsyncImage(
                                        url: film.posterUrl.isEmpty ? film.thumbUrl : film.posterUrl,
                                        contentMode: .fill
                                    )
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
                        HStack(spacing: 4) {
                            Text("Xem tất cả")
                                .font(.system(size: 11.5, weight: .bold))
                                .foregroundColor(Color.white.opacity(0.65))

                            Image(systemName: "chevron.right")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.white)
                                .frame(width: 24, height: 24)
                                .background(Color.white.opacity(0.12))
                                .clipShape(Circle())
                        }
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 16)

                // Horizontal Scroll
                ScrollView(.horizontal, showsIndicators: false) {
                    LazyHStack(spacing: 12) {
                        ForEach(films) { film in
                            Button {
                                onSelectFilm(film)
                            } label: {
                                VStack(alignment: .leading, spacing: 6) {
                                    ZStack(alignment: .bottomLeading) {
                                        KLAsyncImage(
                                            url: film.posterUrl.isEmpty ? film.thumbUrl : film.posterUrl,
                                            contentMode: .fill
                                        )
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

                // Auto-Trigger Infinite Scroll on Reach Bottom
                if canLoadMoreCategory && selectedFilter != "lich-su" {
                    HStack(spacing: 8) {
                        ProgressView()
                            .tint(KLTheme.brandOrange)
                            .scaleEffect(0.9)
                        Text("Đang nạp thêm phim trang \(categoryPage + 1)...")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(KLTheme.textSecondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 22)
                    .onAppear {
                        Task { await loadMoreCategoryFilms() }
                    }
                } else if !categoryFilms.isEmpty && selectedFilter != "lich-su" {
                    Text("Đã hiển thị toàn bộ danh sách")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(KLTheme.textMuted)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 20)
                }
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
        categoryPage = 1
        canLoadMoreCategory = true

        if slug == "tat-ca" {
            if sections.isEmpty {
                await loadHomeSections()
            }
        } else if slug == "lich-su" {
            // Local watch history & bookmarks view
            self.categoryFilms = storage.watchHistory.map { item in
                FilmItem(
                    name: item.filmName,
                    slug: item.filmSlug,
                    originalName: item.episodeName,
                    thumbUrl: item.posterUrl,
                    posterUrl: item.posterUrl,
                    quality: "HD",
                    year: ""
                )
            }
            self.isLoadingCategory = false
            self.canLoadMoreCategory = false
        } else {
            isLoadingCategory = true

            // Fast 0ms cache retrieval
            if let cached = PhimService.shared.getCachedCategory(slug: slug), !cached.isEmpty {
                self.categoryFilms = cached
                self.isLoadingCategory = false
            }

            categoryLoadingTask = Task {
                let list = await PhimService.shared.fetchCategoryFilms(slug: slug, page: 1)
                if !Task.isCancelled {
                    await MainActor.run {
                        self.categoryFilms = list
                        self.isLoadingCategory = false
                    }
                }
            }
        }
    }

    private func loadMoreCategoryFilms() async {
        guard !isLoadingCategory, !isLoadingMoreCategory, canLoadMoreCategory else { return }
        guard selectedFilter != "tat-ca" && selectedFilter != "lich-su" else { return }

        isLoadingMoreCategory = true
        let nextPage = categoryPage + 1
        let moreFilms = await PhimService.shared.fetchCategoryFilms(slug: selectedFilter, page: nextPage)
        await MainActor.run {
            if moreFilms.isEmpty {
                self.canLoadMoreCategory = false
            } else {
                let existingSlugs = Set(self.categoryFilms.map { $0.slug })
                let newUnique = moreFilms.filter { !existingSlugs.contains($0.slug) }
                if newUnique.isEmpty {
                    self.canLoadMoreCategory = false
                } else {
                    self.categoryFilms.append(contentsOf: newUnique)
                    self.categoryPage = nextPage
                }
            }
            self.isLoadingMoreCategory = false
        }
    }

    private func loadHomeSections(forceRefresh: Bool = false) async {
        isLoading = true
        if !forceRefresh {
            let initial = await PhimService.shared.fetchQuickInitialSections()
            if !initial.isEmpty {
                sections = initial
                featuredFilms = Array((initial.first?.films ?? []).prefix(15))
                heroIndex = 0
                isLoading = false
            }
        }

        let full = await PhimService.shared.fetchHomeSections(forceRefresh: forceRefresh)
        if !full.isEmpty {
            sections = full
            featuredFilms = Array((full.first?.films ?? []).prefix(15))
        }
        isLoading = false
    }

    private func navigateToSectionCategory(sectionTitle: String) {
        KLHaptics.selection()
        let targetSlug: String
        let grad: [Color]
        if sectionTitle.contains("Mới") {
            targetSlug = "phim-moi"
            grad = [Color(red: 0.95, green: 0.35, blue: 0.12), Color(red: 0.88, green: 0.12, blue: 0.20)]
        } else if sectionTitle.contains("Bộ") {
            targetSlug = "phim-bo"
            grad = [Color(red: 0.22, green: 0.55, blue: 0.95), Color(red: 0.12, green: 0.35, blue: 0.85)]
        } else if sectionTitle.contains("Lẻ") {
            targetSlug = "phim-le"
            grad = [Color(red: 0.88, green: 0.12, blue: 0.20), Color(red: 0.95, green: 0.45, blue: 0.15)]
        } else if sectionTitle.contains("Hoạt Hình") || sectionTitle.contains("Anime") {
            targetSlug = "hoat-hinh"
            grad = [Color(red: 0.95, green: 0.45, blue: 0.75), Color(red: 0.75, green: 0.20, blue: 0.85)]
        } else if sectionTitle.contains("Hàn Quốc") {
            targetSlug = "han-quoc"
            grad = [Color(red: 0.15, green: 0.75, blue: 0.75), Color(red: 0.12, green: 0.45, blue: 0.85)]
        } else if sectionTitle.contains("Trung Quốc") {
            targetSlug = "trung-quoc"
            grad = [Color(red: 0.85, green: 0.25, blue: 0.20), Color(red: 0.95, green: 0.65, blue: 0.15)]
        } else if sectionTitle.contains("Âu Mỹ") {
            targetSlug = "au-my"
            grad = [Color(red: 0.45, green: 0.35, blue: 0.95), Color(red: 0.25, green: 0.15, blue: 0.75)]
        } else if sectionTitle.contains("Hành Động") {
            targetSlug = "hanh-dong"
            grad = [Color(red: 0.95, green: 0.20, blue: 0.20), Color(red: 0.85, green: 0.45, blue: 0.15)]
        } else {
            targetSlug = "phim-moi"
            grad = [Color(red: 0.95, green: 0.35, blue: 0.12), Color(red: 0.88, green: 0.12, blue: 0.20)]
        }

        selectedCuratedCollection = CuratedCollection(
            title: sectionTitle,
            countText: "Khám phá trọn bộ",
            gradient: grad,
            categorySlug: targetSlug,
            searchKeyword: ""
        )
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
    var iconName: String = "film.fill"
    var subtitle: String = "Tuyển chọn"
}

// MARK: - Standard Poster Cell (2:3 Aspect Ratio)
private struct PosterCell: View {
    let film: FilmItem

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            ZStack {
                KLAsyncImage(
                    url: film.posterUrl.isEmpty ? film.thumbUrl : film.posterUrl,
                    contentMode: .fill
                )
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
        VStack(alignment: .leading, spacing: 12) {
            KLSectionHeader(
                title: "Tiếp Tục Xem",
                subtitle: "Khôi phục ngay tập phim đang xem dở",
                trailingText: "\(items.count) PHIM",
                accentColor: Color(red: 0.90, green: 0.22, blue: 0.28)
            )

            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: 14) {
                    ForEach(items) { item in
                        KLWatchHistoryCard(
                            item: item,
                            onPlay: { onTap(item) },
                            onDelete: {
                                withAnimation(.spring(response: 0.28, dampingFraction: 0.78)) {
                                    StorageManager.shared.removeWatchProgress(id: item.id)
                                }
                            }
                        )
                    }
                }
                .padding(.horizontal, 16)
            }
        }
    }
}

// MARK: - Curated Collection Detail Sheet
private struct CuratedCollectionDetailSheet: View {
    let collection: CuratedCollection
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var storage = StorageManager.shared
    @State private var films: [FilmItem] = []
    @State private var isLoading: Bool = true
    @State private var selectedFilm: FilmItem? = nil
    @State private var page: Int = 1
    @State private var canLoadMore: Bool = true
    @State private var isLoadingMore: Bool = false

    var body: some View {
        ZStack {
            Color(red: 0.08, green: 0.08, blue: 0.10).ignoresSafeArea()

            VStack(spacing: 0) {
                // Header Bar with Collection Gradient Accent
                HStack(alignment: .center) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text(collection.title.uppercased())
                            .font(.system(size: 17, weight: .heavy, design: .rounded))
                            .foregroundColor(.white)

                        Text("\(films.isEmpty ? collection.countText : "\(films.count) phim") · Khám phá trọn bộ")
                            .font(.system(size: 11.5, weight: .medium))
                            .foregroundColor(KLTheme.textSecondary)
                    }

                    Spacer()

                    Button {
                        KLHaptics.light()
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.white)
                            .frame(width: 32, height: 32)
                            .background(Color.white.opacity(0.18))
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .background(
                    LinearGradient(
                        colors: collection.gradient.map { $0.opacity(0.65) } + [Color.clear],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )

                if isLoading {
                    Spacer()
                    ProgressView()
                        .tint(KLTheme.brandOrange)
                        .scaleEffect(1.2)
                    Spacer()
                } else if films.isEmpty {
                    Spacer()
                    VStack(spacing: 12) {
                        Image(systemName: "film.stack")
                            .font(.system(size: 38))
                            .foregroundColor(KLTheme.textMuted)
                        Text("Chưa có phim trong bộ sưu tập này")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(KLTheme.textSecondary)
                    }
                    Spacer()
                } else {
                    ScrollView(showsIndicators: false) {
                        LazyVGrid(
                            columns: [
                                GridItem(.flexible(), spacing: 10),
                                GridItem(.flexible(), spacing: 10),
                                GridItem(.flexible(), spacing: 10)
                            ],
                            spacing: 14
                        ) {
                            ForEach(Array(films.enumerated()), id: \.element.id) { index, film in
                                Button {
                                    KLHaptics.light()
                                    selectedFilm = film
                                } label: {
                                    PosterCell(film: film)
                                }
                                .buttonStyle(KLScaleButtonStyle())
                                .onAppear {
                                    if index >= films.count - 4 {
                                        Task { await loadMoreFilms() }
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 12)

                        // Auto Infinite Load More Footer (Vuốt xuống tự load)
                        if canLoadMore && (!collection.categorySlug.isEmpty || !collection.searchKeyword.isEmpty) {
                            HStack(spacing: 8) {
                                ProgressView()
                                    .tint(KLTheme.brandOrange)
                                    .scaleEffect(0.9)
                                Text("Đang tải thêm phim trang \(page + 1)...")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(KLTheme.textSecondary)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 22)
                            .id("coll_footer_\(page)_\(films.count)")
                            .onAppear {
                                Task { await loadMoreFilms() }
                            }
                        } else if !films.isEmpty {
                            Text("Đã hiển thị toàn bộ danh sách")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(KLTheme.textMuted)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 20)
                        }

                        Spacer(minLength: 40)
                    }
                }
            }
        }
        .task {
            await loadCollectionFilms()
        }
        .sheet(item: $selectedFilm) { film in
            EpisodePickerSheet(
                film: film,
                initialResumeProgress: storage.getProgress(for: film.slug)
            )
        }
    }

    private func loadCollectionFilms() async {
        isLoading = true
        page = 1
        canLoadMore = true
        var results: [FilmItem] = []
        if !collection.categorySlug.isEmpty {
            results = await PhimService.shared.fetchCategoryFilms(slug: collection.categorySlug, page: 1)
        }
        if results.isEmpty && !collection.searchKeyword.isEmpty {
            results = await PhimService.shared.searchFilms(keyword: collection.searchKeyword, page: 1)
        }
        films = results
        isLoading = false
    }

    private func loadMoreFilms() async {
        guard !isLoading, !isLoadingMore, canLoadMore else { return }
        guard !collection.categorySlug.isEmpty || !collection.searchKeyword.isEmpty else { return }
        isLoadingMore = true
        let nextPage = page + 1
        let more: [FilmItem]
        if !collection.categorySlug.isEmpty {
            more = await PhimService.shared.fetchCategoryFilms(slug: collection.categorySlug, page: nextPage)
        } else {
            more = await PhimService.shared.searchFilms(keyword: collection.searchKeyword, page: nextPage)
        }

        await MainActor.run {
            if more.isEmpty {
                self.canLoadMore = false
            } else {
                let existing = Set(self.films.map { $0.slug })
                let unique = more.filter { !existing.contains($0.slug) }
                if !unique.isEmpty {
                    self.films.append(contentsOf: unique)
                }
                self.page = nextPage
                if more.count < 8 {
                    self.canLoadMore = false
                }
            }
            self.isLoadingMore = false
        }
    }
}
