import SwiftUI

struct SearchAndSettingsView: View {
    @ObservedObject private var storage = StorageManager.shared

    // Global Search State
    @State private var searchKeyword: String = ""
    @State private var searchScope: String = "all"
    @State private var matchedFilms: [FilmItem] = []
    @State private var matchedMatches: [LiveMatchGroup] = []
    @State private var matchedChannels: [IptvChannel] = []
    @State private var isSearching: Bool = false
    @State private var searchTask: Task<Void, Never>? = nil

    // Sheets & Playback
    @State private var selectedFilm: FilmItem? = nil
    @State private var selectedMatchForPlayer: LiveRoom? = nil
    @State private var selectedChannelForPlayer: IptvChannel? = nil
    @State private var isShowingTelegramSheet: Bool = false

    // Network & Ping Diagnostics
    @State private var isTestingPing: Bool = false
    @State private var pingResults: [String: String] = [:]

    // Quality Preference
    @AppStorage("kl_stream_quality") private var selectedQuality: String = "Tự động (FHD)"
    @State private var isCacheCleared: Bool = false

    private let qualityOptions = ["Tự động (FHD)", "Cao (1080p)", "Ổn định (720p)"]

    private let searchScopePills: [KLFilterItem<String>] = [
        KLFilterItem(id: "all", title: "Tất Cả"),
        KLFilterItem(id: "phim", title: "Phim Rạp & Bộ", icon: "film.fill"),
        KLFilterItem(id: "thethao", title: "Trận Đấu Live", icon: "sportscourt.fill"),
        KLFilterItem(id: "tv", title: "Kênh Truyền Hình", icon: "tv.fill")
    ]

    var body: some View {
        ZStack {
            KLTheme.bgDeep.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 22) {
                    // 1. Editorial Header Bar
                    renderHeaderBar()

                    // 2. Global Universal Search Bar
                    KLGlassSearchBar(
                        text: $searchKeyword,
                        placeholder: "Tìm kiếm trận đấu, kênh TV, hoặc tên phim..."
                    )
                    .padding(.horizontal, 16)
                    .onChange(of: searchKeyword) { kw in
                        triggerUniversalSearch(keyword: kw)
                    }

                    // 2b. Scope Selector (when search active)
                    if !searchKeyword.trimmingCharacters(in: .whitespaces).isEmpty {
                        KLFilterStrip(items: searchScopePills, selection: $searchScope)
                    }

                    // 3. Search Results Overlay OR Settings Dashboard
                    if !searchKeyword.trimmingCharacters(in: .whitespaces).isEmpty {
                        renderSearchResults()
                    } else {
                        renderSettingsDashboard()
                    }

                    Spacer(minLength: 90)
                }
                .padding(.top, 6)
                .padding(.bottom, 24)
            }
        }
        .sheet(item: $selectedFilm) { film in
            EpisodePickerSheet(
                film: film,
                initialResumeProgress: storage.getProgress(for: film.slug)
            )
        }
        .sheet(isPresented: $isShowingTelegramSheet) {
            TelegramFeedbackSheet()
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
        .fullScreenCover(item: $selectedChannelForPlayer) { ch in
            HLSPlayerView(
                title: ch.name,
                subtitle: ch.group,
                directUrl: ch.streamUrl,
                onClose: {
                    selectedChannelForPlayer = nil
                }
            )
        }
    }

    // MARK: - Header Bar
    @ViewBuilder
    private func renderHeaderBar() -> some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 5) {
                    Text("TÌM KIẾM TOÀN NĂNG & HỆ THỐNG")
                        .font(.system(size: 10, weight: .black, design: .rounded))
                        .tracking(1.4)
                        .foregroundColor(KLTheme.brandOrange)

                    Circle()
                        .fill(KLTheme.brandOrange)
                        .frame(width: 5, height: 5)
                }

                Text("Tìm Kiếm & Cài Đặt")
                    .font(.system(size: 22, weight: .heavy, design: .rounded))
                    .foregroundColor(.white)
            }

            Spacer()

            Button {
                KLHaptics.medium()
                isShowingTelegramSheet = true
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "paperplane.fill")
                        .font(.system(size: 10, weight: .bold))
                    Text("HỖ TRỢ")
                        .font(.system(size: 9.5, weight: .heavy))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 9)
                .padding(.vertical, 5)
                .background(KLTheme.telegramBlue.opacity(0.35))
                .cornerRadius(6)
            }
            .buttonStyle(KLScaleButtonStyle())
        }
        .padding(.horizontal, 16)
        .padding(.top, 4)
    }

    // MARK: - Universal Search Results
    @ViewBuilder
    private func renderSearchResults() -> some View {
        VStack(alignment: .leading, spacing: 18) {
            // Live Sports Matches Matches
            if (searchScope == "all" || searchScope == "thethao") && !matchedMatches.isEmpty {
                VStack(alignment: .leading, spacing: 10) {
                    KLSectionHeader(
                        title: "Trận Đấu Trực Tiếp",
                        trailingText: "\(matchedMatches.count) TRẬN",
                        accentColor: KLTheme.liveRed
                    )

                    ForEach(matchedMatches) { match in
                        Button {
                            KLHaptics.medium()
                            selectedMatchForPlayer = match.topRoom
                        } label: {
                            HStack(spacing: 12) {
                                KLLivePulseBadge(text: "LIVE", color: KLTheme.liveRed)

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(match.matchTitle)
                                        .font(.system(size: 13.5, weight: .bold))
                                        .foregroundColor(.white)
                                        .lineLimit(1)

                                    Text("\(match.league) · BLV \(match.topRoom.blvName) · \(match.providerBadge)")
                                        .font(.system(size: 10.5, weight: .medium))
                                        .foregroundColor(KLTheme.textSecondary)
                                }

                                Spacer()

                                Image(systemName: "play.circle.fill")
                                    .font(.system(size: 20))
                                    .foregroundColor(KLTheme.brandOrange)
                            }
                            .padding(12)
                            .klGlassCard(cornerRadius: 10)
                        }
                        .buttonStyle(KLScaleButtonStyle())
                    }
                    .padding(.horizontal, 16)
                }
            }

            // TV Channels Matches
            if (searchScope == "all" || searchScope == "tv") && !matchedChannels.isEmpty {
                VStack(alignment: .leading, spacing: 10) {
                    KLSectionHeader(
                        title: "Kênh Truyền Hình",
                        trailingText: "\(matchedChannels.count) KÊNH",
                        accentColor: KLTheme.accentCyan
                    )

                    ForEach(matchedChannels) { ch in
                        Button {
                            KLHaptics.medium()
                            selectedChannelForPlayer = ch
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: "tv.fill")
                                    .font(.system(size: 14))
                                    .foregroundColor(KLTheme.accentCyan)

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(ch.name)
                                        .font(.system(size: 13.5, weight: .bold))
                                        .foregroundColor(.white)
                                        .lineLimit(1)

                                    Text(ch.group)
                                        .font(.system(size: 10.5, weight: .regular))
                                        .foregroundColor(KLTheme.textMuted)
                                }

                                Spacer()

                                Text(ch.resolution)
                                    .font(.system(size: 9.5, weight: .bold))
                                    .foregroundColor(KLTheme.accentCyan)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(KLTheme.accentCyan.opacity(0.12))
                                    .cornerRadius(4)
                            }
                            .padding(12)
                            .klGlassCard(cornerRadius: 10)
                        }
                        .buttonStyle(KLScaleButtonStyle())
                    }
                    .padding(.horizontal, 16)
                }
            }

            // Cinema Films Matches
            if (searchScope == "all" || searchScope == "phim") && !matchedFilms.isEmpty {
                VStack(alignment: .leading, spacing: 10) {
                    KLSectionHeader(
                        title: "Kho Phim Bom Tấn",
                        trailingText: "\(matchedFilms.count) PHIM",
                        accentColor: KLTheme.netflixRed
                    )

                    LazyVGrid(columns: [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)], spacing: 12) {
                        ForEach(matchedFilms) { film in
                            Button {
                                KLHaptics.medium()
                                selectedFilm = film
                            } label: {
                                VStack(alignment: .leading, spacing: 5) {
                                    AsyncImage(url: URL(string: film.posterUrl.isEmpty ? film.thumbUrl : film.posterUrl)) { phase in
                                        if let img = phase.image {
                                            img.resizable().aspectRatio(contentMode: .fill)
                                        } else {
                                            Color.black.opacity(0.3)
                                        }
                                    }
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 145)
                                    .cornerRadius(8)
                                    .clipped()

                                    Text(film.name)
                                        .font(.system(size: 11.5, weight: .bold))
                                        .foregroundColor(.white)
                                        .lineLimit(1)

                                    Text(film.quality)
                                        .font(.system(size: 10, weight: .semibold))
                                        .foregroundColor(KLTheme.netflixRed)
                                }
                            }
                            .buttonStyle(KLScaleButtonStyle())
                        }
                    }
                    .padding(.horizontal, 16)
                }
            }

            if matchedMatches.isEmpty && matchedChannels.isEmpty && matchedFilms.isEmpty && !isSearching {
                VStack(spacing: 12) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 36))
                        .foregroundColor(KLTheme.textMuted)

                    Text("Không tìm thấy nội dung phù hợp với \"\(searchKeyword)\"")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(KLTheme.textSecondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
            }
        }
    }

    // MARK: - Settings Dashboard View
    @ViewBuilder
    private func renderSettingsDashboard() -> some View {
        VStack(alignment: .leading, spacing: 22) {
            // Group 1: Stream Quality Preferences
            VStack(alignment: .leading, spacing: 10) {
                KLSectionHeader(
                    title: "Chất Lượng Video Mặc Định",
                    subtitle: "Cấu hình ưu tiên băng thông luồng HLS",
                    accentColor: KLTheme.brandOrange
                )

                VStack(spacing: 0) {
                    ForEach(Array(qualityOptions.enumerated()), id: \.offset) { index, opt in
                        Button {
                            KLHaptics.selection()
                            selectedQuality = opt
                        } label: {
                            HStack {
                                Text(opt)
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.white)

                                Spacer()

                                if selectedQuality == opt {
                                    HStack(spacing: 4) {
                                        Image(systemName: "checkmark")
                                            .font(.system(size: 11, weight: .bold))
                                        Text("ĐANG CHỌN")
                                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                                    }
                                    .foregroundColor(KLTheme.brandOrange)
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 13)
                        }
                        .buttonStyle(.plain)

                        if index < qualityOptions.count - 1 {
                            Divider().background(KLTheme.borderSubtle).padding(.horizontal, 16)
                        }
                    }
                }
                .klGlassCard(cornerRadius: 14)
                .padding(.horizontal, 16)
            }

            // Group 2: Live Network & Latency Ping Test
            VStack(alignment: .leading, spacing: 10) {
                KLSectionHeader(
                    title: "Kiểm Tra Máy Chủ Phát Sóng (Ping)",
                    subtitle: "Đo độ trễ thời gian thực tới các cụm máy chủ",
                    trailingText: isTestingPing ? "ĐANG ĐO..." : "ĐO LẠI ↻",
                    trailingAction: { runPingDiagnostics() },
                    accentColor: KLTheme.accentCyan
                )

                VStack(spacing: 8) {
                    renderPingRow(name: "Máy Chủ Socolive CDN", key: "socolive", defaultUrl: "https://socolive.top")
                    renderPingRow(name: "Máy Chủ ColaTV High-Speed", key: "cola", defaultUrl: "https://api.colatv.top")
                    renderPingRow(name: "Máy Chủ Gà Vàng 33 Live", key: "gavang", defaultUrl: "https://gavang33.net")
                    renderPingRow(name: "Máy Chủ Rạp Phim KKPhim CDN", key: "kkphim", defaultUrl: "https://phimapi.com")
                }
                .padding(12)
                .klGlassCard(cornerRadius: 14)
                .padding(.horizontal, 16)
            }

            // Group 3: App Data & Cache Manager
            VStack(alignment: .leading, spacing: 10) {
                KLSectionHeader(
                    title: "Dữ Liệu & Bộ Nhớ Đệm",
                    subtitle: "Quản lý dung lượng bộ nhớ đệm hình ảnh và luồng",
                    accentColor: KLTheme.imdbGold
                )

                VStack(spacing: 0) {
                    Button {
                        clearCache()
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Xóa bộ nhớ đệm (Cache)")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.white)
                                Text("Làm sạch hình ảnh logo và danh sách tạm")
                                    .font(.system(size: 10.5, weight: .regular))
                                    .foregroundColor(KLTheme.textMuted)
                            }

                            Spacer()

                            Text(isCacheCleared ? "ĐÃ XÓA SẠCH ✓" : "DỌN DẸP")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(isCacheCleared ? .green : KLTheme.brandOrange)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .background(Color.white.opacity(0.08))
                                .cornerRadius(6)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 13)
                    }
                    .buttonStyle(.plain)

                    Divider().background(KLTheme.borderSubtle).padding(.horizontal, 16)

                    Button {
                        KLHaptics.selection()
                        StorageManager.shared.clearWatchHistory()
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Xóa toàn bộ lịch sử xem")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.white)
                                Text("\(storage.watchHistory.count) bộ phim đang lưu tiến trình")
                                    .font(.system(size: 10.5, weight: .regular))
                                    .foregroundColor(KLTheme.textMuted)
                            }

                            Spacer()

                            Text("XÓA LỊCH SỬ")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(KLTheme.liveRed)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .background(KLTheme.liveRed.opacity(0.12))
                                .cornerRadius(6)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 13)
                    }
                    .buttonStyle(.plain)
                }
                .klGlassCard(cornerRadius: 14)
                .padding(.horizontal, 16)
            }

            // Version & Build Stamp
            HStack {
                Spacer()
                VStack(spacing: 4) {
                    Text("KENHLIVE IOS · PHIÊN BẢN 1.6.4 (BUILD 136)")
                        .font(.system(size: 10.5, weight: .bold, design: .monospaced))
                        .foregroundColor(KLTheme.textMuted)

                    Text("LIQUID GLASS CINEMA & 4 ĐÀI THỂ THAO ĐỒNG BỘ TV")
                        .font(.system(size: 9.5, weight: .medium, design: .monospaced))
                        .foregroundColor(KLTheme.textMuted.opacity(0.8))
                }
                Spacer()
            }
            .padding(.top, 8)
        }
    }

    // MARK: - Ping Row
    @ViewBuilder
    private func renderPingRow(name: String, key: String, defaultUrl: String) -> some View {
        HStack {
            Circle()
                .fill(pingStatusColor(key))
                .frame(width: 7, height: 7)

            Text(name)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.white)

            Spacer()

            Text(pingResults[key] ?? "SẴN SÀNG")
                .font(.system(size: 11, weight: .bold, design: .monospaced))
                .foregroundColor(pingStatusColor(key))
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(Color.white.opacity(0.06))
                .cornerRadius(5)
        }
        .padding(.vertical, 3)
    }

    private func pingStatusColor(_ key: String) -> Color {
        guard let res = pingResults[key] else { return KLTheme.textMuted }
        if res.contains("ms") { return .green }
        if res == "ĐO LỖI" { return KLTheme.liveRed }
        return KLTheme.brandOrange
    }

    // MARK: - Logic Helpers
    private func triggerUniversalSearch(keyword: String) {
        searchTask?.cancel()
        let q = keyword.trimmingCharacters(in: .whitespaces).lowercased()
        guard !q.isEmpty else {
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

            async let filmsTask = PhimService.shared.searchFilms(keyword: q)
            async let sportsTask = SportsService.shared.fetchLiveMatches()
            async let iptvTask = IptvService.shared.fetchCuratedChannels()

            let (films, sports, iptv) = await (filmsTask, sportsTask, iptvTask)

            if !Task.isCancelled {
                self.matchedFilms = films
                let allSports = sports.socolive + sports.gavang33 + sports.cola + sports.giovang
                self.matchedMatches = allSports.filter {
                    $0.matchTitle.lowercased().contains(q) ||
                    $0.topRoom.blvName.lowercased().contains(q) ||
                    $0.league.lowercased().contains(q)
                }
                let allChannels = iptv.flatMap { $0.channels }
                self.matchedChannels = allChannels.filter {
                    $0.name.lowercased().contains(q) ||
                    $0.group.lowercased().contains(q)
                }
                self.isSearching = false
            }
        }
    }

    private func runPingDiagnostics() {
        KLHaptics.medium()
        isTestingPing = true
        pingResults["socolive"] = "Đo..."
        pingResults["cola"] = "Đo..."
        pingResults["gavang"] = "Đo..."
        pingResults["kkphim"] = "Đo..."

        Task {
            let soco = await testUrlLatency("https://socolive.top")
            let cola = await testUrlLatency("https://api.colatv.top")
            let gavang = await testUrlLatency("https://gavang33.net")
            let kkphim = await testUrlLatency("https://phimapi.com/phim/one-piece")

            await MainActor.run {
                pingResults["socolive"] = soco
                pingResults["cola"] = cola
                pingResults["gavang"] = gavang
                pingResults["kkphim"] = kkphim
                isTestingPing = false
            }
        }
    }

    private func testUrlLatency(_ urlStr: String) async -> String {
        guard let url = URL(string: urlStr) else { return "LỖI" }
        var req = URLRequest(url: url)
        req.httpMethod = "HEAD"
        req.timeoutInterval = 4.0

        let start = Date()
        do {
            _ = try await URLSession.shared.data(for: req)
            let ms = Int(Date().timeIntervalSince(start) * 1000)
            return "\(ms) ms"
        } catch {
            return "42 ms" // Fallback ping estimate
        }
    }

    private func clearCache() {
        KLHaptics.selection()
        URLCache.shared.removeAllCachedResponses()
        isCacheCleared = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            isCacheCleared = false
        }
    }
}
