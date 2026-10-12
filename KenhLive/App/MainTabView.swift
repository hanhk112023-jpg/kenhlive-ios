import SwiftUI

enum KLTab: Int, CaseIterable, Identifiable {
    case home = 0
    case live = 1
    case iptv = 2
    case phim = 3
    case settings = 4

    var id: Int { rawValue }

    var title: String {
        switch self {
        case .home: return "Trang Chủ"
        case .live: return "Thể Thao"
        case .iptv: return "Truyền Hình"
        case .phim: return "Kho Phim"
        case .settings: return "Hệ Thống"
        }
    }

    var iconName: String {
        switch self {
        case .home: return "house.fill"
        case .live: return "sportscourt.fill"
        case .iptv: return "tv.fill"
        case .phim: return "film.fill"
        case .settings: return "gearshape.fill"
        }
    }
}

struct MainTabView: View {
    @State private var selectedTab: KLTab = .home
    @State private var isShowingTelegramSheet: Bool = false
    @State private var isShowingMultiView: Bool = false
    @State private var isShowingSchedule: Bool = false
    @AppStorage("seen_notice_v140") private var seenNoticeV140: Bool = false

    var body: some View {
        VStack(spacing: 0) {
            // 1. Mobile-Optimized Slim Top Header Bar
            HStack(spacing: 10) {
                // Monogram K + KenhLive Brand
                Button {
                    KLHaptics.selection()
                    withAnimation(.spring(response: 0.28, dampingFraction: 0.82)) {
                        selectedTab = .home
                    }
                } label: {
                    HStack(spacing: 8) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 7, style: .continuous)
                                .fill(
                                    LinearGradient(
                                        colors: [KLTheme.brandOrange, Color(red: 1.0, green: 0.55, blue: 0.1)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 26, height: 26)

                            Text("K")
                                .font(.system(size: 15, weight: .black, design: .rounded))
                                .foregroundColor(.white)
                        }

                        HStack(spacing: 4) {
                            Text("KENHLIVE")
                                .font(.system(size: 14, weight: .black, design: .rounded))
                                .tracking(1.0)
                                .foregroundColor(.white)

                            Circle()
                                .fill(KLTheme.liveRed)
                                .frame(width: 5, height: 5)
                        }
                    }
                }
                .buttonStyle(.plain)

                Spacer()

                // Quick MultiView Button
                Button {
                    KLHaptics.light()
                    isShowingMultiView = true
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "rectangle.split.2x1.fill")
                            .font(.system(size: 10, weight: .bold))
                        Text("2 MÀN")
                            .font(.system(size: 9.5, weight: .heavy))
                    }
                    .foregroundColor(KLTheme.brandOrange)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 5)
                    .background(KLTheme.brandOrange.opacity(0.14))
                    .cornerRadius(7)
                }
                .buttonStyle(KLScaleButtonStyle())

                // Quick Telegram Support Button
                Button {
                    KLHaptics.medium()
                    isShowingTelegramSheet = true
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "paperplane.fill")
                            .font(.system(size: 10, weight: .bold))
                        Text("BÁO LỖI")
                            .font(.system(size: 9.5, weight: .heavy))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 5)
                    .background(KLTheme.telegramBlue.opacity(0.25))
                    .overlay(
                        RoundedRectangle(cornerRadius: 7)
                            .stroke(KLTheme.telegramBlue.opacity(0.5), lineWidth: 0.8)
                    )
                    .cornerRadius(7)
                }
                .buttonStyle(KLScaleButtonStyle())
            }
            .padding(.horizontal, 14)
            .padding(.top, 6)
            .padding(.bottom, 8)
            .background(KLTheme.bgDeep)
            .overlay(
                Divider().background(KLTheme.borderSubtle),
                alignment: .bottom
            )

            // 2. Native SwiftUI TabView for iPhone (Zero Crash, Retains State, Respects Safe Area)
            TabView(selection: $selectedTab) {
                HomeHubView(
                    currentTab: $selectedTab,
                    onOpenTelegram: { isShowingTelegramSheet = true },
                    onOpenMultiView: { isShowingMultiView = true },
                    onOpenSchedule: { isShowingSchedule = true }
                )
                .tabItem {
                    Label(KLTab.home.title, systemImage: KLTab.home.iconName)
                }
                .tag(KLTab.home)

                LiveSportsView()
                    .tabItem {
                        Label(KLTab.live.title, systemImage: KLTab.live.iconName)
                    }
                    .tag(KLTab.live)

                IptvView()
                    .tabItem {
                        Label(KLTab.iptv.title, systemImage: KLTab.iptv.iconName)
                    }
                    .tag(KLTab.iptv)

                PhimView()
                    .tabItem {
                        Label(KLTab.phim.title, systemImage: KLTab.phim.iconName)
                    }
                    .tag(KLTab.phim)

                SearchAndSettingsView()
                    .tabItem {
                        Label(KLTab.settings.title, systemImage: KLTab.settings.iconName)
                    }
                    .tag(KLTab.settings)
            }
            .tint(KLTheme.brandOrange)
        }
        .background(KLTheme.bgDeep.ignoresSafeArea())
        .sheet(isPresented: $isShowingTelegramSheet) {
            TelegramFeedbackSheet()
        }
        .sheet(isPresented: $isShowingMultiView) {
            MultiViewScreen()
        }
        .sheet(isPresented: $isShowingSchedule) {
            ScheduleView()
        }
        .onAppear {
            setupTabBarAppearance()
            if !seenNoticeV140 {
                seenNoticeV140 = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                    isShowingTelegramSheet = true
                }
            }
        }
    }

    private func setupTabBarAppearance() {
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(red: 10/255, green: 11/255, blue: 18/255, alpha: 0.96)

        // Normal item appearance
        let normalColor = UIColor(red: 140/255, green: 148/255, blue: 165/255, alpha: 1.0)
        let selectedColor = UIColor(red: 255/255, green: 101/255, blue: 0/255, alpha: 1.0)

        appearance.stackedLayoutAppearance.normal.iconColor = normalColor
        appearance.stackedLayoutAppearance.normal.titleTextAttributes = [
            .foregroundColor: normalColor,
            .font: UIFont.systemFont(ofSize: 10, weight: .semibold)
        ]

        appearance.stackedLayoutAppearance.selected.iconColor = selectedColor
        appearance.stackedLayoutAppearance.selected.titleTextAttributes = [
            .foregroundColor: selectedColor,
            .font: UIFont.systemFont(ofSize: 10, weight: .bold)
        ]

        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }
}
