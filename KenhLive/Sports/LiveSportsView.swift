import SwiftUI

struct LiveSportsView: View {
    var isActive: Bool = true
    @State private var socoliveMatches: [LiveMatchGroup] = []
    @State private var colaMatches: [LiveMatchGroup] = []
    @State private var gavang33Matches: [LiveMatchGroup] = []
    @State private var giovangMatches: [LiveMatchGroup] = []

    @State private var selectedProvider: String = "all"
    @State private var selectedLeague: String = "all"
    @State private var heroIndex: Int = 0
    @State private var isLoading: Bool = true
    @State private var selectedGroupForPicker: LiveMatchGroup? = nil
    @State private var activeRoomForPlayer: LiveRoom? = nil
    @State private var isShowingSchedule: Bool = false
    @State private var autoRefreshTask: Task<Void, Never>? = nil

    private var allMatches: [LiveMatchGroup] {
        socoliveMatches + gavang33Matches + colaMatches + giovangMatches
    }

    private var providerFilteredMatches: [LiveMatchGroup] {
        switch selectedProvider {
        case "socolive": return socoliveMatches
        case "gavang33", "gavang": return gavang33Matches
        case "colatv": return colaMatches
        case "giovang", "khandai": return giovangMatches
        default: return allMatches
        }
    }

    private var activeMatchesForCurrentProvider: [LiveMatchGroup] {
        var list = providerFilteredMatches
        if selectedLeague != "all" {
            list = list.filter { $0.league == selectedLeague }
        }
        return list
    }

    private var availableLeagues: [String] {
        let leagues = Array(Set(providerFilteredMatches.map { $0.league.isEmpty ? "Khác" : $0.league }))
        return ["all"] + leagues.sorted()
    }

    private var heroMatches: [LiveMatchGroup] {
        Array(providerFilteredMatches.prefix(6))
    }

    private var currentHero: LiveMatchGroup? {
        guard !heroMatches.isEmpty else { return nil }
        return heroMatches[heroIndex % heroMatches.count]
    }

    var body: some View {
        ZStack(alignment: .top) {
            KLTheme.bgDeep.ignoresSafeArea()

            // FPT Play Emerald Stadium Ambient Glow
            KLAmbientHeaderGlow(
                color: Color(red: 0.08, green: 0.65, blue: 0.45),
                height: 280,
                opacity: 0.20
            )

            ScrollView(showsIndicators: false) {
                LazyVStack(alignment: .leading, spacing: 18) {
                    // 1. Apple Native Editorial Navigation Header
                    HStack(alignment: .center) {
                        HStack(spacing: 8) {
                            Text("Thể Thao")
                                .font(.system(size: 28, weight: .heavy, design: .rounded))
                                .foregroundColor(.white)

                            Circle()
                                .fill(KLTheme.liveRed)
                                .frame(width: 8, height: 8)
                                .overlay(
                                    Circle()
                                        .stroke(KLTheme.liveRed.opacity(0.4), lineWidth: 4)
                                )
                        }

                        Spacer()

                        Button {
                            KLHaptics.selection()
                            isShowingSchedule = true
                        } label: {
                            HStack(spacing: 5) {
                                Image(systemName: "calendar")
                                    .font(.system(size: 13, weight: .bold))
                                Text("Lịch đấu")
                                    .font(.system(size: 12, weight: .bold, design: .rounded))
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 7)
                            .background(Color.white.opacity(0.12))
                            .clipShape(Capsule())
                            .overlay(
                                Capsule().stroke(Color.white.opacity(0.15), lineWidth: 0.8)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 10)

                    // 2. Spotlight Hero Match Banner (Immersion & Content First)
                    if let hero = currentHero {
                        SportsHeroBanner(
                            group: hero,
                            currentIndex: heroIndex,
                            totalCount: max(1, heroMatches.count),
                            onWatchNow: {
                                activeRoomForPlayer = hero.topRoom
                            },
                            onPickRoom: {
                                if hero.rooms.count > 1 {
                                    selectedGroupForPicker = hero
                                } else {
                                    activeRoomForPlayer = hero.topRoom
                                }
                            },
                            onNextMatch: {
                                if heroMatches.count > 1 {
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                        heroIndex = (heroIndex + 1) % heroMatches.count
                                    }
                                }
                            }
                        )
                        .padding(.top, 8)
                    }

                    // 2. League Quick Filter Chips
                    if availableLeagues.count > 2 {
                        renderLeagueFilterStrip()
                    }

                    // 3. Matches Content Feed (Branded Horizontal Rails per Provider)
                    if selectedProvider == "all" && selectedLeague == "all" {
                        renderAllProvidersRails()
                    } else {
                        renderVerticalMatchesFeed()
                    }

                    Spacer(minLength: 80)
                }
                .padding(.top, 4)
                .padding(.bottom, 24)
            }
            .refreshable {
                await loadMatches()
            }

            if isLoading && allMatches.isEmpty {
                ProgressView()
                    .tint(KLTheme.brandOrange)
                    .scaleEffect(1.3)
            }
        }
        .task {
            if allMatches.isEmpty {
                await loadMatches()
            }
            startAutoRefresh()
        }
        .onDisappear {
            autoRefreshTask?.cancel()
            autoRefreshTask = nil
        }
        .onChange(of: isActive) { active in
            if active {
                startAutoRefresh()
            } else {
                autoRefreshTask?.cancel()
                autoRefreshTask = nil
            }
        }
        .sheet(item: $selectedGroupForPicker) { group in
            RoomPickerSheet(matchGroup: group)
        }
        .sheet(isPresented: $isShowingSchedule) {
            ScheduleView()
        }
        .fullScreenCover(item: $activeRoomForPlayer) { room in
            HLSPlayerView(
                title: room.matchTitle,
                subtitle: "\(room.providerDisplayName) · \(room.blvName)",
                room: room,
                onClose: {
                    activeRoomForPlayer = nil
                }
            )
        }
    }

    // MARK: - League Filter Strip
    @ViewBuilder
    private func renderLeagueFilterStrip() -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(availableLeagues, id: \.self) { lg in
                    let isSel = selectedLeague == lg
                    Button {
                        KLHaptics.selection()
                        withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
                            selectedLeague = lg
                        }
                    } label: {
                        Text(lg == "all" ? "Tất cả giải" : lg)
                            .font(.system(size: 11.5, weight: isSel ? .bold : .medium, design: .rounded))
                            .foregroundColor(isSel ? .black : KLTheme.textSecondary)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(isSel ? Color.white : KLTheme.surfaceGlass)
                            .cornerRadius(14)
                            .overlay(
                                RoundedRectangle(cornerRadius: 14)
                                    .stroke(isSel ? Color.white : KLTheme.borderSubtle, lineWidth: 0.8)
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 16)
        }
    }

    // MARK: - All Providers Rails (Default View)
    @ViewBuilder
    private func renderAllProvidersRails() -> some View {
        VStack(spacing: 20) {
            if !socoliveMatches.isEmpty {
                SportsProviderRail(
                    title: "Trực Tiếp Socolive",
                    subtitle: "Bình luận viên Socolive sôi động",
                    badgeText: "SOCOLIVE",
                    badgeColor: KLTheme.socoEmerald,
                    matches: socoliveMatches,
                    onTapMatch: handleMatchSelection
                )
            }

            if !gavang33Matches.isEmpty {
                SportsProviderRail(
                    title: "Trực Tiếp Gà Vàng 33",
                    subtitle: "Luồng độc quyền độ trễ thấp",
                    badgeText: "GÀ VÀNG 33",
                    badgeColor: KLTheme.gavangAmber,
                    matches: gavang33Matches,
                    onTapMatch: handleMatchSelection
                )
            }

            if !colaMatches.isEmpty {
                SportsProviderRail(
                    title: "Trực Tiếp ColaTV",
                    subtitle: "Đường truyền tốc độ cao ColaTV",
                    badgeText: "COLATV",
                    badgeColor: KLTheme.colaSky,
                    matches: colaMatches,
                    onTapMatch: handleMatchSelection
                )
            }

            if !giovangMatches.isEmpty {
                SportsProviderRail(
                    title: "Trực Tiếp Giờ Vàng TV",
                    subtitle: "Luồng thể thao chọn lọc",
                    badgeText: "GIỜ VÀNG",
                    badgeColor: KLTheme.giovangPurple,
                    matches: giovangMatches,
                    onTapMatch: handleMatchSelection
                )
            }
        }
    }

    // MARK: - Vertical Matches Feed
    @ViewBuilder
    private func renderVerticalMatchesFeed() -> some View {
        VStack(alignment: .leading, spacing: 12) {
            KLSectionHeader(
                title: "Danh Sách Trận Đấu",
                subtitle: "\(activeMatchesForCurrentProvider.count) trận phù hợp",
                trailingText: "REAL-TIME",
                accentColor: KLTheme.brandOrange
            )

            if activeMatchesForCurrentProvider.isEmpty {
                VStack(spacing: 10) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 30))
                        .foregroundColor(KLTheme.textMuted)
                    Text("Không tìm thấy trận đấu phù hợp")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(KLTheme.textSecondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
            } else {
                LazyVStack(spacing: 10) {
                    ForEach(activeMatchesForCurrentProvider) { group in
                        Button {
                            handleMatchSelection(group)
                        } label: {
                            StadiumMatchCard(group: group)
                        }
                        .buttonStyle(KLScaleButtonStyle())
                    }
                }
                .padding(.horizontal, 16)
            }
        }
    }

    private func handleMatchSelection(_ group: LiveMatchGroup) {
        KLHaptics.medium()
        if group.rooms.count > 1 {
            selectedGroupForPicker = group
        } else {
            activeRoomForPlayer = group.topRoom
        }
    }

    private func loadMatches() async {
        isLoading = true
        let res = await SportsService.shared.fetchLiveMatches()
        socoliveMatches = res.socolive
        colaMatches = res.cola
        gavang33Matches = res.gavang33
        giovangMatches = res.giovang
        isLoading = false
    }

    private func startAutoRefresh() {
        autoRefreshTask?.cancel()
        autoRefreshTask = Task {
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 60 * 1_000_000_000)
                guard !Task.isCancelled else { break }
                let res = await SportsService.shared.fetchLiveMatches()
                await MainActor.run {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        socoliveMatches = res.socolive
                        colaMatches = res.cola
                        gavang33Matches = res.gavang33
                        giovangMatches = res.giovang
                    }
                }
            }
        }
    }
}

// MARK: - Apple Sports Cinema Spotlight Hero Banner
private struct SportsHeroBanner: View {
    let group: LiveMatchGroup
    let currentIndex: Int
    let totalCount: Int
    let onWatchNow: () -> Void
    let onPickRoom: () -> Void
    let onNextMatch: () -> Void

    var body: some View {
        let top = group.topRoom
        let teamA = group.homeTeamName
        let teamB = group.awayTeamName
        let logoA = group.homeLogoUrl
        let logoB = group.awayLogoUrl

        VStack(spacing: 12) {
            // 1. Top Badges Row: Status + League + Broadcaster
            HStack(spacing: 8) {
                KLLivePulseBadge(text: "TRỰC TIẾP", color: KLTheme.liveRed)

                Text(group.league.isEmpty ? "BÓNG ĐÁ" : group.league.uppercased())
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .tracking(0.6)
                    .foregroundColor(Color.white.opacity(0.85))
                    .lineLimit(1)

                Spacer()

                Text(top.providerDisplayName)
                    .font(.system(size: 9, weight: .heavy, design: .rounded))
                    .foregroundColor(.white)
                    .padding(.horizontal, 7)
                    .padding(.vertical, 3)
                    .background(group.providerColor)
                    .clipShape(Capsule())

                if totalCount > 1 {
                    Text("\(currentIndex + 1)/\(totalCount)")
                        .font(.system(size: 9.5, weight: .bold, design: .monospaced))
                        .foregroundColor(Color.white.opacity(0.65))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2.5)
                        .background(Color.white.opacity(0.12))
                        .clipShape(Capsule())
                }
            }

            // 2. Teams Arena Face-Off
            HStack(alignment: .center, spacing: 12) {
                // Home Club
                VStack(spacing: 6) {
                    TeamLogoView(url: logoA, size: 48)
                        .shadow(color: .black.opacity(0.4), radius: 6, y: 3)

                    Text(teamA)
                        .font(.system(size: 13.5, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                        .frame(maxWidth: .infinity)
                }
                .frame(maxWidth: .infinity)

                // Scoreboard Digital Center
                VStack(spacing: 4) {
                    if let s = group.liveScore, !s.scoreA.isEmpty {
                        HStack(spacing: 6) {
                            Text(s.scoreA)
                                .font(.system(size: 24, weight: .black, design: .monospaced))
                            Text("-")
                                .font(.system(size: 18, weight: .bold, design: .rounded))
                                .foregroundColor(Color.white.opacity(0.5))
                            Text(s.scoreB)
                                .font(.system(size: 24, weight: .black, design: .monospaced))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 4)
                        .background(Color.black.opacity(0.5))
                        .clipShape(Capsule())
                        .overlay(Capsule().stroke(Color.white.opacity(0.15), lineWidth: 0.8))
                    } else {
                        Text("VS")
                            .font(.system(size: 13, weight: .black, design: .rounded))
                            .foregroundColor(Color.white.opacity(0.75))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4.5)
                            .background(Color.white.opacity(0.12))
                            .clipShape(Capsule())
                    }

                    if !top.blvName.isEmpty {
                        HStack(spacing: 4) {
                            Image(systemName: "mic.fill")
                                .font(.system(size: 9))
                                .foregroundColor(KLTheme.accentCyan)
                            Text(top.blvName)
                                .font(.system(size: 11, weight: .semibold, design: .rounded))
                                .foregroundColor(Color.white.opacity(0.9))
                                .lineLimit(1)
                        }
                    }
                }
                .frame(minWidth: 84)

                // Away Club
                VStack(spacing: 6) {
                    TeamLogoView(url: logoB, size: 48)
                        .shadow(color: .black.opacity(0.4), radius: 6, y: 3)

                    Text(teamB)
                        .font(.system(size: 13.5, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                        .frame(maxWidth: .infinity)
                }
                .frame(maxWidth: .infinity)
            }
            .padding(.vertical, 4)

            // 3. Bottom Action Controls
            HStack(spacing: 8) {
                Button(action: onWatchNow) {
                    HStack(spacing: 6) {
                        Image(systemName: "play.fill")
                            .font(.system(size: 11, weight: .bold))
                        Text("XEM TRỰC TIẾP")
                            .font(.system(size: 12, weight: .heavy, design: .rounded))
                    }
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
                .buttonStyle(.plain)

                if group.rooms.count > 1 {
                    Button(action: onPickRoom) {
                        HStack(spacing: 4) {
                            Image(systemName: "waveform")
                                .font(.system(size: 10, weight: .bold))
                            Text("ĐỔI BLV (\(group.rooms.count))")
                                .font(.system(size: 11, weight: .bold, design: .rounded))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                        .background(Color.white.opacity(0.14))
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }
                    .buttonStyle(.plain)
                }

                if totalCount > 1 {
                    Button(action: onNextMatch) {
                        Image(systemName: "chevron.right")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 10)
                            .background(Color.white.opacity(0.14))
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }
                    .buttonStyle(.plain)
                }
            }

            // 4. Elegant Indicator Dots
            if totalCount > 1 {
                HStack(spacing: 5) {
                    ForEach(0..<min(8, totalCount), id: \.self) { idx in
                        Capsule()
                            .fill(idx == currentIndex ? Color.white : Color.white.opacity(0.22))
                            .frame(width: idx == currentIndex ? 16 : 5, height: 4.5)
                            .animation(.spring(response: 0.25, dampingFraction: 0.8), value: currentIndex)
                    }
                }
                .padding(.top, 2)
            }
        }
        .padding(16)
        .background(
            ZStack {
                LinearGradient(
                    colors: [
                        Color(red: 0.04, green: 0.15, blue: 0.13),
                        Color(red: 0.05, green: 0.08, blue: 0.14)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )

                RadialGradient(
                    colors: [
                        Color(red: 0.08, green: 0.70, blue: 0.45).opacity(0.35),
                        Color.clear
                    ],
                    center: .top,
                    startRadius: 20,
                    endRadius: 220
                )
            }
        )
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(
                    LinearGradient(
                        colors: [
                            Color(red: 0.12, green: 0.75, blue: 0.50).opacity(0.40),
                            Color.white.opacity(0.12)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
        .padding(.horizontal, 16)
    }
}

// MARK: - Horizontal Sports Provider Rail
private struct SportsProviderRail: View {
    let title: String
    let subtitle: String
    let badgeText: String
    let badgeColor: Color
    let matches: [LiveMatchGroup]
    let onTapMatch: (LiveMatchGroup) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            KLSectionHeader(
                title: title,
                subtitle: subtitle,
                trailingText: "\(matches.count) TRẬN",
                accentColor: badgeColor
            )

            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: 12) {
                    ForEach(matches) { group in
                        SportsMatchCardView(group: group, badgeColor: badgeColor) {
                            onTapMatch(group)
                        }
                    }
                }
                .padding(.horizontal, 16)
            }
        }
    }
}

// MARK: - Modern Stadium Scoreboard Match Card (Rail Item)
private struct SportsMatchCardView: View {
    let group: LiveMatchGroup
    let badgeColor: Color
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            let top = group.topRoom
            let teamA = group.homeTeamName
            let teamB = group.awayTeamName
            let logoA = group.homeLogoUrl
            let logoB = group.awayLogoUrl

            VStack(alignment: .leading, spacing: 9) {
                // Top Header: League Pill + Live Status Pill
                HStack(alignment: .center) {
                    Text(group.league.isEmpty ? "BÓNG ĐÁ" : group.league)
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .foregroundColor(KLTheme.accentCyan)
                        .lineLimit(1)

                    Spacer()

                    KLLivePulseBadge(text: "LIVE", color: KLTheme.liveRed)
                }

                // Stadium Face-Off
                HStack(alignment: .center, spacing: 8) {
                    HStack(spacing: 7) {
                        TeamLogoView(url: logoA, size: 32)
                        Text(teamA)
                            .font(.system(size: 13, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                            .lineLimit(1)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    if let score = group.liveScore, !score.scoreA.isEmpty {
                        Text("\(score.scoreA) - \(score.scoreB)")
                            .font(.system(size: 13, weight: .black, design: .monospaced))
                            .foregroundColor(KLTheme.brandOrange)
                            .padding(.horizontal, 7)
                            .padding(.vertical, 3)
                            .background(Color.white.opacity(0.08))
                            .clipShape(Capsule())
                    } else {
                        Text("VS")
                            .font(.system(size: 11, weight: .black, design: .rounded))
                            .foregroundColor(KLTheme.textMuted)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                    }

                    HStack(spacing: 7) {
                        Text(teamB)
                            .font(.system(size: 13, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                            .lineLimit(1)
                            .multilineTextAlignment(.trailing)
                        TeamLogoView(url: logoB, size: 32)
                    }
                    .frame(maxWidth: .infinity, alignment: .trailing)
                }
                .padding(.vertical, 3)

                Divider().background(KLTheme.borderSubtle)

                // Footer: BLV Name + Provider Badge
                HStack {
                    HStack(spacing: 4) {
                        Image(systemName: "mic.fill")
                            .font(.system(size: 9))
                            .foregroundColor(KLTheme.brandOrange)
                        Text(top.blvName.isEmpty ? "BLV Nhà Đài" : top.blvName)
                            .font(.system(size: 11, weight: .semibold, design: .rounded))
                            .foregroundColor(KLTheme.brandOrange)
                            .lineLimit(1)
                    }

                    Spacer()

                    Text(top.providerDisplayName)
                        .font(.system(size: 9, weight: .heavy, design: .rounded))
                        .foregroundColor(badgeColor)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2.5)
                        .background(badgeColor.opacity(0.16))
                        .clipShape(Capsule())
                }
            }
            .padding(13)
            .frame(width: 295)
            .klGlassCard(cornerRadius: 16)
        }
        .buttonStyle(KLScaleButtonStyle())
    }
}

// MARK: - Apple Stadium Match Card (store-utility-card: rounded.lg 18px, SF Pro Text 17px/14px, action blue pill)
private struct StadiumMatchCard: View {
    let group: LiveMatchGroup

    var body: some View {
        let top = group.topRoom
        let teamA = group.homeTeamName
        let teamB = group.awayTeamName
        let logoA = group.homeLogoUrl
        let logoB = group.awayLogoUrl

        VStack(spacing: 12) {
            HStack {
                Text(group.league.isEmpty ? "BÓNG ĐÁ QUỐC TẾ" : group.league)
                    .font(.system(size: 12, weight: .semibold, design: .default))
                    .tracking(-0.22)
                    .foregroundColor(KLTheme.fptOrange)
                    .lineLimit(1)

                Spacer()

                KLLivePulseBadge(text: "LIVE", color: KLTheme.liveRed)

                Text(top.providerDisplayName)
                    .font(.system(size: 10, weight: .medium, design: .default))
                    .foregroundColor(.white)
                    .padding(.horizontal, 7)
                    .padding(.vertical, 3)
                    .background(Color.white.opacity(0.12))
                    .clipShape(Capsule())
            }

            // Scoreboard Row
            HStack(alignment: .center, spacing: 10) {
                HStack(spacing: 10) {
                    TeamLogoView(url: logoA, size: 36)
                    Text(teamA)
                        .font(.system(size: 15, weight: .semibold, design: .default))
                        .tracking(-0.28)
                        .foregroundColor(.white)
                        .lineLimit(1)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                if let score = group.liveScore, !score.scoreA.isEmpty {
                    Text("\(score.scoreA) - \(score.scoreB)")
                        .font(.system(size: 16, weight: .semibold, design: .monospaced))
                        .foregroundColor(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(KLTheme.surfaceCardSecondary)
                        .clipShape(Capsule())
                } else {
                    Text("VS")
                        .font(.system(size: 12, weight: .medium, design: .default))
                        .foregroundColor(KLTheme.textMuted)
                }

                HStack(spacing: 10) {
                    Text(teamB)
                        .font(.system(size: 15, weight: .semibold, design: .default))
                        .tracking(-0.28)
                        .foregroundColor(.white)
                        .lineLimit(1)
                        .multilineTextAlignment(.trailing)
                    TeamLogoView(url: logoB, size: 36)
                }
                .frame(maxWidth: .infinity, alignment: .trailing)
            }

            Divider().background(KLTheme.borderSubtle)

            HStack {
                HStack(spacing: 5) {
                    Image(systemName: "mic.fill")
                        .font(.system(size: 10))
                        .foregroundColor(KLTheme.appleSkyBlue)
                    Text(top.blvName)
                        .font(.system(size: 12, weight: .regular, design: .default))
                        .foregroundColor(KLTheme.appleSkyBlue)
                        .lineLimit(1)
                }

                Spacer()

                HStack(spacing: 5) {
                    Text("Xem ngay")
                        .font(.system(size: 12, weight: .medium, design: .default))
                    Image(systemName: "play.fill")
                        .font(.system(size: 9, weight: .semibold))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 14)
                .padding(.vertical, 7)
                .background(KLTheme.appleActionBlue)
                .clipShape(Capsule())
            }
        }
        .padding(16)
        .klGlassCard(cornerRadius: 18)
    }
}

// MARK: - Reusable Team Logo View
struct TeamLogoView: View {
    let url: String
    var size: CGFloat = 30

    var body: some View {
        if !url.isEmpty, let imageURL = URL(string: url) {
            AsyncImage(url: imageURL) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFit()
                        .frame(width: size, height: size)
                default:
                    SportsShieldPlaceholder(size: size)
                }
            }
            .frame(width: size, height: size)
        } else {
            SportsShieldPlaceholder(size: size)
        }
    }
}


