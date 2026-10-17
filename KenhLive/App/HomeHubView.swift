import SwiftUI

struct HomeHubView: View {
    @Binding var currentTab: KLTab
    let onOpenTelegram: () -> Void
    let onOpenSchedule: () -> Void

    @State private var liveMatches: [LiveMatchGroup] = []
    @State private var trendingFilms: [FilmItem] = []
    @State private var continueWatchingList: [WatchProgress] = []
    @State private var selectedMatchForPlayer: LiveRoom? = nil
    @State private var selectedFilmForEpisodes: FilmItem? = nil
    @State private var resumeFilmProgress: WatchProgress? = nil
    @State private var spotlightIndex: Int = 0
    @State private var isLoading: Bool = true

    private var spotlightItems: [LiveMatchGroup] {
        Array(liveMatches.prefix(5))
    }

    var body: some View {
        ZStack {
            KLTheme.bgDeep.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 22) {
                    // 1. Editorial Header Bar
                    renderEditorialHeader()

                    // 2. Dynamic Spotlight Hero Carousel
                    if !spotlightItems.isEmpty {
                        renderSpotlightCarousel()
                    }

                    // 3. Continue Watching Rail (if any)
                    if !continueWatchingList.isEmpty {
                        renderContinueWatchingRail()
                    }

                    // 4. 2x2 Glass Portals Grid
                    renderPortalsGrid()

                    // 5. Live Football Matches Rail
                    if !liveMatches.isEmpty {
                        renderLiveSportsRail()
                    }

                    // 6. Top Trending Films Rail
                    if !trendingFilms.isEmpty {
                        renderTrendingFilmsRail()
                    }

                    // 7. Bottom Utility & Support Tiles
                    renderSupportFooter()

                    Spacer(minLength: 32)
                }
                .padding(.top, 6)
                .padding(.bottom, 24)
            }
        }
        .task {
            await loadHomeData()
        }
        .fullScreenCover(item: $selectedMatchForPlayer) { room in
            HLSPlayerView(
                title: room.matchTitle,
                subtitle: "\(room.providerDisplayName) · \(room.blvName)",
                room: room,
                onClose: {
                    selectedMatchForPlayer = nil
                }
            )
        }
        .sheet(item: $selectedFilmForEpisodes) { film in
            EpisodePickerSheet(
                film: film,
                initialResumeProgress: resumeFilmProgress ?? StorageManager.shared.getProgress(for: film.slug)
            )
        }
    }

    // MARK: - Header Bar
    @ViewBuilder
    private func renderEditorialHeader() -> some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 5) {
                    Text("CỔNG GIẢI TRÍ ĐA NỀN TẢNG")
                        .font(.system(size: 10, weight: .black, design: .rounded))
                        .tracking(1.4)
                        .foregroundColor(KLTheme.brandOrange)

                    Circle()
                        .fill(KLTheme.liveRed)
                        .frame(width: 5, height: 5)
                }

                Text("KenhLive Premium")
                    .font(.system(size: 22, weight: .heavy, design: .rounded))
                    .foregroundColor(.white)
            }

            Spacer()

            HStack(spacing: 5) {
                Image(systemName: "clock.fill")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(KLTheme.brandOrange)

                Text(DataNormalizer.formatGMT7Time(Date()) + " GMT+7")
                    .font(.system(size: 10.5, weight: .bold, design: .monospaced))
                    .foregroundColor(KLTheme.textSecondary)
            }
            .padding(.horizontal, 9)
            .padding(.vertical, 5)
            .background(KLTheme.surfaceCard)
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(KLTheme.borderSubtle, lineWidth: 0.8)
            )
        }
        .padding(.horizontal, 16)
        .padding(.top, 4)
    }

    // MARK: - Spotlight Hero Carousel
    @ViewBuilder
    private func renderSpotlightCarousel() -> some View {
        VStack(alignment: .leading, spacing: 10) {
            KLSectionHeader(
                title: "Tâm Điểm Trực Tiếp",
                subtitle: "Trận cầu đinh đang phát sóng",
                trailingText: "\(liveMatches.count) TRẬN LIVE",
                accentColor: KLTheme.liveRed
            )

            TabView(selection: $spotlightIndex) {
                ForEach(Array(spotlightItems.enumerated()), id: \.offset) { index, match in
                    renderSpotlightCard(match: match)
                        .tag(index)
                        .padding(.horizontal, 16)
                }
            }
            .frame(height: 180)
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .automatic))
        }
    }

    @ViewBuilder
    private func renderSpotlightCard(match: LiveMatchGroup) -> some View {
        let teamA = match.homeTeamName
        let teamB = match.awayTeamName
        let logoA = match.homeLogoUrl
        let logoB = match.awayLogoUrl

        Button {
            KLHaptics.medium()
            selectedMatchForPlayer = match.topRoom
        } label: {
            ZStack(alignment: .bottomLeading) {
                // Background Gradient Mesh
                LinearGradient(
                    colors: [
                        Color(red: 0.12, green: 0.08, blue: 0.18),
                        Color(red: 0.06, green: 0.09, blue: 0.16),
                        KLTheme.surfaceCard
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )

                // Team Logos Glow
                HStack {
                    Spacer()
                    Image(systemName: "sportscourt.fill")
                        .font(.system(size: 140))
                        .foregroundColor(Color.white.opacity(0.03))
                        .offset(x: 20, y: 10)
                }

                VStack(alignment: .leading, spacing: 10) {
                    // Top Bar: Live Badge + League
                    HStack {
                        KLLivePulseBadge(text: "TRỰC TIẾP", color: KLTheme.liveRed)

                        Text(match.league.isEmpty ? "BÓNG ĐÁ QUỐC TẾ" : match.league.uppercased())
                            .font(.system(size: 10.5, weight: .bold, design: .rounded))
                            .foregroundColor(KLTheme.textSecondary)
                            .lineLimit(1)

                        Spacer()

                        Text(match.providerBadge)
                            .font(.system(size: 9.5, weight: .heavy, design: .rounded))
                            .foregroundColor(.white)
                            .padding(.horizontal, 7)
                            .padding(.vertical, 3)
                            .background(match.providerColor.opacity(0.85))
                            .cornerRadius(5)
                    }

                    // Center Stadium Face-Off
                    HStack(alignment: .center, spacing: 12) {
                        // Team A
                        HStack(spacing: 8) {
                            AsyncImage(url: URL(string: logoA)) { phase in
                                if let img = phase.image {
                                    img.resizable().aspectRatio(contentMode: .fit)
                                } else {
                                    Image(systemName: "shield.fill").foregroundColor(KLTheme.textMuted)
                                }
                            }
                            .frame(width: 38, height: 38)

                            Text(teamA)
                                .font(.system(size: 13.5, weight: .bold))
                                .foregroundColor(.white)
                                .lineLimit(1)
                        }
                        .frame(maxWidth: .infinity, alignment: .trailing)

                        // Center Score / VS
                        VStack(spacing: 2) {
                            if let s = match.liveScore, !s.scoreA.isEmpty {
                                Text("\(s.scoreA) - \(s.scoreB)")
                                    .font(.system(size: 18, weight: .black, design: .rounded))
                                    .foregroundColor(KLTheme.brandOrange)
                            } else {
                                Text("VS")
                                    .font(.system(size: 14, weight: .black, design: .rounded))
                                    .foregroundColor(KLTheme.textMuted)
                            }

                            if !match.blvName.isEmpty {
                                Text("BLV " + match.blvName)
                                    .font(.system(size: 10, weight: .semibold))
                                    .foregroundColor(KLTheme.textSecondary)
                                    .lineLimit(1)
                            }
                        }
                        .frame(width: 70)

                        // Team B
                        HStack(spacing: 8) {
                            Text(teamB)
                                .font(.system(size: 13.5, weight: .bold))
                                .foregroundColor(.white)
                                .lineLimit(1)

                            AsyncImage(url: URL(string: logoB)) { phase in
                                if let img = phase.image {
                                    img.resizable().aspectRatio(contentMode: .fit)
                                } else {
                                    Image(systemName: "shield.fill").foregroundColor(KLTheme.textMuted)
                                }
                            }
                            .frame(width: 38, height: 38)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding(.vertical, 6)

                    // Bottom Action Bar
                    HStack {
                        HStack(spacing: 4) {
                            Image(systemName: "person.2.fill")
                                .font(.system(size: 10))
                            Text("\(match.totalViewers) người đang xem")
                                .font(.system(size: 10, weight: .medium, design: .monospaced))
                        }
                        .foregroundColor(KLTheme.textMuted)

                        Spacer()

                        HStack(spacing: 4) {
                            Text("XEM NGAY")
                                .font(.system(size: 11, weight: .black, design: .rounded))
                            Image(systemName: "play.fill")
                                .font(.system(size: 9, weight: .bold))
                        }
                        .foregroundColor(.black)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.white)
                        .cornerRadius(6)
                    }
                }
                .padding(14)
            }
            .klGlassCard(cornerRadius: 14, borderColor: KLTheme.borderMedium)
        }
        .buttonStyle(KLScaleButtonStyle())
    }

    // MARK: - Continue Watching Rail
    @ViewBuilder
    private func renderContinueWatchingRail() -> some View {
        VStack(alignment: .leading, spacing: 10) {
            KLSectionHeader(
                title: "Tiếp Tục Xem",
                subtitle: "Lịch sử xem phim dở",
                trailingText: "QUẢN LÝ",
                trailingAction: {
                    currentTab = .settings
                },
                accentColor: KLTheme.brandOrange
            )

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(continueWatchingList.prefix(8)) { item in
                        Button {
                            KLHaptics.medium()
                            resumeWatching(item)
                        } label: {
                            HStack(spacing: 10) {
                                // Poster Thumbnail
                                AsyncImage(url: URL(string: item.posterUrl)) { phase in
                                    if let img = phase.image {
                                        img.resizable().aspectRatio(contentMode: .fill)
                                    } else {
                                        Color.black.opacity(0.3)
                                    }
                                }
                                .frame(width: 50, height: 70)
                                .cornerRadius(8)
                                .clipped()

                                VStack(alignment: .leading, spacing: 4) {
                                    Text(item.filmName)
                                        .font(.system(size: 12.5, weight: .bold))
                                        .foregroundColor(.white)
                                        .lineLimit(1)

                                    Text(item.episodeName)
                                        .font(.system(size: 10.5, weight: .semibold))
                                        .foregroundColor(KLTheme.brandOrange)

                                    // Progress Bar
                                    let percent = item.durationMs > 0 ? Double(item.positionMs) / Double(item.durationMs) : 0.0
                                    GeometryReader { geo in
                                        ZStack(alignment: .leading) {
                                            Capsule().fill(Color.white.opacity(0.15))
                                            Capsule().fill(KLTheme.brandOrange)
                                                .frame(width: geo.size.width * CGFloat(min(1.0, max(0.05, percent))))
                                        }
                                    }
                                    .frame(height: 3)
                                    .padding(.top, 2)

                                    Text(formatSeconds(Double(item.positionMs) / 1000.0))
                                        .font(.system(size: 9.5, weight: .medium, design: .monospaced))
                                        .foregroundColor(KLTheme.textMuted)
                                }
                                .frame(width: 140, alignment: .leading)
                            }
                            .padding(8)
                            .klGlassCard(cornerRadius: 10)
                        }
                        .buttonStyle(KLScaleButtonStyle())
                    }
                }
                .padding(.horizontal, 16)
            }
        }
    }

    // MARK: - 2x2 Glass Portals Grid
    @ViewBuilder
    private func renderPortalsGrid() -> some View {
        VStack(alignment: .leading, spacing: 10) {
            KLSectionHeader(
                title: "Khám Phá Nội Dung",
                subtitle: "Chọn cổng giải trí yêu thích",
                accentColor: KLTheme.accentCyan
            )

            LazyVGrid(columns: [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)], spacing: 10) {
                // Portal 1: Thể Thao 4 Đài
                PortalGridTile(
                    title: "Thể Thao",
                    subtitle: "\(liveMatches.count) trận đang phát",
                    badge: "4 ĐÀI",
                    badgeColor: KLTheme.socoEmerald,
                    icon: "sportscourt.fill",
                    accentColor: KLTheme.socoEmerald,
                    action: { currentTab = .live }
                )

                // Portal 2: Hỗ Trợ & Báo Lỗi
                PortalGridTile(
                    title: "Hỗ Trợ",
                    subtitle: "Báo lỗi Telegram 24/7",
                    badge: "ONLINE",
                    badgeColor: KLTheme.accentCyan,
                    icon: "paperplane.fill",
                    accentColor: KLTheme.accentCyan,
                    action: onOpenTelegram
                )

                // Portal 3: Kho Phim Bom Tấn
                PortalGridTile(
                    title: "Kho Phim",
                    subtitle: "Netflix · Phim Bộ · Anime",
                    badge: "4K CINEMA",
                    badgeColor: KLTheme.netflixRed,
                    icon: "film.fill",
                    accentColor: KLTheme.netflixRed,
                    action: { currentTab = .phim }
                )

                // Portal 4: Lịch Thi Đấu
                PortalGridTile(
                    title: "Lịch Thi Đấu",
                    subtitle: "Hôm nay & Ngày mai",
                    badge: "GMT+7",
                    badgeColor: KLTheme.brandOrange,
                    icon: "calendar",
                    accentColor: KLTheme.brandOrange,
                    action: onOpenSchedule
                )
            }
            .padding(.horizontal, 16)
        }
    }

    // MARK: - Live Sports Matches Rail
    @ViewBuilder
    private func renderLiveSportsRail() -> some View {
        VStack(alignment: .leading, spacing: 10) {
            KLSectionHeader(
                title: "Trận Đang Đá Sôi Động",
                subtitle: "Tỉ số thời gian thực",
                trailingText: "TẤT CẢ",
                trailingAction: { currentTab = .live },
                accentColor: KLTheme.socoEmerald
            )

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(liveMatches.prefix(10)) { match in
                        renderMiniMatchCard(match: match)
                    }
                }
                .padding(.horizontal, 16)
            }
        }
    }

    @ViewBuilder
    private func renderMiniMatchCard(match: LiveMatchGroup) -> some View {
        let teamA = match.homeTeamName
        let teamB = match.awayTeamName
        let logoA = match.homeLogoUrl
        let logoB = match.awayLogoUrl

        Button {
            KLHaptics.medium()
            selectedMatchForPlayer = match.topRoom
        } label: {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    KLLivePulseBadge(text: "LIVE", color: KLTheme.liveRed)
                    Spacer()
                    Text(match.providerBadge)
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 5)
                        .padding(.vertical, 2)
                        .background(match.providerColor)
                        .cornerRadius(4)
                }

                HStack(spacing: 10) {
                    // Team A
                    VStack(spacing: 4) {
                        AsyncImage(url: URL(string: logoA)) { phase in
                            if let img = phase.image { img.resizable().aspectRatio(contentMode: .fit) }
                            else { Image(systemName: "shield.fill").foregroundColor(KLTheme.textMuted) }
                        }
                        .frame(width: 28, height: 28)

                        Text(teamA)
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(.white)
                            .lineLimit(1)
                    }
                    .frame(width: 65)

                    // Score
                    VStack(spacing: 2) {
                        if let s = match.liveScore, !s.scoreA.isEmpty {
                            Text("\(s.scoreA) - \(s.scoreB)")
                                .font(.system(size: 13, weight: .black, design: .rounded))
                                .foregroundColor(KLTheme.brandOrange)
                        } else {
                            Text("VS")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(KLTheme.textMuted)
                        }
                    }

                    // Team B
                    VStack(spacing: 4) {
                        AsyncImage(url: URL(string: logoB)) { phase in
                            if let img = phase.image { img.resizable().aspectRatio(contentMode: .fit) }
                            else { Image(systemName: "shield.fill").foregroundColor(KLTheme.textMuted) }
                        }
                        .frame(width: 28, height: 28)

                        Text(teamB)
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(.white)
                            .lineLimit(1)
                    }
                    .frame(width: 65)
                }

                if !match.blvName.isEmpty {
                    Text("🎙️ " + match.blvName)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(KLTheme.textSecondary)
                        .lineLimit(1)
                }
            }
            .padding(10)
            .frame(width: 195)
            .klGlassCard(cornerRadius: 12)
        }
        .buttonStyle(KLScaleButtonStyle())
    }

    // MARK: - Trending Films Rail
    @ViewBuilder
    private func renderTrendingFilmsRail() -> some View {
        VStack(alignment: .leading, spacing: 10) {
            KLSectionHeader(
                title: "Phim Hot Thịnh Hành",
                subtitle: "Top phim xem nhiều nhất",
                trailingText: "KHO PHIM",
                trailingAction: { currentTab = .phim },
                accentColor: KLTheme.netflixRed
            )

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(Array(trendingFilms.prefix(12).enumerated()), id: \.offset) { index, film in
                        Button {
                            KLHaptics.medium()
                            resumeFilmProgress = nil
                            selectedFilmForEpisodes = film
                        } label: {
                            VStack(alignment: .leading, spacing: 6) {
                                ZStack(alignment: .topTrailing) {
                                    AsyncImage(url: URL(string: film.posterUrl.isEmpty ? film.thumbUrl : film.posterUrl)) { phase in
                                        if let img = phase.image {
                                            img.resizable().aspectRatio(contentMode: .fill)
                                        } else {
                                            Color.black.opacity(0.4)
                                        }
                                    }
                                    .frame(width: 108, height: 156)
                                    .cornerRadius(10)
                                    .clipped()

                                    // Rank Number Badge
                                    Text("\(index + 1)")
                                        .font(.system(size: 11, weight: .black, design: .rounded))
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(KLTheme.netflixRed)
                                        .cornerRadius(4)
                                        .padding(6)
                                }

                                Text(film.name)
                                    .font(.system(size: 11.5, weight: .bold))
                                    .foregroundColor(.white)
                                    .lineLimit(1)

                                Text(film.year.isEmpty ? film.quality : "\(film.quality) · \(film.year)")
                                    .font(.system(size: 10, weight: .regular))
                                    .foregroundColor(KLTheme.textMuted)
                            }
                            .frame(width: 108)
                        }
                        .buttonStyle(KLScaleButtonStyle())
                    }
                }
                .padding(.horizontal, 16)
            }
        }
    }

    // MARK: - Support & Feedback Footer
    @ViewBuilder
    private func renderSupportFooter() -> some View {
        VStack(spacing: 8) {
            Button(action: onOpenTelegram) {
                HStack(spacing: 10) {
                    Image(systemName: "paperplane.fill")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(KLTheme.telegramBlue)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Cộng Đồng & Báo Lỗi Trực Tiếp")
                            .font(.system(size: 12.5, weight: .bold))
                            .foregroundColor(.white)

                        Text("Telegram @T990512S · Đóng góp ý kiến và cập nhật bản mới")
                            .font(.system(size: 10.5, weight: .regular))
                            .foregroundColor(KLTheme.textMuted)
                    }

                    Spacer()

                    Image(systemName: "arrow.up.right")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(KLTheme.telegramBlue)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 11)
                .klGlassCard(cornerRadius: 12, borderColor: KLTheme.telegramBlue.opacity(0.3))
            }
            .buttonStyle(KLScaleButtonStyle())
            .padding(.horizontal, 16)
        }
    }

    // MARK: - Helpers & Data Loading
    private func loadHomeData() async {
        isLoading = true
        async let sportsTask = SportsService.shared.fetchLiveMatches()
        async let phimTask = PhimService.shared.fetchQuickInitialSections()

        let (sportsRes, phimRes) = await (sportsTask, phimTask)
        liveMatches = (sportsRes.socolive + sportsRes.gavang33 + sportsRes.cola + sportsRes.giovang)
        trendingFilms = phimRes.first?.films ?? []
        continueWatchingList = StorageManager.shared.consolidatedWatchHistory.map { $0.latestProgress }
        isLoading = false
    }

    private func resumeWatching(_ progress: WatchProgress) {
        let dummy = FilmItem(
            name: progress.filmName,
            slug: progress.filmSlug,
            originalName: "",
            thumbUrl: progress.posterUrl,
            posterUrl: progress.posterUrl,
            quality: "HD",
            year: ""
        )
        self.resumeFilmProgress = progress
        self.selectedFilmForEpisodes = dummy
    }

    private func formatSeconds(_ sec: Double) -> String {
        guard !sec.isNaN && !sec.isInfinite else { return "00:00" }
        let total = Int(sec)
        let m = total / 60
        let s = total % 60
        return String(format: "%02d:%02d", m, s)
    }
}

// MARK: - Portal Grid Tile
private struct PortalGridTile: View {
    let title: String
    let subtitle: String
    let badge: String
    let badgeColor: Color
    let icon: String
    let accentColor: Color
    let action: () -> Void

    var body: some View {
        Button(action: {
            KLHaptics.medium()
            action()
        }) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    ZStack {
                        Circle()
                            .fill(accentColor.opacity(0.18))
                            .frame(width: 34, height: 34)

                        Image(systemName: icon)
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(accentColor)
                    }

                    Spacer()

                    Text(badge)
                        .font(.system(size: 9, weight: .heavy, design: .rounded))
                        .foregroundColor(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2.5)
                        .background(badgeColor.opacity(0.85))
                        .cornerRadius(5)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)

                    Text(subtitle)
                        .font(.system(size: 10.5, weight: .medium))
                        .foregroundColor(KLTheme.textMuted)
                        .lineLimit(1)
                }
            }
            .padding(12)
            .klGlassCard(cornerRadius: 12)
        }
        .buttonStyle(KLScaleButtonStyle())
    }
}
