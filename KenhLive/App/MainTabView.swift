import SwiftUI

enum KLTab: Int, CaseIterable, Identifiable {
    case live = 0
    case schedule = 1
    case iptv = 2
    case phim = 3
    case multiview = 4
    case settings = 5

    var id: Int { rawValue }

    var title: String {
        switch self {
        case .live: return "Trực Tiếp"
        case .schedule: return "Lịch Đấu"
        case .iptv: return "Truyền Hình"
        case .phim: return "Kho Phim"
        case .multiview: return "MultiView"
        case .settings: return "Cài Đặt"
        }
    }
}

struct MainTabView: View {
    @State private var currentTab: KLTab = .live

    var body: some View {
        ZStack(alignment: .bottom) {
            // Tab Content Pages
            Group {
                switch currentTab {
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

            // Minimalist Typography-First Floating Tab Bar (No Cluttered Icons)
            VStack(spacing: 0) {
                Divider()
                    .background(KLTheme.borderSubtle)

                HStack(spacing: 0) {
                    ForEach(KLTab.allCases) { tab in
                        let isSelected = currentTab == tab
                        Button {
                            withAnimation(.easeInOut(duration: 0.15)) {
                                currentTab = tab
                            }
                        } label: {
                            VStack(spacing: 4) {
                                // Subtle top active indicator line
                                Capsule()
                                    .fill(isSelected ? KLTheme.brandOrange : Color.clear)
                                    .frame(width: 20, height: 2.5)

                                Text(tab.title.uppercased())
                                    .font(.system(size: 10, weight: isSelected ? .heavy : .semibold, design: .rounded))
                                    .tracking(0.4)
                                    .foregroundColor(isSelected ? KLTheme.brandOrange : KLTheme.textMuted)
                                    .frame(maxWidth: .infinity)
                                    .padding(.top, 4)
                                    .padding(.bottom, 6)
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 4)
                .padding(.bottom, 14)
                .background(
                    Color(red: 0.04, green: 0.04, blue: 0.07).opacity(0.96)
                )
            }
        }
        .ignoresSafeArea(.keyboard, edges: .bottom)
    }
}
