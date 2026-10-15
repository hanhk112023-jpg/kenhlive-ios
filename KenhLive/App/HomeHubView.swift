import SwiftUI

struct HomeHubView: View {
    @Binding var currentTab: KLTab
    let onOpenTelegram: () -> Void
    let onOpenSchedule: () -> Void

    @State private var liveMatches: [LiveMatchGroup] = []
    @State private var trendingFilms: [FilmItem] = []
    @State private var selectedMatchForPlayer: LiveRoom? = nil
    @State private var selectedFilmForEpisodes: FilmItem? = nil

    var body: some View {
        ZStack {
            KLTheme.bgDeep.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 20) {
                    // 1. Mobile Editorial Greeting Bar
                    HStack(alignment: .center) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("TRUNG TÂM GIẢI TRÍ")
                                .font(.system(size: 10, weight: .black, design: .rounded))
                                .tracking(1.4)
                                .foregroundColor(KLTheme.brandOrange)

                            Text("Cổng Chọn KenhLive")
                                .font(.system(size: 22, weight: .heavy))
                                .foregroundColor(.white)
                        }

                        Spacer()

                        HStack(spacing: 5) {
                            Circle()
                                .fill(KLTheme.liveRed)
                                .frame(width: 6, height: 6)
                            Text(DataNormalizer.formatGMT7Time(Date()) + " GMT+7")
                                .font(.system(size: 10.5, weight: .bold, design: .monospaced))
                                .foregroundColor(.white)
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
                    .padding(.top, 8)

                    // 2. Three Primary Entertainment Portals (Compact Mobile Cards)
                    VStack(spacing: 10) {
                        // Portal 1: THỂ THAO TRỰC TIẾP
                        MobilePortalRow(
                            badgeText: "ĐANG PHÁT SÓNG",
                            badgeColor: KLTheme.liveRed,
                            title: "Thể Thao Trực Tiếp",
                            subtitle: "4 Đài Độc Lập: Socolive · Gà Vàng 33 · ColaTV · Giờ Vàng TV",
                            iconSystemName: "sportscourt.fill",
                            accentColor: KLTheme.socoEmerald,
                            gradient: [Color(red: 0.05, green: 0.22, blue: 0.17), KLTheme.surfaceCard]
                        ) {
                            KLHaptics.medium()
                            currentTab = .live
                        }

                        // Portal 2: TRUYỀN HÌNH VIỆT NAM
                        MobilePortalRow(
                            badgeText: "FHD SIÊU MƯỢT",
                            badgeColor: KLTheme.accentCyan,
                            title: "Truyền Hình Kênh TV",
                            subtitle: "VTV Quốc Gia · HTV Thể Thao · THVL · Kênh Quốc Tế",
                            iconSystemName: "tv.fill",
                            accentColor: KLTheme.accentCyan,
                            gradient: [Color(red: 0.06, green: 0.16, blue: 0.30), KLTheme.surfaceCard]
                        ) {
                            KLHaptics.medium()
                            currentTab = .iptv
                        }

                        // Portal 3: KHO PHIM NETFLIX CINEMA
                        MobilePortalRow(
                            badgeText: "NETFLIX 4K",
                            badgeColor: KLTheme.netflixRed,
                            title: "Kho Phim Netflix Cinema",
                            subtitle: "Phim Rạp Bom Tấn · Phim Bộ Mới · Hoạt Hình Anime Vietsub",
                            iconSystemName: "film.fill",
                            accentColor: KLTheme.netflixRed,
                            gradient: [Color(red: 0.28, green: 0.05, blue: 0.08), KLTheme.surfaceCard]
                        ) {
                            KLHaptics.medium()
                            currentTab = .phim
                        }
                    }
                    .padding(.horizontal, 16)

                    // 3. Live Matches Quick Carousel (If Available)
                    if !liveMatches.isEmpty {
                        VStack(alignment: .leading, spacing: 10) {
                            HStack {
                                Text("TRẬN CẦU TÂM ĐIỂM")
                                    .font(.system(size: 13, weight: .heavy))
                                    .tracking(0.6)
                                    .foregroundColor(.white)

                                Spacer()

                                Button {
                                    currentTab = .live
                                } label: {
                                    Text("Xem tất cả ›")
                                        .font(.system(size: 11.5, weight: .bold))
                                        .foregroundColor(KLTheme.brandOrange)
                                }
                            }
                            .padding(.horizontal, 16)

                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 10) {
                                    ForEach(liveMatches.prefix(6)) { match in
                                        Button {
                                            selectedMatchForPlayer = match.topRoom
                                        } label: {
                                            VStack(alignment: .leading, spacing: 6) {
                                                HStack {
                                                    KLPillBadge(text: match.league, fg: KLTheme.accentCyan, bg: KLTheme.accentCyan.opacity(0.12), border: .clear)
                                                    Spacer()
                                                    HStack(spacing: 4) {
                                                        Circle().fill(KLTheme.liveRed).frame(width: 5, height: 5)
                                                        Text("LIVE")
                                                            .font(.system(size: 9.5, weight: .heavy))
                                                            .foregroundColor(KLTheme.liveRed)
                                                    }
                                                }

                                                Text(match.matchTitle)
                                                    .font(.system(size: 13, weight: .bold))
                                                    .foregroundColor(.white)
                                                    .lineLimit(1)

                                                HStack {
                                                    Text(match.topRoom.blvName)
                                                        .font(.system(size: 11, weight: .semibold))
                                                        .foregroundColor(KLTheme.brandOrange)
                                                        .lineLimit(1)
                                                    Spacer()
                                                    Text(match.topRoom.providerDisplayName)
                                                        .font(.system(size: 9.5, weight: .bold))
                                                        .foregroundColor(KLTheme.textMuted)
                                                }
                                            }
                                            .padding(12)
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

                    // 4. Trending Films Quick Carousel (If Available)
                    if !trendingFilms.isEmpty {
                        VStack(alignment: .leading, spacing: 10) {
                            HStack {
                                Text("PHIM THỊNH HÀNH HÔM NAY")
                                    .font(.system(size: 13, weight: .heavy))
                                    .tracking(0.6)
                                    .foregroundColor(.white)

                                Spacer()

                                Button {
                                    currentTab = .phim
                                } label: {
                                    Text("Xem kho phim ›")
                                        .font(.system(size: 11.5, weight: .bold))
                                        .foregroundColor(KLTheme.netflixRed)
                                }
                            }
                            .padding(.horizontal, 16)

                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 10) {
                                    ForEach(trendingFilms.prefix(8)) { film in
                                        Button {
                                            selectedFilmForEpisodes = film
                                        } label: {
                                            VStack(alignment: .leading, spacing: 4) {
                                                ZStack(alignment: .topTrailing) {
                                                    AsyncImage(url: URL(string: film.thumbUrl.isEmpty ? film.posterUrl : film.thumbUrl)) { phase in
                                                        if let img = phase.image {
                                                            img.resizable().aspectRatio(contentMode: .fill)
                                                        } else {
                                                            KLTheme.surfaceCard
                                                        }
                                                    }
                                                    .frame(width: 105, height: 155)
                                                    .clipped()
                                                    .cornerRadius(8)

                                                    Text(film.quality)
                                                        .font(.system(size: 8.5, weight: .black))
                                                        .foregroundColor(.white)
                                                        .padding(.horizontal, 4)
                                                        .padding(.vertical, 2)
                                                        .background(KLTheme.netflixRed)
                                                        .cornerRadius(3)
                                                        .padding(4)
                                                }
                                                .overlay(
                                                    RoundedRectangle(cornerRadius: 8)
                                                        .stroke(KLTheme.borderSubtle, lineWidth: 0.8)
                                                )

                                                Text(film.name)
                                                    .font(.system(size: 11.5, weight: .bold))
                                                    .foregroundColor(.white)
                                                    .lineLimit(1)
                                                    .frame(width: 105, alignment: .leading)
                                            }
                                        }
                                        .buttonStyle(KLScaleButtonStyle())
                                    }
                                }
                                .padding(.horizontal, 16)
                            }
                        }
                    }

                    // 5. Bento Utility Grid (2x2)
                    VStack(alignment: .leading, spacing: 10) {
                        KLSectionHeader(
                            title: "Tiện Ích & Hỗ Trợ",
                            subtitle: "Truy cập nhanh các tính năng mở rộng",
                            trailingText: "v1.4.3"
                        )

                        LazyVGrid(columns: [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)], spacing: 10) {
                            HubMiniTile(
                                badge: "EPG 7 NGÀY",
                                badgeColor: KLTheme.brandOrange,
                                title: "Lịch Thi Đấu",
                                iconName: "calendar",
                                action: {
                                    KLHaptics.light()
                                    onOpenSchedule()
                                }
                            )

                            HubMiniTile(
                                badge: "NETFLIX 4K",
                                badgeColor: KLTheme.netflixRed,
                                title: "Kho Phim Hot",
                                iconName: "film.stack.fill",
                                action: {
                                    KLHaptics.light()
                                    currentTab = .phim
                                }
                            )

                            HubMiniTile(
                                badge: "HỆ THỐNG",
                                badgeColor: KLTheme.imdbGold,
                                title: "Cài Đặt & Tìm",
                                iconName: "gearshape.fill",
                                action: {
                                    KLHaptics.light()
                                    currentTab = .settings
                                }
                            )

                            HubMiniTile(
                                badge: "@T990512S",
                                badgeColor: KLTheme.telegramBlue,
                                title: "Báo Lỗi Telegram",
                                iconName: "paperplane.fill",
                                action: {
                                    KLHaptics.medium()
                                    onOpenTelegram()
                                }
                            )
                        }
                        .padding(.horizontal, 16)
                    }

                    Spacer(minLength: 40)
                }
                .padding(.bottom, 20)
            }
        }
        .task {
            async let sportsTask = SportsService.shared.fetchLiveMatches()
            async let phimTask = PhimService.shared.fetchHomeSections()
            let (sportsRes, phimRes) = await (sportsTask, phimTask)
            liveMatches = (sportsRes.socolive + sportsRes.gavang33 + sportsRes.cola + sportsRes.giovang)
            trendingFilms = phimRes.first?.films ?? []
        }
        .fullScreenCover(item: $selectedMatchForPlayer) { room in
            HLSPlayerView(
                title: room.matchTitle,
                subtitle: "\(room.providerDisplayName) · \(room.blvName)",
                room: room
            )
        }
        .sheet(item: $selectedFilmForEpisodes) { film in
            EpisodePickerSheet(
                film: film,
                initialResumeProgress: StorageManager.shared.getProgress(for: film.slug)
            )
        }
    }
}

// MARK: - Compact Mobile Portal Row
private struct MobilePortalRow: View {
    let badgeText: String
    let badgeColor: Color
    let title: String
    let subtitle: String
    let iconSystemName: String
    let accentColor: Color
    let gradient: [Color]
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                // Leading Icon Box
                ZStack {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(accentColor.opacity(0.18))
                        .frame(width: 44, height: 44)

                    Image(systemName: iconSystemName)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(accentColor)
                }

                // Title & Subtitle
                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 6) {
                        Text(title)
                            .font(.system(size: 15.5, weight: .bold))
                            .foregroundColor(.white)

                        KLPillBadge(text: badgeText, fg: .white, bg: badgeColor, border: .clear)
                    }

                    Text(subtitle)
                        .font(.system(size: 11.5, weight: .regular))
                        .foregroundColor(KLTheme.textSecondary)
                        .lineLimit(1)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(KLTheme.textMuted)
            }
            .padding(12)
            .background(
                LinearGradient(colors: gradient, startPoint: .leading, endPoint: .trailing)
            )
            .cornerRadius(14)
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(KLTheme.borderSubtle, lineWidth: 0.8)
            )
        }
        .buttonStyle(KLScaleButtonStyle(scaleAmount: 0.98))
    }
}

// MARK: - Hub Mini Tile
private struct HubMiniTile: View {
    let badge: String
    let badgeColor: Color
    let title: String
    let iconName: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: iconName)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(badgeColor)

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.white)
                        .lineLimit(1)

                    Text(badge)
                        .font(.system(size: 9, weight: .bold, design: .monospaced))
                        .foregroundColor(KLTheme.textMuted)
                }

                Spacer()
            }
            .padding(12)
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
