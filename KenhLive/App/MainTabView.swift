import SwiftUI

enum KLTab: Int, CaseIterable, Identifiable {
    case home = 0
    case live = 1
    case iptv = 2
    case phim = 3
    case schedule = 4
    case multiview = 5
    case settings = 6

    var id: Int { rawValue }

    var title: String {
        switch self {
        case .home: return "Cổng Chọn"
        case .live: return "Thể Thao"
        case .iptv: return "Kênh TV"
        case .phim: return "Kho Phim"
        case .schedule: return "Lịch Đấu"
        case .multiview: return "Đa Màn"
        case .settings: return "Cài Đặt"
        }
    }

    static var bottomBarTabs: [KLTab] {
        [.home, .live, .iptv, .phim, .schedule, .settings]
    }
}

struct MainTabView: View {
    @State private var currentTab: KLTab = .home
    @State private var isShowingTelegramSheet: Bool = false
    @AppStorage("seen_notice_v140") private var seenNoticeV140: Bool = false

    var body: some View {
        VStack(spacing: 0) {
            // 1. Flagship Top Brand Bar with Monogram Logo & Quick Actions
            HStack(spacing: 8) {
                Button {
                    KLHaptics.selection()
                    withAnimation(.spring(response: 0.28, dampingFraction: 0.82)) {
                        currentTab = .home
                    }
                } label: {
                    HStack(spacing: 9) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .fill(
                                    LinearGradient(
                                        colors: [KLTheme.brandOrange, Color(red: 1.0, green: 0.55, blue: 0.1)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 28, height: 28)

                            Text("K")
                                .font(.system(size: 16, weight: .black, design: .rounded))
                                .foregroundColor(.white)
                        }

                        VStack(alignment: .leading, spacing: 0) {
                            HStack(spacing: 5) {
                                Text("KENHLIVE")
                                    .font(.system(size: 14.5, weight: .black, design: .rounded))
                                    .tracking(1.1)
                                    .foregroundColor(.white)

                                Circle()
                                    .fill(KLTheme.liveRed)
                                    .frame(width: 6, height: 6)
                            }
                            Text("SMART OTT v1.4.0")
                                .font(.system(size: 8.5, weight: .bold))
                                .tracking(0.8)
                                .foregroundColor(KLTheme.textMuted)
                        }
                    }
                }
                .buttonStyle(.plain)

                Spacer()

                // Quick Switch to MultiView
                Button {
                    KLHaptics.light()
                    withAnimation(.spring(response: 0.28, dampingFraction: 0.82)) {
                        currentTab = .multiview
                    }
                } label: {
                    Text("2 MÀN")
                        .font(.system(size: 10, weight: .heavy))
                        .foregroundColor(currentTab == .multiview ? .white : KLTheme.brandOrange)
                        .padding(.horizontal, 9)
                        .padding(.vertical, 6)
                        .background(currentTab == .multiview ? KLTheme.brandOrange : KLTheme.brandOrange.opacity(0.14))
                        .cornerRadius(8)
                }
                .buttonStyle(KLScaleButtonStyle())

                // Quick Open Telegram Support & Notice
                Button {
                    KLHaptics.medium()
                    isShowingTelegramSheet = true
                } label: {
                    Text("BÁO LỖI")
                        .font(.system(size: 10, weight: .heavy))
                        .foregroundColor(.white)
                        .padding(.horizontal, 9)
                        .padding(.vertical, 6)
                        .background(KLTheme.telegramBlue.opacity(0.24))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(KLTheme.telegramBlue.opacity(0.5), lineWidth: 0.8)
                        )
                        .cornerRadius(8)
                }
                .buttonStyle(KLScaleButtonStyle())

                // Quick Switch to Search
                Button {
                    KLHaptics.light()
                    withAnimation(.spring(response: 0.28, dampingFraction: 0.82)) {
                        currentTab = .settings
                    }
                } label: {
                    Text("TÌM KIẾM")
                        .font(.system(size: 10, weight: .heavy))
                        .foregroundColor(currentTab == .settings ? .white : KLTheme.textSecondary)
                        .padding(.horizontal, 9)
                        .padding(.vertical, 6)
                        .background(currentTab == .settings ? KLTheme.brandOrange : KLTheme.surfaceCard)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(KLTheme.borderSubtle, lineWidth: 0.8)
                        )
                        .cornerRadius(8)
                }
                .buttonStyle(KLScaleButtonStyle())
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(KLTheme.bgDeep)
            .overlay(
                Divider().background(KLTheme.borderSubtle),
                alignment: .bottom
            )

            // 2. Main Tab Content Area
            ZStack {
                switch currentTab {
                case .home:
                    HomeHubView(currentTab: $currentTab) {
                        isShowingTelegramSheet = true
                    }
                case .live:
                    LiveSportsView()
                case .schedule:
                    ScheduleView()
                case .iptv:
                    IptvView()
                case .phim:
                    PhimView()
                case .multiview:
                    MultiViewScreen()
                case .settings:
                    SearchAndSettingsView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .clipped()

            // 3. Minimalist Typography-First Bottom Tab Bar
            VStack(spacing: 0) {
                Divider()
                    .background(KLTheme.borderSubtle)

                HStack(spacing: 4) {
                    ForEach(KLTab.bottomBarTabs) { tab in
                        let isSelected = currentTab == tab
                        Button {
                            KLHaptics.selection()
                            withAnimation(.spring(response: 0.26, dampingFraction: 0.82)) {
                                currentTab = tab
                            }
                        } label: {
                            VStack(spacing: 4) {
                                Capsule()
                                    .fill(isSelected ? (tab == .phim ? KLTheme.netflixRed : KLTheme.brandOrange) : Color.clear)
                                    .frame(width: 20, height: 2.5)

                                Text(tab.title.uppercased())
                                    .font(.system(size: 9.5, weight: isSelected ? .heavy : .semibold, design: .rounded))
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.75)
                                    .foregroundColor(isSelected ? .white : KLTheme.textMuted)
                                    .padding(.vertical, 5)
                                    .frame(maxWidth: .infinity)
                                    .background(
                                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                                            .fill(isSelected ? (tab == .phim ? KLTheme.netflixRed.opacity(0.22) : KLTheme.brandOrange.opacity(0.18)) : Color.clear)
                                    )
                            }
                            .padding(.top, 4)
                            .padding(.bottom, 6)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 8)
                .background(Color(red: 0.04, green: 0.045, blue: 0.075).opacity(0.98))
            }
        }
        .background(KLTheme.bgDeep.ignoresSafeArea())
        .ignoresSafeArea(.keyboard, edges: .bottom)
        .sheet(isPresented: $isShowingTelegramSheet) {
            TelegramFeedbackSheet()
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
}
