import SwiftUI

// MARK: - Cinema Netflix / Liquid Glass 5-Tab Navigation
enum KLTab: Int, CaseIterable, Identifiable {
    case home = 0       // "Trang chủ" (Kho Phim Cinema)
    case sports = 1     // "Thể thao" (Socolive, ColaTV, Gà Vàng, Giờ Vàng)
    case iptv = 2       // "Truyền hình" (VTV1-6, K+ Sport, HTV)
    case search = 3     // "Tìm kiếm" (Universal Search)
    case profile = 4    // "Cá nhân" (Tiếp tục xem, Lịch đá, Báo lỗi, Cài đặt)

    // Backward-compatibility aliases for legacy portals & services
    static let live = KLTab.sports
    static let phim = KLTab.home
    static let library = KLTab.profile
    static let settings = KLTab.profile

    var id: Int { rawValue }

    var title: String {
        switch self {
        case .home: return "Trang chủ"
        case .sports: return "Thể thao"
        case .iptv: return "Truyền hình"
        case .search: return "Tìm kiếm"
        case .profile: return "Cá nhân"
        }
    }

    var iconName: String {
        switch self {
        case .home: return "house.fill"
        case .sports: return "sportscourt.fill"
        case .iptv: return "tv.fill"
        case .search: return "magnifyingglass"
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

            // 1. Tab View Content (Preserves live sports, VTV IPTV, and Cinema Experience)
            ZStack {
                switch selectedTab {
                case .home:
                    PhimView(onSelectTab: { targetTab in
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.72)) {
                            selectedTab = targetTab
                        }
                    })
                    .transition(.opacity)

                case .sports:
                    LiveSportsView()
                        .transition(.opacity)

                case .iptv:
                    IptvView()
                        .transition(.opacity)

                case .search:
                    CinemaSearchView()
                        .transition(.opacity)

                case .profile:
                    CinemaProfileView(
                        onOpenSchedule: { isShowingSchedule = true },
                        onOpenTelegram: { isShowingTelegramSheet = true }
                    )
                    .transition(.opacity)
                }
            }
            .animation(.easeInOut(duration: 0.22), value: selectedTab)
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            // 2. Animated Floating Glass Dock Tab Bar with Sliding Capsule Effect
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

    // MARK: - Animated Floating Dock Tab Bar with Sliding Indicator Effect
    @ViewBuilder
    private func renderFloatingDockTabBar() -> some View {
        HStack(spacing: 3) {
            ForEach(KLTab.allCases) { tab in
                let isActive = selectedTab == tab
                Button {
                    KLHaptics.selection()
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.72)) {
                        selectedTab = tab
                    }
                } label: {
                    ZStack {
                        // Smooth Sliding Capsule Pill via matchedGeometryEffect
                        if isActive {
                            Capsule()
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            Color(red: 0.62, green: 0.12, blue: 0.18),
                                            Color(red: 0.85, green: 0.22, blue: 0.28)
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .matchedGeometryEffect(id: "ACTIVE_TAB_PILL", in: tabNamespace)
                                .shadow(color: Color(red: 0.85, green: 0.22, blue: 0.28).opacity(0.42), radius: 8, x: 0, y: 3)
                        }

                        HStack(spacing: 4) {
                            Image(systemName: tab.iconName)
                                .font(.system(size: isActive ? 15 : 14, weight: isActive ? .bold : .medium))
                                .scaleEffect(isActive ? 1.15 : 1.0)
                                .animation(.spring(response: 0.35, dampingFraction: 0.62), value: isActive)

                            if isActive {
                                Text(tab.title)
                                    .font(.system(size: 11, weight: .bold))
                                    .lineLimit(1)
                                    .transition(.opacity.combined(with: .scale(scale: 0.9)))
                            }
                        }
                        .foregroundColor(
                            isActive
                                ? Color.white
                                : Color(white: 0.58)
                        )
                        .padding(.horizontal, isActive ? 10 : 6)
                        .padding(.vertical, 8)
                    }
                    .frame(minHeight: 38)
                }
                .buttonStyle(.plain)
                .frame(maxWidth: .infinity)
            }
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 5)
        .background(
            RoundedRectangle(cornerRadius: 32)
                .fill(Color(red: 0.11, green: 0.11, blue: 0.13).opacity(0.96))
                .overlay(
                    RoundedRectangle(cornerRadius: 32)
                        .stroke(
                            LinearGradient(
                                colors: [Color.white.opacity(0.20), Color.white.opacity(0.06)],
                                startPoint: .top,
                                endPoint: .bottom
                            ),
                            lineWidth: 0.8
                        )
                )
                .shadow(color: Color.black.opacity(0.68), radius: 18, x: 0, y: 8)
        )
        .padding(.horizontal, 12)
        .padding(.bottom, 22)
    }
}

// MARK: - Dedicated Cinema Search View (Tab 3: "Tìm kiếm")
struct CinemaSearchView: View {
    @ObservedObject private var storage = StorageManager.shared
    @State private var searchKeyword: String = ""
    @State private var searchScope: String = "all"
    @State private var matchedFilms: [FilmItem] = []
    @State private var matchedMatches: [LiveMatchGroup] = []
    @State private var matchedChannels: [IptvChannel] = []
    @State private var isSearching: Bool = false
    @State private var searchTask: Task<Void, Never>? = nil

    @State private var selectedFilm: FilmItem? = nil
    @State private var selectedMatchForPlayer: LiveRoom? = nil
    @State private var selectedChannelForPlayer: IptvChannel? = nil

    private let trendingChips = ["One Piece", "Conan", "Marvel", "Batman", "Ngoại Hạng Anh", "VTV3", "K-Drama"]

    private let searchScopePills: [KLFilterItem<String>] = [
        KLFilterItem(id: "all", title: "Tất Cả"),
        KLFilterItem(id: "phim", title: "Kho Phim", icon: "film.fill"),
        KLFilterItem(id: "thethao", title: "Thể Thao Live", icon: "sportscourt.fill"),
        KLFilterItem(id: "tv", title: "Kênh TV", icon: "tv.fill")
    ]

    var body: some View {
        ZStack {
            Color(red: 0.07, green: 0.07, blue: 0.09).ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 18) {
                    // Header
                    Text("Tìm Kiếm")
                        .font(.system(size: 26, weight: .heavy, design: .rounded))
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.top, 54)

                    // Search Bar
                    KLGlassSearchBar(
                        text: $searchKeyword,
                        placeholder: "Tìm phim, diễn viên, trận đấu, kênh TV..."
                    )
                    .padding(.horizontal, 16)
                    .onChange(of: searchKeyword) { kw in
                        triggerSearch(query: kw)
                    }

                    // Trending Chips
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

                    // Scope Strip
                    if !searchKeyword.trimmingCharacters(in: .whitespaces).isEmpty {
                        KLFilterStrip(items: searchScopePills, selection: $searchScope)
                    }

                    // Results
                    if isSearching {
                        HStack {
                            Spacer()
                            ProgressView().tint(KLTheme.brandOrange).scaleEffect(1.2)
                            Spacer()
                        }
                        .padding(.top, 40)
                    } else if !searchKeyword.trimmingCharacters(in: .whitespaces).isEmpty {
                        renderResultsGrid()
                    } else {
                        // Empty Search State
                        VStack(spacing: 12) {
                            Image(systemName: "magnifyingglass")
                                .font(.system(size: 42))
                                .foregroundColor(Color.white.opacity(0.25))
                            Text("Nhập từ khóa để khám phá kho phim & thể thao")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(KLTheme.textMuted)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.top, 60)
                    }

                    Spacer(minLength: 120)
                }
            }
        }
        .sheet(item: $selectedFilm) { film in
            EpisodePickerSheet(
                film: film,
                initialResumeProgress: storage.getProgress(for: film.slug)
            )
        }
        .fullScreenCover(item: $selectedMatchForPlayer) { room in
            HLSPlayerView(
                title: room.matchTitle,
                subtitle: "\(room.providerDisplayName) · \(room.blvName)",
                room: room
            )
        }
        .fullScreenCover(item: $selectedChannelForPlayer) { ch in
            HLSPlayerView(
                title: ch.name,
                subtitle: ch.group,
                directUrl: ch.streamUrl
            )
        }
    }

    @ViewBuilder
    private func renderResultsGrid() -> some View {
        VStack(alignment: .leading, spacing: 14) {
            if matchedFilms.isEmpty && matchedMatches.isEmpty && matchedChannels.isEmpty {
                VStack(spacing: 10) {
                    Image(systemName: "film.stack")
                        .font(.system(size: 36))
                        .foregroundColor(Color.white.opacity(0.3))
                    Text("Không tìm thấy kết quả phù hợp với \"\(searchKeyword)\"")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(KLTheme.textMuted)
                }
                .frame(maxWidth: .infinity)
                .padding(.top, 40)
            } else {
                // Movies Grid
                if (searchScope == "all" || searchScope == "phim") && !matchedFilms.isEmpty {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("KHO PHIM (\(matchedFilms.count))")
                            .font(.system(size: 12, weight: .heavy))
                            .tracking(0.6)
                            .foregroundColor(KLTheme.textMuted)
                            .padding(.horizontal, 16)

                        LazyVGrid(columns: [
                            GridItem(.flexible(), spacing: 10),
                            GridItem(.flexible(), spacing: 10),
                            GridItem(.flexible(), spacing: 10)
                        ], spacing: 14) {
                            ForEach(matchedFilms) { film in
                                Button {
                                    KLHaptics.light()
                                    selectedFilm = film
                                } label: {
                                    VStack(alignment: .leading, spacing: 5) {
                                        AsyncImage(url: URL(string: film.posterUrl.isEmpty ? film.thumbUrl : film.posterUrl)) { phase in
                                            if let img = phase.image {
                                                img.resizable().aspectRatio(contentMode: .fill)
                                            } else {
                                                Color(red: 0.14, green: 0.14, blue: 0.18)
                                            }
                                        }
                                        .frame(height: 155)
                                        .clipped()
                                        .cornerRadius(8)

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
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal, 16)
                    }
                }
            }
        }
    }

    private func triggerSearch(query: String) {
        searchTask?.cancel()
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            matchedFilms = []
            matchedMatches = []
            matchedChannels = []
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
}

// MARK: - Dedicated Cinema Profile View (Tab 4: "Cá nhân")
struct CinemaProfileView: View {
    let onOpenSchedule: () -> Void
    let onOpenTelegram: () -> Void

    @ObservedObject private var storage = StorageManager.shared
    @State private var selectedFilm: FilmItem? = nil
    @AppStorage("kl_stream_quality") private var selectedQuality: String = "Tự động (FHD)"
    @State private var pingResults: [String: String] = [:]
    @State private var isTestingPing: Bool = false
    @State private var isCacheCleared: Bool = false

    var body: some View {
        ZStack {
            Color(red: 0.07, green: 0.07, blue: 0.09).ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 20) {
                    // Header Profile Card
                    HStack(spacing: 14) {
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [Color(red: 0.62, green: 0.12, blue: 0.18), Color(red: 0.85, green: 0.22, blue: 0.27)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 58, height: 58)

                            Image(systemName: "person.fill")
                                .font(.system(size: 26))
                                .foregroundColor(.white)
                        }

                        VStack(alignment: .leading, spacing: 3) {
                            Text("KenhLive Member")
                                .font(.system(size: 18, weight: .heavy, design: .rounded))
                                .foregroundColor(.white)

                            Text("VIP Cinema, Sports & VTV Access")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(Color(red: 0.96, green: 0.77, blue: 0.10))
                        }

                        Spacer()
                    }
                    .padding(16)
                    .background(Color(red: 0.12, green: 0.12, blue: 0.16))
                    .cornerRadius(18)
                    .padding(.horizontal, 16)
                    .padding(.top, 54)

                    // Continue Watching Rail
                    if !storage.watchHistory.isEmpty {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("TIẾP TỤC XEM")
                                .font(.system(size: 11.5, weight: .heavy))
                                .tracking(0.6)
                                .foregroundColor(KLTheme.textMuted)
                                .padding(.horizontal, 16)

                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 12) {
                                    ForEach(storage.watchHistory) { item in
                                        Button {
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
                                            selectedFilm = film
                                        } label: {
                                            VStack(alignment: .leading, spacing: 6) {
                                                HStack {
                                                    Text("▶ XEM TIẾP")
                                                        .font(.system(size: 9.5, weight: .black))
                                                        .foregroundColor(KLTheme.brandOrange)
                                                    Spacer()
                                                    Text("\(Int(item.progressPercent * 100))%")
                                                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                                                        .foregroundColor(KLTheme.textSecondary)
                                                }

                                                Text(item.filmName)
                                                    .font(.system(size: 13, weight: .bold))
                                                    .foregroundColor(.white)
                                                    .lineLimit(1)

                                                Text(item.episodeName)
                                                    .font(.system(size: 11, weight: .medium))
                                                    .foregroundColor(KLTheme.textSecondary)
                                            }
                                            .padding(14)
                                            .frame(width: 200)
                                            .background(Color(red: 0.12, green: 0.12, blue: 0.16))
                                            .cornerRadius(14)
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                                .padding(.horizontal, 16)
                            }
                        }
                    }

                    // Quick Utilities
                    VStack(spacing: 12) {
                        // Schedule Button
                        Button {
                            KLHaptics.medium()
                            onOpenSchedule()
                        } label: {
                            HStack {
                                Image(systemName: "calendar")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(KLTheme.brandOrange)
                                    .frame(width: 28)

                                Text("Lịch Thi Đấu Bóng Đá (7 Ngày)")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(.white)

                                Spacer()

                                Image(systemName: "chevron.right")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(Color.white.opacity(0.3))
                            }
                            .padding(14)
                            .background(Color(red: 0.12, green: 0.12, blue: 0.16))
                            .cornerRadius(14)
                        }
                        .buttonStyle(.plain)

                        // Telegram Support Button
                        Button {
                            KLHaptics.medium()
                            onOpenTelegram()
                        } label: {
                            HStack {
                                Image(systemName: "paperplane.fill")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(KLTheme.telegramBlue)
                                    .frame(width: 28)

                                Text("Báo Lỗi & Góp Ý Telegram")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(.white)

                                Spacer()

                                Image(systemName: "chevron.right")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(Color.white.opacity(0.3))
                            }
                            .padding(14)
                            .background(Color(red: 0.12, green: 0.12, blue: 0.16))
                            .cornerRadius(14)
                        }
                        .buttonStyle(.plain)

                        // Clear Cache Button
                        Button {
                            KLHaptics.selection()
                            URLCache.shared.removeAllCachedResponses()
                            isCacheCleared = true
                        } label: {
                            HStack {
                                Image(systemName: "trash.fill")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(isCacheCleared ? .green : .white.opacity(0.6))
                                    .frame(width: 28)

                                Text(isCacheCleared ? "Đã Xóa Toàn Bộ Bộ Nhớ Đệm" : "Xóa Bộ Nhớ Đệm Hình Ảnh & Video")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.white)

                                Spacer()
                            }
                            .padding(14)
                            .background(Color(red: 0.12, green: 0.12, blue: 0.16))
                            .cornerRadius(14)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, 16)

                    // App Version Footer
                    VStack(spacing: 4) {
                        Text("KenhLive Cinema & Sports iOS")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(Color.white.opacity(0.6))
                        Text("Phiên bản v1.6.7 (Build 139)")
                            .font(.system(size: 11, weight: .regular))
                            .foregroundColor(Color.white.opacity(0.3))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 20)

                    Spacer(minLength: 120)
                }
            }
        }
        .sheet(item: $selectedFilm) { film in
            EpisodePickerSheet(
                film: film,
                initialResumeProgress: storage.getProgress(for: film.slug)
            )
        }
    }
}
