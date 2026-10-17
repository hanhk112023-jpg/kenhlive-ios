import SwiftUI

struct ScheduleView: View {
    @State private var selectedDayIndex: Int = 0
    @State private var scheduleCache: [Int: [ScheduleItem]] = [:]
    @State private var isLoading: Bool = false
    @State private var activeRoomForPlayer: LiveRoom? = nil
    @State private var searchQuery: String = ""

    @Environment(\.dismiss) private var dismiss

    // Generate dynamic 7 days relative to current date in GMT+7
    private var dayTabs: [(id: Int, title: String, date: Date)] {
        let calendar = Calendar.current
        let today = Date()
        let weekdayFmt = DateFormatter()
        weekdayFmt.locale = Locale(identifier: "vi_VN")
        weekdayFmt.timeZone = TimeZone(identifier: "Asia/Ho_Chi_Minh")
        weekdayFmt.dateFormat = "EEEE · dd/MM"

        return (0..<7).compactMap { offset -> (id: Int, title: String, date: Date)? in
            guard let date = calendar.date(byAdding: .day, value: offset, to: today) else { return nil }
            let title: String
            if offset == 0 {
                title = "Hôm Nay"
            } else if offset == 1 {
                title = "Ngày Mai"
            } else {
                let raw = weekdayFmt.string(from: date)
                title = raw.prefix(1).uppercased() + raw.dropFirst()
            }
            return (id: offset, title: title, date: date)
        }
    }

    private var currentDayFixtures: [ScheduleItem] {
        scheduleCache[selectedDayIndex] ?? []
    }

    private var filteredFixtures: [ScheduleItem] {
        let list = currentDayFixtures
        let q = searchQuery.trimmingCharacters(in: .whitespaces).lowercased()
        guard !q.isEmpty else { return list }
        return list.filter {
            $0.homeName.lowercased().contains(q) ||
            $0.awayName.lowercased().contains(q) ||
            $0.league.lowercased().contains(q) ||
            $0.blvName.lowercased().contains(q)
        }
    }

    var body: some View {
        ZStack {
            KLTheme.bgDeep.ignoresSafeArea()

            VStack(alignment: .leading, spacing: 14) {
                // 1. Drag Indicator & Modal Header
                VStack(spacing: 8) {
                    Capsule()
                        .fill(Color.white.opacity(0.2))
                        .frame(width: 38, height: 4.5)
                        .padding(.top, 10)

                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            HStack(spacing: 5) {
                                Text("LỊCH THI ĐẤU EPG 7 NGÀY")
                                    .font(.system(size: 10, weight: .black, design: .rounded))
                                    .tracking(1.4)
                                    .foregroundColor(KLTheme.brandOrange)

                                Circle()
                                    .fill(KLTheme.brandOrange)
                                    .frame(width: 5, height: 5)
                            }

                            Text("Lịch Bóng Đá Trực Tiếp")
                                .font(.system(size: 20, weight: .heavy, design: .rounded))
                                .foregroundColor(.white)
                        }

                        Spacer()

                        Button {
                            KLHaptics.light()
                            dismiss()
                        } label: {
                            Image(systemName: "xmark")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(.white)
                                .padding(8)
                                .background(Color.white.opacity(0.12))
                                .clipShape(Circle())
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, 16)
                }

                // 2. Search Filter Bar
                KLGlassSearchBar(text: $searchQuery, placeholder: "Tìm trận đấu, câu lạc bộ, giải đấu...")
                    .padding(.horizontal, 16)

                // 3. Dynamic 7-Day Filter Strip
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(dayTabs, id: \.id) { tab in
                            let isSelected = selectedDayIndex == tab.id
                            Button {
                                KLHaptics.selection()
                                withAnimation(.spring(response: 0.28, dampingFraction: 0.8)) {
                                    selectedDayIndex = tab.id
                                }
                                loadFixturesIfNeeded(for: tab.id, date: tab.date)
                            } label: {
                                Text(tab.title)
                                    .font(.system(size: 12, weight: isSelected ? .bold : .medium))
                                    .foregroundColor(isSelected ? .white : KLTheme.textSecondary)
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 7)
                                    .background(
                                        isSelected ?
                                        LinearGradient(colors: [KLTheme.brandOrange, Color(red: 1.0, green: 0.55, blue: 0.1)], startPoint: .topLeading, endPoint: .bottomTrailing) :
                                        LinearGradient(colors: [Color.white.opacity(0.06), Color.white.opacity(0.03)], startPoint: .top, endPoint: .bottom)
                                    )
                                    .cornerRadius(8)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(isSelected ? Color.clear : KLTheme.borderSubtle, lineWidth: 0.8)
                                    )
                            }
                            .buttonStyle(KLScaleButtonStyle())
                        }
                    }
                    .padding(.horizontal, 16)
                }

                // 4. Fixtures Scroll List
                if isLoading && currentDayFixtures.isEmpty {
                    VStack(spacing: 12) {
                        ForEach(0..<4, id: \.self) { _ in
                            KLSkeletonView(height: 80, cornerRadius: 12)
                                .padding(.horizontal, 16)
                        }
                    }
                    .padding(.top, 10)
                    Spacer()
                } else if filteredFixtures.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "calendar.badge.exclamationmark")
                            .font(.system(size: 38))
                            .foregroundColor(KLTheme.textMuted)

                        Text("Không có trận đấu nào trong ngày này")
                            .font(.system(size: 13.5, weight: .medium))
                            .foregroundColor(KLTheme.textSecondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 60)
                    Spacer()
                } else {
                    ScrollView(showsIndicators: false) {
                        LazyVStack(spacing: 10) {
                            ForEach(filteredFixtures) { item in
                                renderFixtureCard(item)
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.bottom, 30)
                    }
                }
            }
        }
        .task {
            if let first = dayTabs.first {
                loadFixturesIfNeeded(for: first.id, date: first.date)
            }
        }
        .fullScreenCover(item: $activeRoomForPlayer) { room in
            HLSPlayerView(
                title: room.matchTitle,
                subtitle: room.league,
                room: room,
                onClose: {
                    activeRoomForPlayer = nil
                }
            )
        }
    }

    // MARK: - Fixture Card Component
    @ViewBuilder
    private func renderFixtureCard(_ item: ScheduleItem) -> some View {
        Button {
            KLHaptics.medium()
            let rNum = item.roomNum.isEmpty ? "235232" : item.roomNum
            activeRoomForPlayer = LiveRoom(
                roomNum: rNum,
                blvName: item.blvName,
                avatar: item.homeLogo,
                viewers: 52000,
                matchTitle: "\(item.homeName) vs \(item.awayName)",
                league: item.league,
                cover: item.homeLogo,
                category: "Bóng đá",
                blvLevel: "VIP",
                score: 0,
                notice: "Trực tiếp bóng đá chất lượng cao"
            )
        } label: {
            VStack(spacing: 10) {
                // Header: League + Match Time + Live Status Pill
                HStack {
                    Text(item.league)
                        .font(.system(size: 9.5, weight: .bold))
                        .foregroundColor(KLTheme.accentCyan)
                        .lineLimit(1)

                    Spacer()

                    Text(item.matchTime)
                        .font(.system(size: 11, weight: .medium, design: .monospaced))
                        .foregroundColor(KLTheme.textMuted)

                    if item.statusText == "ĐANG ĐÁ" {
                        KLLivePulseBadge(text: "LIVE", color: KLTheme.liveRed)
                    } else {
                        Text(item.statusText)
                            .font(.system(size: 9.5, weight: .bold))
                            .foregroundColor(KLTheme.textSecondary)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2.5)
                            .background(Color.white.opacity(0.08))
                            .cornerRadius(4)
                    }
                }

                // Body: Team A vs Team B Stadium Faceoff
                HStack(alignment: .center, spacing: 8) {
                    // Home Team
                    HStack(spacing: 8) {
                        Text(item.homeName)
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(.white)
                            .lineLimit(1)
                            .frame(maxWidth: .infinity, alignment: .trailing)

                        TeamLogoImageView(url: item.homeLogo, teamName: item.homeName, size: 28)
                    }

                    // Scoreboard Box
                    VStack(spacing: 2) {
                        if item.statusText == "ĐANG ĐÁ" && item.homeScore != "-" {
                            Text("\(item.homeScore) : \(item.awayScore)")
                                .font(.system(size: 14, weight: .black, design: .rounded))
                                .foregroundColor(KLTheme.brandOrange)
                        } else {
                            Text("VS")
                                .font(.system(size: 11, weight: .heavy, design: .monospaced))
                                .foregroundColor(KLTheme.textMuted)
                        }
                    }
                    .frame(width: 50)

                    // Away Team
                    HStack(spacing: 8) {
                        TeamLogoImageView(url: item.awayLogo, teamName: item.awayName, size: 28)

                        Text(item.awayName)
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(.white)
                            .lineLimit(1)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }

                // Footer: Commentator badge if present
                if !item.blvName.isEmpty && item.blvName != "BLV Socolive" {
                    HStack(spacing: 4) {
                        Image(systemName: "mic.fill")
                            .font(.system(size: 9))
                            .foregroundColor(KLTheme.brandOrange)

                        Text(item.blvName)
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(KLTheme.textSecondary)

                        Spacer()

                        Image(systemName: "play.circle.fill")
                            .font(.system(size: 14))
                            .foregroundColor(KLTheme.brandOrange)
                    }
                    .padding(.top, 2)
                }
            }
            .padding(12)
            .klGlassCard(cornerRadius: 12)
        }
        .buttonStyle(KLScaleButtonStyle())
    }

    // MARK: - Logic Helpers
    private func loadFixturesIfNeeded(for dayIndex: Int, date: Date) {
        if scheduleCache[dayIndex] != nil {
            return
        }

        isLoading = true
        Task {
            let items = await SportsService.shared.fetchSchedule(for: date)
            await MainActor.run {
                self.scheduleCache[dayIndex] = items
                self.isLoading = false
            }
        }
    }
}

// MARK: - Team Logo Image View Helper
private struct TeamLogoImageView: View {
    let url: String
    let teamName: String
    let size: CGFloat

    var resolvedUrl: String {
        if !url.isEmpty { return url }
        return TeamLogoRegistry.shared.findLogo(for: teamName) ?? ""
    }

    var body: some View {
        if !resolvedUrl.isEmpty, let imgUrl = URL(string: resolvedUrl) {
            AsyncImage(url: imgUrl) { phase in
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
