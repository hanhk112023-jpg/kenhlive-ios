import SwiftUI

struct LiveSportsView: View {
    @State private var socoliveMatches: [LiveMatchGroup] = []
    @State private var colaMatches: [LiveMatchGroup] = []
    @State private var gavangMatches: [LiveMatchGroup] = []
    @State private var khandaiMatches: [LiveMatchGroup] = []

    @State private var heroIndex: Int = 0
    @State private var isLoading: Bool = true
    @State private var selectedGroupForPicker: LiveMatchGroup? = nil
    @State private var activeRoomForPlayer: LiveRoom? = nil

    private var heroMatches: [LiveMatchGroup] {
        Array(socoliveMatches.prefix(6))
    }

    private var currentHero: LiveMatchGroup? {
        guard !heroMatches.isEmpty else { return colaMatches.first }
        return heroMatches[heroIndex % heroMatches.count]
    }

    var body: some View {
        ZStack {
            KLTheme.bgDeep.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 26) {
                    // 1. Editorial Header
                    HStack(alignment: .lastTextBaseline) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("KENHLIVE")
                                .font(.system(size: 11, weight: .black, design: .rounded))
                                .tracking(2.0)
                                .foregroundColor(KLTheme.brandOrange)

                            Text("Trực Tiếp Thể Thao")
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(KLTheme.textPrimary)
                        }

                        Spacer()

                        Text(DataNormalizer.formatGMT7Time(Date()) + " · GMT+7")
                            .font(.system(size: 11.5, weight: .semibold, design: .monospaced))
                            .foregroundColor(KLTheme.textSecondary)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(KLTheme.surfaceCard)
                            .cornerRadius(6)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 12)

                    // 2. Hero Spotlight Banner
                    if let hero = currentHero {
                        SportsHeroBanner(
                            group: hero,
                            currentIndex: heroIndex,
                            totalCount: max(1, heroMatches.count),
                            onWatchNow: {
                                activeRoomForPlayer = hero.topRoom
                            },
                            onPickRoom: {
                                selectedGroupForPicker = hero
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

                    // 3. Strictly Separate 4 Sports Provider Rails (Never Merged)
                    if !socoliveMatches.isEmpty {
                        SportsProviderRail(
                            title: "Trực Tiếp Socolive",
                            subtitle: "Bình luận viên tâm điểm",
                            matches: socoliveMatches,
                            onTapMatch: { group in
                                if group.rooms.count > 1 {
                                    selectedGroupForPicker = group
                                } else {
                                    activeRoomForPlayer = group.topRoom
                                }
                            }
                        )
                    }

                    if !colaMatches.isEmpty {
                        SportsProviderRail(
                            title: "Trực Tiếp ColaTV",
                            subtitle: "Đường truyền tốc độ cao",
                            matches: colaMatches,
                            onTapMatch: { group in
                                activeRoomForPlayer = group.topRoom
                            }
                        )
                    }

                    if !gavangMatches.isEmpty {
                        SportsProviderRail(
                            title: "Trực Tiếp Gà Vàng",
                            subtitle: "Âm thanh sân vận động",
                            matches: gavangMatches,
                            onTapMatch: { group in
                                activeRoomForPlayer = group.topRoom
                            }
                        )
                    }

                    if !khandaiMatches.isEmpty {
                        SportsProviderRail(
                            title: "Trực Tiếp Khán Đài",
                            subtitle: "Bình luận chuyên sâu",
                            matches: khandaiMatches,
                            onTapMatch: { group in
                                activeRoomForPlayer = group.topRoom
                            }
                        )
                    }

                    Spacer(minLength: 90)
                }
            }
            .refreshable {
                await loadMatches()
            }

            if isLoading && socoliveMatches.isEmpty && colaMatches.isEmpty {
                ProgressView()
                    .tint(KLTheme.brandOrange)
            }
        }
        .task {
            if socoliveMatches.isEmpty && colaMatches.isEmpty {
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
                subtitle: "\(room.league) · \(room.blvName)",
                roomNum: room.roomNum,
                directUrl: nil
            )
        }
    }

    private func loadMatches() async {
        isLoading = true
        let res = await SportsService.shared.fetchLiveMatches()
        socoliveMatches = res.socolive
        colaMatches = res.cola
        gavangMatches = res.gavang
        khandaiMatches = res.khandai
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
                KLPillBadge(text: group.league, fg: KLTheme.accentCyan, bg: KLTheme.accentCyan.opacity(0.12), border: KLTheme.accentCyan.opacity(0.28))
                KLPillBadge(text: "\(DataNormalizer.formatViewers(group.totalViewers)) XEM", fg: KLTheme.textSecondary, bg: Color.black.opacity(0.45), border: KLTheme.borderSubtle)

                Spacer()

                if totalCount > 1 {
                    Text("\(currentIndex + 1)/\(totalCount)")
                        .font(.system(size: 10.5, weight: .bold, design: .monospaced))
                        .foregroundColor(KLTheme.textSecondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Color.black.opacity(0.5))
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
                    Text("XEM NGAY")
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
                        .background(Color.white.opacity(0.10))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(KLTheme.borderSubtle, lineWidth: 1)
                        )
                        .cornerRadius(8)
                }

                if totalCount > 1 {
                    Button(action: onNextMatch) {
                        Text("ĐỔI TRẬN")
                            .font(.system(size: 11.5, weight: .semibold))
                            .foregroundColor(KLTheme.textSecondary)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 10)
                            .background(Color.white.opacity(0.06))
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
}

// MARK: - Horizontal Sports Provider Rail
private struct SportsProviderRail: View {
    let title: String
    let subtitle: String
    let matches: [LiveMatchGroup]
    let onTapMatch: (LiveMatchGroup) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            KLSectionHeader(
                title: title,
                subtitle: subtitle,
                trailingText: "\(matches.count) TRẬN"
            )

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

                                    Text("\(group.rooms.count) phòng")
                                        .font(.system(size: 11, weight: .medium))
                                        .foregroundColor(KLTheme.textMuted)
                                }
                            }
                            .padding(14)
                            .frame(width: 248)
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
