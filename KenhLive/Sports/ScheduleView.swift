import SwiftUI

struct ScheduleView: View {
    @State private var selectedDay: String = "Hôm nay"
    @State private var fixtures: [ScheduleItem] = []
    @State private var activeRoomForPlayer: LiveRoom? = nil

    private let dayTabs: [KLFilterItem<String>] = [
        KLFilterItem(id: "Hôm nay", title: "Hôm Nay"),
        KLFilterItem(id: "Ngày mai", title: "Ngày Mai"),
        KLFilterItem(id: "12/10", title: "Thứ Hai · 12/10"),
        KLFilterItem(id: "13/10", title: "Thứ Ba · 13/10"),
        KLFilterItem(id: "14/10", title: "Thứ Tư · 14/10"),
        KLFilterItem(id: "15/10", title: "Thứ Năm · 15/10")
    ]

    var filteredFixtures: [ScheduleItem] {
        if selectedDay == "Hôm nay" {
            return fixtures
        }
        return fixtures.filter { $0.matchTime.contains(selectedDay) || selectedDay == "Hôm nay" }
    }

    var body: some View {
        ZStack {
            KLTheme.bgDeep.ignoresSafeArea()

            VStack(alignment: .leading, spacing: 16) {
                // Header
                VStack(alignment: .leading, spacing: 2) {
                    Text("LỊCH THI ĐẤU EPG")
                        .font(.system(size: 11, weight: .black, design: .rounded))
                        .tracking(1.6)
                        .foregroundColor(KLTheme.brandOrange)

                    Text("Lịch Bóng Đá 7 Ngày")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(KLTheme.textPrimary)
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)

                // Day Filter Pills
                KLFilterStrip(items: dayTabs, selection: $selectedDay)

                // Fixture Cards
                ScrollView(showsIndicators: false) {
                    LazyVStack(spacing: 12) {
                        ForEach(filteredFixtures.isEmpty ? fixtures : filteredFixtures) { item in
                            Button {
                                activeRoomForPlayer = LiveRoom(
                                    roomNum: "sched_1",
                                    blvName: "BLV Socolive",
                                    avatar: "",
                                    viewers: 52000,
                                    matchTitle: "\(item.homeName) vs \(item.awayName)",
                                    league: item.league,
                                    cover: "",
                                    category: "Bóng đá",
                                    blvLevel: "Lv.5",
                                    score: 0,
                                    notice: "Trực tiếp bóng đá tốc độ cao"
                                )
                            } label: {
                                VStack(spacing: 12) {
                                    HStack {
                                        KLPillBadge(
                                            text: item.league,
                                            fg: KLTheme.accentCyan,
                                            bg: KLTheme.accentCyan.opacity(0.10),
                                            border: .clear
                                        )

                                        Spacer()

                                        Text(item.matchTime)
                                            .font(.system(size: 11.5, weight: .medium, design: .monospaced))
                                            .foregroundColor(KLTheme.textSecondary)

                                        KLPillBadge(
                                            text: item.statusText,
                                            fg: item.statusText == "ĐANG ĐÁ" ? .white : KLTheme.textSecondary,
                                            bg: item.statusText == "ĐANG ĐÁ" ? KLTheme.liveRed : Color.white.opacity(0.08),
                                            border: .clear
                                        )
                                    }

                                    HStack(alignment: .center, spacing: 12) {
                                        Text(item.homeName)
                                            .font(.system(size: 15, weight: .bold))
                                            .foregroundColor(KLTheme.textPrimary)
                                            .frame(maxWidth: .infinity, alignment: .trailing)
                                            .lineLimit(1)

                                        Text("\(item.homeScore) : \(item.awayScore)")
                                            .font(.system(size: 16, weight: .black, design: .monospaced))
                                            .foregroundColor(KLTheme.brandOrange)
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 5)
                                            .background(KLTheme.bgDeep)
                                            .cornerRadius(8)

                                        Text(item.awayName)
                                            .font(.system(size: 15, weight: .bold))
                                            .foregroundColor(KLTheme.textPrimary)
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                            .lineLimit(1)
                                    }

                                    if item.hasLive {
                                        HStack {
                                            Text("Đã có phòng bình luận trực tiếp")
                                                .font(.system(size: 11, weight: .regular))
                                                .foregroundColor(KLTheme.textMuted)
                                            Spacer()
                                            Text("VÀO PHÒNG")
                                                .font(.system(size: 11, weight: .bold))
                                                .foregroundColor(KLTheme.brandOrange)
                                        }
                                    }
                                }
                                .padding(16)
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
                    .padding(.bottom, 90)
                }
            }
        }
        .task {
            if fixtures.isEmpty {
                fixtures = await SportsService.shared.fetchSchedule()
            }
        }
        .fullScreenCover(item: $activeRoomForPlayer) { room in
            HLSPlayerView(
                title: room.matchTitle,
                subtitle: room.league,
                roomNum: room.roomNum,
                directUrl: nil
            )
        }
    }
}
