import SwiftUI

struct LiveSportsView: View {
    @State private var socoliveMatches: [LiveMatchGroup] = []
    @State private var colaMatches: [LiveMatchGroup] = []
    @State private var gavang33Matches: [LiveMatchGroup] = []
    @State private var giovangMatches: [LiveMatchGroup] = []

    @State private var selectedProvider: String = "all"
    @State private var heroIndex: Int = 0
    @State private var isLoading: Bool = true
    @State private var selectedGroupForPicker: LiveMatchGroup? = nil
    @State private var activeRoomForPlayer: LiveRoom? = nil

    private let providerPills: [KLFilterItem<String>] = [
        KLFilterItem(id: "all", title: "Tất Cả"),
        KLFilterItem(id: "socolive", title: "Socolive"),
        KLFilterItem(id: "gavang33", title: "Gà Vàng 33"),
        KLFilterItem(id: "colatv", title: "ColaTV"),
        KLFilterItem(id: "giovang", title: "Giờ Vàng TV")
    ]

    private var activeMatchesForCurrentProvider: [LiveMatchGroup] {
        switch selectedProvider {
        case "socolive": return socoliveMatches
        case "gavang33", "gavang": return gavang33Matches
        case "colatv": return colaMatches
        case "giovang", "khandai": return giovangMatches
        default: return socoliveMatches + gavang33Matches + colaMatches + giovangMatches
        }
    }

    private var heroMatches: [LiveMatchGroup] {
        let list = activeMatchesForCurrentProvider
        return Array(list.prefix(8))
    }

    private var currentHero: LiveMatchGroup? {
        guard !heroMatches.isEmpty else { return nil }
        return heroMatches[heroIndex % heroMatches.count]
    }

    var body: some View {
        ZStack {
            KLTheme.bgDeep.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 20) {
                    // 1. Header Bar with Time & GMT+7
                    HStack(alignment: .firstTextBaseline) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("THỂ THAO TRỰC TIẾP")
                                .font(.system(size: 11, weight: .black, design: .rounded))
                                .tracking(1.8)
                                .foregroundColor(KLTheme.brandOrange)

                            Text("Đài Phát Sóng Trực Tuyến")
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(KLTheme.textPrimary)
                        }

                        Spacer()

                        Text(DataNormalizer.formatGMT7Time(Date()) + " · GMT+7")
                            .font(.system(size: 11, weight: .semibold, design: .monospaced))
                            .foregroundColor(KLTheme.textSecondary)
                            .padding(.horizontal, 9)
                            .padding(.vertical, 5)
                            .background(KLTheme.surfaceCard)
                            .cornerRadius(6)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 10)

                    // 2. Segmented Provider Strip (Chuyển Nhanh 4 Đài Độc Lập)
                    KLFilterStrip(items: providerPills, selection: $selectedProvider)
                        .onChange(of: selectedProvider) { _ in
                            heroIndex = 0
                        }

                    // 3. Hero Spotlight Banner
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
                                    withAnimation(.easeInOut(duration: 0.2)) {
                                        heroIndex = (heroIndex + 1) % heroMatches.count
                                    }
                                }
                            }
                        )
                    }

                    // 4. Rails or Filtered Feed
                    if selectedProvider == "all" {
                        // Section: Socolive
                        if !socoliveMatches.isEmpty {
                            SportsProviderRail(
                                title: "Trực Tiếp Socolive",
                                subtitle: "Bình luận viên Socolive sôi động",
                                badgeText: "SOCOLIVE",
                                badgeColor: Color(red: 0.06, green: 0.72, blue: 0.50),
                                matches: socoliveMatches,
                                onTapMatch: { group in
                                    handleMatchSelection(group)
                                }
                            )
                        }

                        // Section: Gà Vàng 33
                        if !gavang33Matches.isEmpty {
                            SportsProviderRail(
                                title: "Trực Tiếp Gà Vàng 33",
                                subtitle: "Luồng phát độc quyền từ Gà Vàng 33",
                                badgeText: "GÀ VÀNG 33",
                                badgeColor: Color(red: 0.96, green: 0.62, blue: 0.04),
                                matches: gavang33Matches,
                                onTapMatch: { group in
                                    handleMatchSelection(group)
                                }
                            )
                        }

                        // Section: ColaTV
                        if !colaMatches.isEmpty {
                            SportsProviderRail(
                                title: "Trực Tiếp ColaTV",
                                subtitle: "Đường truyền tốc độ cao ColaTV",
                                badgeText: "COLATV",
                                badgeColor: KLTheme.brandOrange,
                                matches: colaMatches,
                                onTapMatch: { group in
                                    handleMatchSelection(group)
                                }
                            )
                        }

                        // Section: Giờ Vàng TV
                        if !giovangMatches.isEmpty {
                            SportsProviderRail(
                                title: "Trực Tiếp Giờ Vàng TV",
                                subtitle: "Luồng trực tiếp chất lượng cao Giờ Vàng",
                                badgeText: "GIỜ VÀNG",
                                badgeColor: Color(red: 0.23, green: 0.51, blue: 0.96),
                                matches: giovangMatches,
                                onTapMatch: { group in
                                    handleMatchSelection(group)
                                }
                            )
                        }
                    } else {
                        // Single Provider Vertical Stadium Feed
                        VStack(alignment: .leading, spacing: 12) {
                            KLSectionHeader(
                                title: "Danh Sách Trận Đấu (\(activeMatchesForCurrentProvider.count))",
                                subtitle: "Các trận đấu đang phát trực tiếp",
                                trailingText: "TỰ ĐỘNG CẬP NHẬT"
                            )

                            LazyVStack(spacing: 12) {
                                ForEach(activeMatchesForCurrentProvider) { group in
                                    Button {
                                        handleMatchSelection(group)
                                    } label: {
                                        StadiumMatchCard(group: group)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding(.horizontal, 16)
                        }
                    }

                    Spacer(minLength: 90)
                }
            }
            .refreshable {
                await loadMatches()
            }

            if isLoading && socoliveMatches.isEmpty && gavang33Matches.isEmpty {
                ProgressView()
                    .tint(KLTheme.brandOrange)
            }
        }
        .task {
            if socoliveMatches.isEmpty && gavang33Matches.isEmpty {
                await loadMatches()
            }
        }
        .sheet(item: $selectedGroupForPicker) { group in
            RoomPickerSheet(matchGroup: group) { room in
                activeRoomForPlayer = room
            }
        }
        .fullScreenCover(item: $activeRoomForPlayer) { room in
            HLSPlayerView(
                title: room.matchTitle,
                subtitle: "\(room.providerDisplayName) · \(room.blvName)",
                room: room
            )
        }
    }

    private func handleMatchSelection(_ group: LiveMatchGroup) {
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
}

// MARK: - Hero Spotlight Banner (Typography-First, Screen Bounded)
private struct SportsHeroBanner: View {
    let group: LiveMatchGroup
    let currentIndex: Int
    let totalCount: Int
    let onWatchNow: () -> Void
    let onPickRoom: () -> Void
    let onNextMatch: () -> Void

    var body: some View {
        let top = group.topRoom
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                KLPillBadge(text: "TRỰC TIẾP", fg: .white, bg: KLTheme.liveRed, border: .clear)
                KLPillBadge(text: top.providerDisplayName, fg: .white, bg: providerColor(top.provider), border: .clear)
                KLPillBadge(text: group.league, fg: KLTheme.accentCyan, bg: KLTheme.accentCyan.opacity(0.12), border: KLTheme.accentCyan.opacity(0.28))

                Spacer()

                if totalCount > 1 {
                    Text("\(currentIndex + 1)/\(totalCount)")
                        .font(.system(size: 10.5, weight: .bold, design: .monospaced))
                        .foregroundColor(KLTheme.textSecondary)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 3)
                        .background(Color.black.opacity(0.65))
                        .cornerRadius(5)
                }
            }

            Text(group.matchTitle)
                .font(.system(size: 21, weight: .heavy))
                .foregroundColor(.white)
                .lineLimit(2)

            Text("\(top.blvName) · \(group.rooms.count) phòng bình luận · \(top.notice)")
                .font(.system(size: 12, weight: .regular))
                .foregroundColor(KLTheme.textSecondary)
                .lineLimit(1)

            HStack(spacing: 10) {
                Button(action: onWatchNow) {
                    Text("XEM TRỰC TIẾP")
                        .font(.system(size: 12.5, weight: .bold))
                        .tracking(0.5)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(KLTheme.brandOrange)
                        .cornerRadius(8)
                }

                Button(action: onPickRoom) {
                    Text("PHÒNG BLV (\(group.rooms.count))")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(KLTheme.textPrimary)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(Color.white.opacity(0.12))
                        .cornerRadius(8)
                }

                if totalCount > 1 {
                    Button(action: onNextMatch) {
                        Text("ĐỔI TRẬN ↻")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(KLTheme.textSecondary)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 10)
                            .background(Color.white.opacity(0.08))
                            .cornerRadius(8)
                    }
                }
            }
            .padding(.top, 4)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            ZStack {
                AsyncImage(url: URL(string: top.cover.isEmpty ? top.avatar : top.cover)) { phase in
                    if let image = phase.image {
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } else {
                        LinearGradient(
                            colors: [Color(red: 0.14, green: 0.08, blue: 0.18), KLTheme.bgDeep],
                            startPoint: .topTrailing,
                            endPoint: .bottomLeading
                        )
                    }
                }

                LinearGradient(
                    colors: [
                        KLTheme.bgDeep.opacity(0.15),
                        KLTheme.bgDeep.opacity(0.75),
                        KLTheme.bgDeep
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            }
        )
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(KLTheme.borderSubtle, lineWidth: 1)
        )
        .clipped()
        .padding(.horizontal, 16)
    }

    private func providerColor(_ p: String) -> Color {
        switch p.lowercased() {
        case "gavang", "gavang33": return Color(red: 0.96, green: 0.62, blue: 0.04)
        case "colatv", "cola": return KLTheme.brandOrange
        case "giovang", "khandai": return Color(red: 0.23, green: 0.51, blue: 0.96)
        default: return Color(red: 0.06, green: 0.72, blue: 0.50)
        }
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
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text(title.uppercased())
                            .font(.system(size: 13.5, weight: .heavy, design: .default))
                            .tracking(0.6)
                            .foregroundColor(KLTheme.textPrimary)

                        KLPillBadge(text: badgeText, fg: .white, bg: badgeColor, border: .clear)
                    }

                    Text(subtitle)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(KLTheme.textMuted)
                }

                Spacer()

                Text("\(matches.count) TRẬN")
                    .font(.system(size: 11, weight: .semibold, design: .monospaced))
                    .foregroundColor(KLTheme.textSecondary)
            }
            .padding(.horizontal, 16)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(matches) { group in
                        let top = group.topRoom
                        Button {
                            onTapMatch(group)
                        } label: {
                            VStack(alignment: .leading, spacing: 10) {
                                HStack {
                                    KLPillBadge(text: group.league, fg: KLTheme.accentCyan, bg: KLTheme.accentCyan.opacity(0.10), border: .clear)
                                    Spacer()
                                    Text("LIVE · \(DataNormalizer.formatViewers(group.totalViewers))")
                                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                                        .foregroundColor(KLTheme.liveRed)
                                }

                                Text(group.matchTitle)
                                    .font(.system(size: 14.5, weight: .bold))
                                    .foregroundColor(KLTheme.textPrimary)
                                    .lineLimit(2)
                                    .multilineTextAlignment(.leading)
                                    .frame(height: 38, alignment: .topLeading)

                                Divider()
                                    .background(KLTheme.borderSubtle)

                                HStack {
                                    Text(top.blvName)
                                        .font(.system(size: 11.5, weight: .semibold))
                                        .foregroundColor(KLTheme.brandOrange)
                                        .lineLimit(1)

                                    Spacer()

                                    Text(top.providerDisplayName)
                                        .font(.system(size: 10, weight: .bold))
                                        .foregroundColor(badgeColor)
                                }
                            }
                            .padding(14)
                            .frame(width: 252)
                            .background(KLTheme.surfaceCard)
                            .cornerRadius(14)
                            .overlay(
                                RoundedRectangle(cornerRadius: 14)
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

// MARK: - Stadium Match Card (Vertical Feed Mode)
private struct StadiumMatchCard: View {
    let group: LiveMatchGroup

    var body: some View {
        let top = group.topRoom
        VStack(spacing: 12) {
            HStack {
                KLPillBadge(text: group.league, fg: KLTheme.accentCyan, bg: KLTheme.accentCyan.opacity(0.10), border: .clear)
                KLPillBadge(text: top.providerDisplayName, fg: .white, bg: Color.white.opacity(0.12), border: .clear)

                Spacer()

                Text("ĐANG ĐÁ · \(DataNormalizer.formatViewers(group.totalViewers)) XEM")
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundColor(KLTheme.liveRed)
            }

            HStack(alignment: .center, spacing: 12) {
                Text(group.homeTeamName)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(KLTheme.textPrimary)
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    .lineLimit(1)

                Text("VS")
                    .font(.system(size: 12, weight: .black, design: .monospaced))
                    .foregroundColor(KLTheme.brandOrange)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(KLTheme.bgDeep)
                    .cornerRadius(6)

                Text(group.awayTeamName)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(KLTheme.textPrimary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .lineLimit(1)
            }

            Divider()
                .background(KLTheme.borderSubtle)

            HStack {
                Text(top.blvName)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(KLTheme.brandOrange)

                Spacer()

                Text("XEM NGAY")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(KLTheme.brandOrange)
                    .cornerRadius(6)
            }
        }
        .padding(14)
        .background(KLTheme.surfaceCard)
        .cornerRadius(14)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(KLTheme.borderSubtle, lineWidth: 0.8)
        )
    }
}
