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
        case .iptv: return "Kênh TV"
        case .phim: return "Kho Phim"
        case .multiview: return "Đa Màn"
        case .settings: return "Cài Đặt"
        }
    }
}

struct MainTabView: View {
    @State private var currentTab: KLTab = .live

    var body: some View {
        VStack(spacing: 0) {
            // 1. Flagship Top Brand Bar with Monogram Logo
            HStack(spacing: 10) {
                // Stylized "K" Brand Monogram Logo
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
                            .font(.system(size: 15, weight: .black, design: .rounded))
                            .tracking(1.2)
                            .foregroundColor(.white)

                        Circle()
                            .fill(KLTheme.liveRed)
                            .frame(width: 6, height: 6)
                    }
                    Text("OTT ENTERTAINMENT")
                        .font(.system(size: 8.5, weight: .bold))
                        .tracking(1.0)
                        .foregroundColor(KLTheme.textMuted)
                }

                Spacer()

                // Quick Switch to MultiView
                Button {
                    withAnimation(.easeInOut(duration: 0.18)) {
                        currentTab = .multiview
                    }
                } label: {
                    Text("2 MÀN HÌNH")
                        .font(.system(size: 10.5, weight: .bold))
                        .foregroundColor(currentTab == .multiview ? .white : KLTheme.brandOrange)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(currentTab == .multiview ? KLTheme.brandOrange : KLTheme.brandOrange.opacity(0.14))
                        .cornerRadius(8)
                }

                // Quick Switch to Search
                Button {
                    withAnimation(.easeInOut(duration: 0.18)) {
                        currentTab = .settings
                    }
                } label: {
                    Text("TÌM KIẾM")
                        .font(.system(size: 10.5, weight: .bold))
                        .foregroundColor(currentTab == .settings ? .white : KLTheme.textSecondary)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(currentTab == .settings ? KLTheme.brandOrange : KLTheme.surfaceCard)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(KLTheme.borderSubtle, lineWidth: 0.8)
                        )
                        .cornerRadius(8)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(KLTheme.bgDeep)
            .overlay(
                Divider().background(KLTheme.borderSubtle),
                alignment: .bottom
            )

            // 2. Main Tab Content Area
            ZStack {
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
            .clipped()

            // 3. Minimalist Typography-First Bottom Tab Bar (Fit to Screen Width)
            VStack(spacing: 0) {
                Divider()
                    .background(KLTheme.borderSubtle)

                HStack(spacing: 4) {
                    ForEach(KLTab.allCases) { tab in
                        let isSelected = currentTab == tab
                        Button {
                            withAnimation(.easeInOut(duration: 0.16)) {
                                currentTab = tab
                            }
                        } label: {
                            VStack(spacing: 4) {
                                Capsule()
                                    .fill(isSelected ? KLTheme.brandOrange : Color.clear)
                                    .frame(width: 18, height: 2.5)

                                Text(tab.title.uppercased())
                                    .font(.system(size: 10, weight: isSelected ? .heavy : .semibold, design: .rounded))
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.8)
                                    .foregroundColor(isSelected ? .white : KLTheme.textMuted)
                                    .padding(.vertical, 5)
                                    .frame(maxWidth: .infinity)
                                    .background(
                                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                                            .fill(isSelected ? KLTheme.brandOrange.opacity(0.18) : Color.clear)
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
    }
}
