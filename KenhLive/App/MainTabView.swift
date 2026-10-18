import SwiftUI

// MARK: - Cinema Netflix / Liquid Glass 3-Tab Navigation (Focus Phim & Thể Thao)
enum KLTab: Int, CaseIterable, Identifiable {
    case home = 0       // "Rạp Phim" (Kho Phim Cinema)
    case sports = 1     // "Thể thao" (Socolive, ColaTV, Gà Vàng, Giờ Vàng)
    case profile = 2    // "Cá nhân" (Tiếp tục xem, Lịch đá, Báo lỗi, Cài đặt)

    // Backward-compatibility aliases for legacy portals & services
    static let live = KLTab.sports
    static let phim = KLTab.home
    static let iptv = KLTab.sports
    static let search = KLTab.home
    static let library = KLTab.profile
    static let settings = KLTab.profile

    var id: Int { rawValue }

    var title: String {
        switch self {
        case .home: return "Rạp Phim"
        case .sports: return "Thể thao"
        case .profile: return "Cá nhân"
        }
    }

    var iconName: String {
        switch self {
        case .home: return "film.fill"
        case .sports: return "sportscourt.fill"
        case .profile: return "person.fill"
        }
    }
}

struct MainTabView: View {
    @State private var selectedTab: KLTab = .home
    @Namespace private var tabNamespace
    @State private var isShowingTelegramSheet: Bool = false
    @State private var isShowingSchedule: Bool = false
    @AppStorage("seen_notice_v140") private var seenNoticeV140: Bool = false

    var body: some View {
        ZStack(alignment: .bottom) {
            Color(red: 0.07, green: 0.07, blue: 0.09).ignoresSafeArea()

            // 1. Tab View Content (Persistent in Memory: 0ms Switch Latency, No View Rebuilds)
            ZStack {
                PhimView(
                    onSelectTab: { targetTab in
                        withAnimation(.spring(response: 0.28, dampingFraction: 0.78)) {
                            selectedTab = targetTab
                        }
                    }
                )
                .opacity(selectedTab == .home ? 1 : 0)
                .allowsHitTesting(selectedTab == .home)

                LiveSportsView(isActive: selectedTab == .sports)
                    .opacity(selectedTab == .sports ? 1 : 0)
                    .allowsHitTesting(selectedTab == .sports)

                CinemaProfileView(
                    onOpenSchedule: { isShowingSchedule = true },
                    onOpenTelegram: { isShowingTelegramSheet = true }
                )
                .opacity(selectedTab == .profile ? 1 : 0)
                .allowsHitTesting(selectedTab == .profile)
            }
            .animation(.easeInOut(duration: 0.16), value: selectedTab)
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            // 2. Animated Floating Glass Dock Tab Bar (Safely Aligned to Bottom)
            renderFloatingDockTabBar()
        }
        .edgesIgnoringSafeArea(.all)
        .sheet(isPresented: $isShowingTelegramSheet) {
            TelegramFeedbackSheet()
        }
        .sheet(isPresented: $isShowingSchedule) {
            ScheduleView()
        }
        .onAppear {
            if !seenNoticeV140 {
                seenNoticeV140 = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                    isShowingTelegramSheet = true
                }
            }
        }
    }

    // MARK: - Safe Bottom Floating Dock Tab Bar (Full Hitbox, Instant Response)
    @ViewBuilder
    private func renderFloatingDockTabBar() -> some View {
        HStack(spacing: 0) {
            ForEach(KLTab.allCases) { tab in
                let isActive = selectedTab == tab
                Button {
                    KLHaptics.selection()
                    withAnimation(.spring(response: 0.28, dampingFraction: 0.78)) {
                        selectedTab = tab
                    }
                } label: {
                    ZStack {
                        if isActive {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            Color(red: 1.0, green: 0.38, blue: 0.16),
                                            Color(red: 0.88, green: 0.10, blue: 0.16)
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 40, height: 40)
                                .shadow(color: Color(red: 1.0, green: 0.38, blue: 0.16).opacity(0.45), radius: 8, x: 0, y: 2)
                        }

                        Image(systemName: tab.iconName)
                            .font(.system(size: isActive ? 18 : 17, weight: isActive ? .bold : .medium))
                            .foregroundColor(isActive ? .white : Color(white: 0.52))
                            .scaleEffect(isActive ? 1.15 : 1.0)
                            .animation(.spring(response: 0.28, dampingFraction: 0.65), value: isActive)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
        .frame(height: 52)
        .padding(.horizontal, 6)
        .background(
            RoundedRectangle(cornerRadius: 30)
                .fill(Color(red: 0.11, green: 0.11, blue: 0.13).opacity(0.96))
                .overlay(
                    RoundedRectangle(cornerRadius: 30)
                        .stroke(
                            LinearGradient(
                                colors: [Color.white.opacity(0.20), Color.white.opacity(0.06)],
                                startPoint: .top,
                                endPoint: .bottom
                            ),
                            lineWidth: 0.8
                        )
                )
                .shadow(color: Color.black.opacity(0.70), radius: 18, x: 0, y: 8)
        )
        .padding(.horizontal, 20)
        .padding(.bottom, 16)
    }
}

// MARK: - Dedicated Cinema Search View
struct CinemaSearchView: View {
    @ObservedObject private var storage = StorageManager.shared
    var onDismiss: (() -> Void)? = nil
    @State private var searchKeyword: String = ""
    @State private var selectedCategory: String = "tat-ca"
    @State private var matchedFilms: [FilmItem] = []
    @State private var categoryFilms: [FilmItem] = []
    @State private var trendingFilms: [FilmItem] = []
    @State private var isSearching: Bool = false
    @State private var isLoadingCategory: Bool = false
    @State private var categoryPage: Int = 1
    @State private var canLoadMoreCategory: Bool = true
    @State private var isLoadingMoreCategory: Bool = false
    @State private var searchTask: Task<Void, Never>? = nil
    @State private var categoryTask: Task<Void, Never>? = nil
    @State private var selectedFilm: FilmItem? = nil

    private let trendingChips = [
        "One Piece", "Conan", "Solo Leveling", "Bleach", "Marvel", "Batman",
        "Doraemon", "Naruto", "Squid Game", "Chiếu Rạp", "Avengers", "John Wick"
    ]

    private struct ThemedSearchTopic: Identifiable {
        var id: String { title }
        let title: String
        let subtitle: String
        let icon: String
        let slug: String
        let gradient: [Color]
    }

    private let themedTopics: [ThemedSearchTopic] = [
        ThemedSearchTopic(title: "Chiếu Rạp Hot", subtitle: "Bom tấn 4K mới", icon: "film.fill", slug: "phim-le", gradient: [Color(red: 0.88, green: 0.15, blue: 0.20), Color(red: 0.98, green: 0.45, blue: 0.15)]),
        ThemedSearchTopic(title: "Phim Bộ Châu Á", subtitle: "K-Drama & Hoa Ngữ", icon: "sparkles.tv.fill", slug: "phim-bo", gradient: [Color(red: 0.95, green: 0.18, blue: 0.52), Color(red: 0.65, green: 0.08, blue: 0.78)]),
        ThemedSearchTopic(title: "Anime & Hoạt Hình", subtitle: "Vietsub tập mới", icon: "sparkles", slug: "hoat-hinh", gradient: [Color(red: 0.16, green: 0.68, blue: 0.56), Color(red: 0.10, green: 0.85, blue: 0.65)]),
        ThemedSearchTopic(title: "Võ Thuật & Hành Động", subtitle: "Nghẹt thở gay cấn", icon: "flame.fill", slug: "hanh-dong", gradient: [Color(red: 0.95, green: 0.35, blue: 0.12), Color(red: 0.98, green: 0.60, blue: 0.15)])
    ]

    private let movieCategoryPills: [KLFilterItem<String>] = [
        KLFilterItem(id: "tat-ca", title: "Tất Cả Phim"),
        KLFilterItem(id: "phim-moi", title: "Mới Cập Nhật"),
        KLFilterItem(id: "phim-le", title: "Phim Lẻ Rạp"),
        KLFilterItem(id: "phim-bo", title: "Phim Bộ Hot"),
        KLFilterItem(id: "hoat-hinh", title: "Hoạt Hình & Anime"),
        KLFilterItem(id: "han-quoc", title: "Hàn Quốc"),
        KLFilterItem(id: "trung-quoc", title: "Trung Quốc"),
        KLFilterItem(id: "au-my", title: "Âu Mỹ Bom Tấn"),
        KLFilterItem(id: "hanh-dong", title: "Hành Động"),
        KLFilterItem(id: "co-trang", title: "Cổ Trang"),
        KLFilterItem(id: "kinh-di", title: "Kinh Dị")
    ]

    var body: some View {
        ZStack {
            Color(red: 0.07, green: 0.07, blue: 0.09).ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 18) {
                    // Header with Optional Back Button
                    HStack(spacing: 12) {
                        if let onDismiss = onDismiss {
                            Button {
                                KLHaptics.light()
                                onDismiss()
                            } label: {
                                Image(systemName: "chevron.left")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(.white)
                                    .frame(width: 38, height: 38)
                                    .background(Color.white.opacity(0.10))
                                    .clipShape(Circle())
                            }
                            .buttonStyle(.plain)
                        }

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Tìm Kiếm Phim")
                                .font(.system(size: 24, weight: .heavy, design: .rounded))
                                .foregroundColor(.white)
                            Text("Kho phim KKPhim & NguonC chất lượng 4K")
                                .font(.system(size: 11.5, weight: .medium))
                                .foregroundColor(KLTheme.textMuted)
                        }

                        Spacer()

                        KLPillBadge(
                            text: "CINEMA 4K",
                            fg: Color(red: 0.96, green: 0.77, blue: 0.10),
                            bg: Color(red: 0.96, green: 0.77, blue: 0.10).opacity(0.14),
                            border: Color(red: 0.96, green: 0.77, blue: 0.10).opacity(0.35)
                        )
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 54)

                    // Search Bar
                    KLGlassSearchBar(
                        text: $searchKeyword,
                        placeholder: "Tìm tên phim, diễn viên, anime (One Piece, Conan, Marvel...)"
                    )
                    .padding(.horizontal, 16)
                    .onChange(of: searchKeyword) { kw in
                        triggerSearch(query: kw)
                    }

                    // Trending Movie Chips
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            Text("🔥")
                                .font(.system(size: 13))

                            ForEach(trendingChips, id: \.self) { chip in
                                Button {
                                    KLHaptics.light()
                                    searchKeyword = chip
                                    triggerSearch(query: chip)
                                } label: {
                                    Text(chip)
                                        .font(.system(size: 11.5, weight: .medium))
                                        .foregroundColor(Color.white.opacity(0.85))
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 5)
                                        .background(Color.white.opacity(0.10))
                                        .cornerRadius(12)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal, 16)
                    }

                    // Themed Topics (Bento Grid: Bạn quan tâm gì?)
                    if searchKeyword.trimmingCharacters(in: .whitespaces).isEmpty {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("CHỦ ĐỀ BẠN QUAN TÂM 🌟")
                                .font(.system(size: 11, weight: .heavy))
                                .tracking(0.8)
                                .foregroundColor(KLTheme.textMuted)
                                .padding(.horizontal, 16)

                            LazyVGrid(columns: [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)], spacing: 10) {
                                ForEach(themedTopics) { topic in
                                    Button {
                                        KLHaptics.medium()
                                        selectedCategory = topic.slug
                                        categoryPage = 1
                                        canLoadMoreCategory = true
                                        Task { await selectCategory(topic.slug) }
                                    } label: {
                                        HStack(spacing: 10) {
                                            ZStack {
                                                Circle()
                                                    .fill(Color.white.opacity(0.20))
                                                    .frame(width: 32, height: 32)
                                                Image(systemName: topic.icon)
                                                    .font(.system(size: 14, weight: .bold))
                                                    .foregroundColor(.white)
                                            }

                                            VStack(alignment: .leading, spacing: 2) {
                                                Text(topic.title)
                                                    .font(.system(size: 13, weight: .bold))
                                                    .foregroundColor(.white)
                                                    .lineLimit(1)
                                                Text(topic.subtitle)
                                                    .font(.system(size: 10, weight: .medium))
                                                    .foregroundColor(Color.white.opacity(0.80))
                                                    .lineLimit(1)
                                            }
                                            Spacer()
                                        }
                                        .padding(10)
                                        .background(
                                            LinearGradient(
                                                colors: topic.gradient,
                                                startPoint: .leading,
                                                endPoint: .trailing
                                            )
                                        )
                                        .cornerRadius(14)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 14)
                                                .stroke(Color.white.opacity(0.20), lineWidth: 0.8)
                                        )
                                    }
                                    .buttonStyle(KLScaleButtonStyle())
                                }
                            }
                            .padding(.horizontal, 16)
                        }

                        // Movie Category Filter Strip
                        KLFilterStrip(items: movieCategoryPills, selection: $selectedCategory) { newCat in
                            categoryPage = 1
                            canLoadMoreCategory = true
                            Task { await selectCategory(newCat) }
                        }
                    }

                    // Results or Category Grid
                    if isSearching {
                        HStack {
                            Spacer()
                            ProgressView().tint(KLTheme.brandOrange).scaleEffect(1.2)
                            Spacer()
                        }
                        .padding(.top, 40)
                    } else if !searchKeyword.trimmingCharacters(in: .whitespaces).isEmpty {
                        renderSearchResultsGrid()
                    } else {
                        renderCategoryOrSuggestedGrid()
                    }

                    Spacer(minLength: 120)
                }
            }
        }
        .task {
            if trendingFilms.isEmpty {
                await loadInitialFilms()
            }
        }
        .sheet(item: $selectedFilm) { film in
            EpisodePickerSheet(
                film: film,
                initialResumeProgress: storage.getProgress(for: film.slug)
            )
        }
    }

    @ViewBuilder
    private func renderSearchResultsGrid() -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("KẾT QUẢ TÌM KIẾM")
                    .font(.system(size: 11, weight: .heavy))
                    .tracking(0.8)
                    .foregroundColor(KLTheme.textMuted)

                Spacer()

                Text("\(matchedFilms.count) PHIM")
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundColor(KLTheme.imdbGold)
            }
            .padding(.horizontal, 16)

            if matchedFilms.isEmpty {
                VStack(spacing: 10) {
                    Image(systemName: "film.stack")
                        .font(.system(size: 36))
                        .foregroundColor(Color.white.opacity(0.3))
                    Text("Không tìm thấy phim phù hợp với \"\(searchKeyword)\"")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(KLTheme.textMuted)
                }
                .frame(maxWidth: .infinity)
                .padding(.top, 40)
            } else {
                renderMoviePostersGrid(films: matchedFilms)
            }
        }
    }

    @ViewBuilder
    private func renderCategoryOrSuggestedGrid() -> some View {
        VStack(alignment: .leading, spacing: 14) {
            let activeTitle = movieCategoryPills.first(where: { $0.id == selectedCategory })?.title ?? "Phim Đề Xuất"
            HStack {
                Text(activeTitle.uppercased())
                    .font(.system(size: 11.5, weight: .heavy))
                    .tracking(0.8)
                    .foregroundColor(KLTheme.textMuted)

                Spacer()

                if isLoadingCategory {
                    ProgressView().tint(KLTheme.brandOrange).scaleEffect(0.8)
                } else {
                    let count = selectedCategory == "tat-ca" ? trendingFilms.count : categoryFilms.count
                    Text("\(count) PHIM")
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .foregroundColor(KLTheme.imdbGold)
                }
            }
            .padding(.horizontal, 16)

            let displayFilms = selectedCategory == "tat-ca" ? trendingFilms : categoryFilms
            if isLoadingCategory && displayFilms.isEmpty {
                LazyVGrid(columns: [
                    GridItem(.flexible(), spacing: 10),
                    GridItem(.flexible(), spacing: 10),
                    GridItem(.flexible(), spacing: 10)
                ], spacing: 14) {
                    ForEach(0..<12, id: \.self) { _ in
                        VStack(alignment: .leading, spacing: 6) {
                            KLSkeletonView(height: 155, cornerRadius: 8)
                            KLSkeletonView(height: 12, cornerRadius: 3)
                        }
                    }
                }
                .padding(.horizontal, 16)
            } else {
                renderMoviePostersGrid(films: displayFilms)

                // Auto Infinite Load More Footer (Vuốt xuống tự load không cần ấn nút)
                if canLoadMoreCategory && selectedCategory != "tat-ca" {
                    HStack(spacing: 8) {
                        ProgressView()
                            .tint(KLTheme.brandOrange)
                            .scaleEffect(0.9)
                        Text("Đang tải thêm phim trang \(categoryPage + 1)...")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(KLTheme.textSecondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 22)
                    .id("search_footer_\(categoryPage)_\(displayFilms.count)")
                    .onAppear {
                        Task { await loadMoreCategoryFilms() }
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func renderMoviePostersGrid(films: [FilmItem]) -> some View {
        LazyVGrid(columns: [
            GridItem(.flexible(), spacing: 10),
            GridItem(.flexible(), spacing: 10),
            GridItem(.flexible(), spacing: 10)
        ], spacing: 14) {
            ForEach(Array(films.enumerated()), id: \.element.id) { index, film in
                Button {
                    KLHaptics.light()
                    selectedFilm = film
                } label: {
                    VStack(alignment: .leading, spacing: 5) {
                        ZStack {
                            KLAsyncImage(
                                url: film.posterUrl.isEmpty ? film.thumbUrl : film.posterUrl,
                                contentMode: .fill
                            )
                            .frame(maxWidth: .infinity)
                            .frame(height: 155)
                            .clipped()

                            // Badges Overlay
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
                                        .font(.system(size: 8.5, weight: .bold))
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
                .buttonStyle(KLScaleButtonStyle())
                .onAppear {
                    if index >= films.count - 4 {
                        Task { await loadMoreCategoryFilms() }
                    }
                }
            }
        }
        .padding(.horizontal, 16)
    }

    private func triggerSearch(query: String) {
        searchTask?.cancel()
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            matchedFilms = []
            isSearching = false
            return
        }

        isSearching = true
        searchTask = Task {
            try? await Task.sleep(nanoseconds: 300_000_000)
            guard !Task.isCancelled else { return }
            let films = await PhimService.shared.searchFilms(keyword: trimmed)
            if !Task.isCancelled {
                await MainActor.run {
                    self.matchedFilms = films
                    self.isSearching = false
                }
            }
        }
    }

    private func selectCategory(_ slug: String) async {
        selectedCategory = slug
        categoryPage = 1
        canLoadMoreCategory = true
        categoryTask?.cancel()
        guard slug != "tat-ca" else { return }

        isLoadingCategory = true
        if let cached = PhimService.shared.getCachedCategory(slug: slug), !cached.isEmpty {
            self.categoryFilms = cached
            self.isLoadingCategory = false
            return
        }

        categoryTask = Task {
            let films = await PhimService.shared.fetchCategoryFilms(slug: slug)
            if !Task.isCancelled {
                await MainActor.run {
                    self.categoryFilms = films
                    self.isLoadingCategory = false
                }
            }
        }
    }

    private func loadMoreCategoryFilms() async {
        guard !isLoadingCategory, !isLoadingMoreCategory, canLoadMoreCategory, selectedCategory != "tat-ca" else { return }
        isLoadingMoreCategory = true
        let nextPage = categoryPage + 1
        let more = await PhimService.shared.fetchCategoryFilms(slug: selectedCategory, page: nextPage)
        await MainActor.run {
            if more.isEmpty {
                self.canLoadMoreCategory = false
            } else {
                let existing = Set(self.categoryFilms.map { $0.slug })
                let unique = more.filter { !existing.contains($0.slug) }
                if !unique.isEmpty {
                    self.categoryFilms.append(contentsOf: unique)
                }
                self.categoryPage = nextPage
                if more.count < 8 {
                    self.canLoadMoreCategory = false
                }
            }
            self.isLoadingMoreCategory = false
        }
    }

    private func loadInitialFilms() async {
        let initial = await PhimService.shared.fetchQuickInitialSections()
        if let first = initial.first {
            trendingFilms = first.films
        }
    }
}

// MARK: - Dedicated Cinema Profile View (Tab 4: "Cá nhân")
struct CinemaProfileView: View {
    let onOpenSchedule: () -> Void
    let onOpenTelegram: () -> Void

    @ObservedObject private var storage = StorageManager.shared
    @State private var selectedFilm: FilmItem? = nil
    @State private var directResumeItem: WatchProgress? = nil
    @AppStorage("kl_stream_quality") private var selectedQuality: String = "Tự động (FHD)"
    @State private var isCacheCleared: Bool = false
    @State private var cacheSizeText: String = ""

    private let qualityOptions = ["Tự động (FHD)", "Cao (1080p)", "Ổn định (720p)"]

    var body: some View {
        ZStack {
            Color(red: 0.07, green: 0.07, blue: 0.09).ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 22) {
                    // 1. VIP Member Obsidian Glass Header Card
                    renderProfileHeaderCard()

                    // 2. Consolidated Watch History (1 bộ gộp vào 1 card duy nhất)
                    renderConsolidatedHistorySection()

                    // 3. Direct Utilities & Quality Settings (Grouped Inset)
                    renderUtilitiesSection()

                    // 4. Data & System Maintenance
                    renderDataAndMaintenanceSection()

                    // 5. Version Footer
                    renderFooter()

                    Spacer(minLength: 120)
                }
            }
        }
        .onAppear {
            cacheSizeText = storage.getFormattedCacheSize()
        }
        .sheet(item: $selectedFilm) { film in
            EpisodePickerSheet(
                film: film,
                initialResumeProgress: storage.getProgress(for: film.slug)
            )
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
    }

    // MARK: - Profile Header Card
    @ViewBuilder
    private func renderProfileHeaderCard() -> some View {
        VStack(spacing: 14) {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color(red: 0.95, green: 0.65, blue: 0.15), Color(red: 0.95, green: 0.25, blue: 0.18)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 58, height: 58)
                        .overlay(
                            Circle()
                                .stroke(Color.white.opacity(0.35), lineWidth: 1.2)
                        )
                        .shadow(color: Color(red: 0.95, green: 0.45, blue: 0.15).opacity(0.4), radius: 8, x: 0, y: 3)

                    Image(systemName: "crown.fill")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.white)
                }

                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Text("KenhLive Member")
                            .font(.system(size: 19, weight: .heavy, design: .rounded))
                            .foregroundColor(.white)

                        Image(systemName: "checkmark.seal.fill")
                            .font(.system(size: 14))
                            .foregroundColor(Color(red: 0.96, green: 0.77, blue: 0.10))
                    }

                    Text("VIP Cinema & Sports Access · Trọn Đời")
                        .font(.system(size: 11.5, weight: .bold))
                        .foregroundColor(Color(red: 0.96, green: 0.77, blue: 0.10))
                }

                Spacer()
            }

            // Quick Bento Stats (3 Cards)
            HStack(spacing: 10) {
                bentoStatTile(
                    title: "BỘ PHIM ĐÃ LƯU",
                    value: "\(storage.consolidatedWatchHistory.count)",
                    icon: "film.stack.fill",
                    accent: Color(red: 0.95, green: 0.45, blue: 0.15)
                )

                bentoStatTile(
                    title: "TỔNG TẬP ĐÃ XEM",
                    value: "\(storage.watchHistory.count)",
                    icon: "play.tv.fill",
                    accent: Color(red: 0.22, green: 0.65, blue: 0.95)
                )

                bentoStatTile(
                    title: "BỘ NHỚ ĐỆM",
                    value: cacheSizeText.isEmpty ? storage.getFormattedCacheSize() : cacheSizeText,
                    icon: "bolt.fill",
                    accent: Color(red: 0.96, green: 0.77, blue: 0.10)
                )
            }
        }
        .padding(16)
        .background(Color(red: 0.11, green: 0.11, blue: 0.14))
        .cornerRadius(20)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(
                    LinearGradient(
                        colors: [Color.white.opacity(0.18), Color.white.opacity(0.04)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 0.8
                )
        )
        .padding(.horizontal, 16)
        .padding(.top, 54)
    }

    @ViewBuilder
    private func bentoStatTile(title: String, value: String, icon: String, accent: Color) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(accent)
                Text(title)
                    .font(.system(size: 8.5, weight: .heavy))
                    .foregroundColor(KLTheme.textMuted)
                    .lineLimit(1)
            }
            Text(value)
                .font(.system(size: 15, weight: .black, design: .rounded))
                .foregroundColor(.white)
                .lineLimit(1)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 9)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white.opacity(0.04))
        .cornerRadius(12)
    }

    // MARK: - Consolidated Watch History (1 bộ gộp vào 1 card duy nhất)
    @ViewBuilder
    private func renderConsolidatedHistorySection() -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "clock.arrow.circlepath")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(KLTheme.brandOrange)

                    Text("LỊCH SỬ XEM & TIẾP TỤC")
                        .font(.system(size: 13, weight: .heavy, design: .rounded))
                        .foregroundColor(.white)
                }

                Spacer()

                if !storage.consolidatedWatchHistory.isEmpty {
                    Button {
                        KLHaptics.selection()
                        withAnimation(.spring(response: 0.28, dampingFraction: 0.78)) {
                            storage.clearWatchHistory()
                        }
                    } label: {
                        Text("Xóa tất cả")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(Color(red: 0.88, green: 0.25, blue: 0.30))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(Color(red: 0.88, green: 0.25, blue: 0.30).opacity(0.12))
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 16)

            if storage.consolidatedWatchHistory.isEmpty {
                // Elegant Empty State Card
                HStack(spacing: 12) {
                    Image(systemName: "film.stack")
                        .font(.system(size: 26))
                        .foregroundColor(KLTheme.textMuted)

                    VStack(alignment: .leading, spacing: 3) {
                        Text("Chưa có phim trong lịch sử xem")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(.white)
                        Text("Mỗi bộ phim theo dõi sẽ được tự động gộp thành 1 mục tinh gọn tại đây.")
                            .font(.system(size: 11, weight: .regular))
                            .foregroundColor(KLTheme.textMuted)
                            .lineLimit(2)
                    }
                }
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(red: 0.11, green: 0.11, blue: 0.14))
                .cornerRadius(14)
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(Color.white.opacity(0.08), lineWidth: 0.8)
                )
                .padding(.horizontal, 16)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 14) {
                        ForEach(storage.consolidatedWatchHistory) { item in
                            KLCinemaConsolidatedHistoryCard(
                                item: item,
                                onPlay: {
                                    KLHaptics.medium()
                                    directResumeItem = item.latestProgress
                                },
                                onDelete: {
                                    withAnimation(.spring(response: 0.28, dampingFraction: 0.78)) {
                                        storage.removeWatchProgress(filmSlug: item.filmSlug)
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

    // MARK: - Direct Utilities & Quality Settings
    @ViewBuilder
    private func renderUtilitiesSection() -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("TIỆN ÍCH TRỰC TIẾP")
                .font(.system(size: 11, weight: .heavy))
                .tracking(0.8)
                .foregroundColor(KLTheme.textMuted)
                .padding(.horizontal, 16)

            VStack(spacing: 0) {
                // Schedule Button
                Button {
                    KLHaptics.medium()
                    onOpenSchedule()
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "calendar")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(KLTheme.brandOrange)
                            .frame(width: 28)

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Lịch Thi Đấu Bóng Đá (7 Ngày)")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.white)
                            Text("Xem lịch thi đấu Ngoại Hạng Anh, C1, La Liga...")
                                .font(.system(size: 11, weight: .regular))
                                .foregroundColor(KLTheme.textMuted)
                        }

                        Spacer()

                        Image(systemName: "chevron.right")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(Color.white.opacity(0.3))
                    }
                    .padding(14)
                }
                .buttonStyle(.plain)

                Divider().background(Color.white.opacity(0.06)).padding(.horizontal, 16)

                // Quality Selector
                HStack(spacing: 12) {
                    Image(systemName: "sparkles.tv")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(Color(red: 0.22, green: 0.65, blue: 0.95))
                        .frame(width: 28)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Chất Lượng Video Mặc Định")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white)
                        Text("Ưu tiên luồng phát HLS mượt mà nhất")
                            .font(.system(size: 11, weight: .regular))
                            .foregroundColor(KLTheme.textMuted)
                    }

                    Spacer()

                    Picker("", selection: $selectedQuality) {
                        ForEach(qualityOptions, id: \.self) { opt in
                            Text(opt).tag(opt)
                        }
                    }
                    .pickerStyle(.menu)
                    .tint(KLTheme.brandOrange)
                }
                .padding(14)
            }
            .background(Color(red: 0.11, green: 0.11, blue: 0.14))
            .cornerRadius(16)
            .padding(.horizontal, 16)
        }
    }

    // MARK: - Data & System Maintenance
    @ViewBuilder
    private func renderDataAndMaintenanceSection() -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("HỆ THỐNG & BỘ NHỚ")
                .font(.system(size: 11, weight: .heavy))
                .tracking(0.8)
                .foregroundColor(KLTheme.textMuted)
                .padding(.horizontal, 16)

            VStack(spacing: 0) {
                // Clear Cache Button
                Button {
                    KLHaptics.selection()
                    storage.clearAllCaches()
                    isCacheCleared = true
                    cacheSizeText = "0 KB"
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                        isCacheCleared = false
                    }
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "trash.fill")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(isCacheCleared ? .green : Color(red: 0.95, green: 0.45, blue: 0.15))
                            .frame(width: 28)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(isCacheCleared ? "Đã Xóa Toàn Bộ Bộ Nhớ Đệm" : "Xóa Bộ Nhớ Đệm Hình Ảnh & Video")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.white)
                            Text(isCacheCleared ? "Dung lượng cache hiện tại: 0 KB" : "Đã chiếm \(cacheSizeText.isEmpty ? storage.getFormattedCacheSize() : cacheSizeText) (RAM + Disk)")
                                .font(.system(size: 11, weight: .regular))
                                .foregroundColor(isCacheCleared ? .green : KLTheme.textMuted)
                        }

                        Spacer()

                        Text(isCacheCleared ? "SẠCH ✓" : "DỌN DẸP")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(isCacheCleared ? .green : KLTheme.brandOrange)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(Color.white.opacity(0.08))
                            .cornerRadius(6)
                    }
                    .padding(14)
                }
                .buttonStyle(.plain)

                Divider().background(Color.white.opacity(0.06)).padding(.horizontal, 16)

                // Telegram Support Button
                Button {
                    KLHaptics.medium()
                    onOpenTelegram()
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "paperplane.fill")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(KLTheme.telegramBlue)
                            .frame(width: 28)

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Báo Lỗi & Góp Ý Telegram")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.white)
                            Text("Kênh phản hồi hỗ trợ người dùng 24/7")
                                .font(.system(size: 11, weight: .regular))
                                .foregroundColor(KLTheme.textMuted)
                        }

                        Spacer()

                        Image(systemName: "chevron.right")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(Color.white.opacity(0.3))
                    }
                    .padding(14)
                }
                .buttonStyle(.plain)
            }
            .background(Color(red: 0.11, green: 0.11, blue: 0.14))
            .cornerRadius(16)
            .padding(.horizontal, 16)
        }
    }

    // MARK: - Footer
    @ViewBuilder
    private func renderFooter() -> some View {
        VStack(spacing: 4) {
            Text("KenhLive Cinema & Sports iOS")
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(Color.white.opacity(0.6))
            Text("Phiên bản v1.9.6 (Build 162)")
                .font(.system(size: 11, weight: .regular))
                .foregroundColor(Color.white.opacity(0.3))
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 10)
    }
}
