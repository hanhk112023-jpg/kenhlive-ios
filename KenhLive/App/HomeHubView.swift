import SwiftUI

struct HomeHubView: View {
    @Binding var currentTab: KLTab
    let onOpenTelegram: () -> Void

    @State private var currentTimeStr: String = DataNormalizer.formatGMT7Time(Date())

    var body: some View {
        ZStack {
            KLTheme.bgDeep.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 18) {
                    // 1. Editorial Welcome Header
                    HStack(alignment: .firstTextBaseline) {
                        VStack(alignment: .leading, spacing: 3) {
                            Text("TRUNG TÂM GIẢI TRÍ ĐA NĂNG")
                                .font(.system(size: 10.5, weight: .black, design: .rounded))
                                .tracking(1.8)
                                .foregroundColor(KLTheme.brandOrange)

                            Text("Cổng Chọn KenhLive")
                                .font(.system(size: 25, weight: .heavy))
                                .foregroundColor(.white)
                        }

                        Spacer()

                        VStack(alignment: .trailing, spacing: 3) {
                            HStack(spacing: 5) {
                                Circle()
                                    .fill(KLTheme.socoEmerald)
                                    .frame(width: 6, height: 6)
                                Text(currentTimeStr + " · GMT+7")
                                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                                    .foregroundColor(.white)
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(KLTheme.surfaceCard)
                            .cornerRadius(8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(KLTheme.borderSubtle, lineWidth: 0.8)
                            )
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 10)

                    // 2. Three Primary Entertainment Portals (Đồng bộ chuẩn TV v7.4.3)
                    VStack(spacing: 14) {
                        // PORTAL 1: THỂ THAO TRỰC TIẾP
                        HubPortalCard(
                            categoryTag: "PHÂN KHU 01 · THỂ THAO",
                            statusBadge: "ĐANG TRỰC TIẾP",
                            statusColor: KLTheme.liveRed,
                            title: "THỂ THAO TRỰC TIẾP",
                            subtitle: "Bóng đá, Bóng rổ, Tennis, eSports với dàn BLV sôi động nhất Việt Nam.",
                            highlights: ["SOCOLIVE", "GÀ VÀNG 33", "COLATV", "GIỜ VÀNG TV"],
                            ctaText: "VÀO SẢNH THỂ THAO →",
                            gradientColors: [
                                Color(red: 0.05, green: 0.24, blue: 0.19),
                                Color(red: 0.06, green: 0.11, blue: 0.18),
                                KLTheme.surfaceCard
                            ],
                            accentColor: KLTheme.socoEmerald
                        ) {
                            KLHaptics.medium()
                            withAnimation(.spring(response: 0.32, dampingFraction: 0.82)) {
                                currentTab = .live
                            }
                        }

                        // PORTAL 2: TRUYỀN HÌNH VIỆT NAM
                        HubPortalCard(
                            categoryTag: "PHÂN KHU 02 · TRUYỀN HÌNH",
                            statusBadge: "FHD SIÊU MƯỢT",
                            statusColor: KLTheme.accentCyan,
                            title: "TRUYỀN HÌNH TRỰC TUYẾN",
                            subtitle: "Hệ thống kênh VTV Quốc Gia, HTV, THVL, Kênh Địa Phương & Quốc Tế chọn lọc.",
                            highlights: ["VTV1 - VTV9", "HTV THỂ THAO", "THVL1 - THVL2", "KÊNH ĐỊA PHƯƠNG"],
                            ctaText: "MỞ TRUYỀN HÌNH TV →",
                            gradientColors: [
                                Color(red: 0.06, green: 0.18, blue: 0.34),
                                Color(red: 0.06, green: 0.10, blue: 0.20),
                                KLTheme.surfaceCard
                            ],
                            accentColor: KLTheme.accentCyan
                        ) {
                            KLHaptics.medium()
                            withAnimation(.spring(response: 0.32, dampingFraction: 0.82)) {
                                currentTab = .iptv
                            }
                        }

                        // PORTAL 3: KHO PHIM ĐIỆN ẢNH NETFLIX
                        HubPortalCard(
                            categoryTag: "PHÂN KHU 03 · RẠP PHIM",
                            statusBadge: "NETFLIX CINEMA",
                            statusColor: KLTheme.netflixRed,
                            title: "KHO PHIM ĐIỆN ẢNH",
                            subtitle: "Giao diện chuẩn Netflix Smart TV. Phim chiếu rạp, phim bộ, hoạt hình 4K Vietsub.",
                            highlights: ["98% PHÙ HỢP", "TOP 10 HÔM NAY", "PHIM BỘ MỚI", "4K VIETSUB"],
                            ctaText: "KHÁM PHÁ RẠP PHIM →",
                            gradientColors: [
                                Color(red: 0.32, green: 0.05, blue: 0.09),
                                Color(red: 0.14, green: 0.06, blue: 0.12),
                                KLTheme.surfaceCard
                            ],
                            accentColor: KLTheme.netflixRed
                        ) {
                            KLHaptics.medium()
                            withAnimation(.spring(response: 0.32, dampingFraction: 0.82)) {
                                currentTab = .phim
                            }
                        }
                    }
                    .padding(.horizontal, 16)

                    // 3. Bento Utility Grid (Lịch Đấu, Đa Màn, Cài Đặt, Báo Lỗi Telegram)
                    VStack(alignment: .leading, spacing: 12) {
                        KLSectionHeader(
                            title: "Tiện Ích & Hỗ Trợ Hệ Thống",
                            subtitle: "Truy cập nhanh các công cụ nâng cao",
                            trailingText: "v1.4.0"
                        )

                        LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
                            HubUtilityTile(
                                badge: "EPG 7 NGÀY",
                                badgeColor: KLTheme.brandOrange,
                                title: "Lịch Thi Đấu",
                                subtitle: "Tâm điểm các giải đấu hôm nay",
                                action: {
                                    KLHaptics.light()
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.82)) {
                                        currentTab = .schedule
                                    }
                                }
                            )

                            HubUtilityTile(
                                badge: "2 LUỒNG LIVE",
                                badgeColor: KLTheme.socoEmerald,
                                title: "Xem Đa Màn",
                                subtitle: "Theo dõi 2 trận đấu cùng lúc",
                                action: {
                                    KLHaptics.light()
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.82)) {
                                        currentTab = .multiview
                                    }
                                }
                            )

                            HubUtilityTile(
                                badge: "TÌM NHANH",
                                badgeColor: KLTheme.imdbGold,
                                title: "Tìm Kiếm & Cài Đặt",
                                subtitle: "Tra cứu phim, chất lượng phát",
                                action: {
                                    KLHaptics.light()
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.82)) {
                                        currentTab = .settings
                                    }
                                }
                            )

                            HubUtilityTile(
                                badge: "@T990512S",
                                badgeColor: KLTheme.telegramBlue,
                                title: "Báo Lỗi Telegram",
                                subtitle: "Quét QR hỗ trợ & yêu cầu kênh",
                                action: {
                                    KLHaptics.medium()
                                    onOpenTelegram()
                                }
                            )
                        }
                        .padding(.horizontal, 16)
                    }

                    Spacer(minLength: 90)
                }
            }
        }
        .onAppear {
            currentTimeStr = DataNormalizer.formatGMT7Time(Date())
        }
    }
}

// MARK: - Flagship Portal Card
private struct HubPortalCard: View {
    let categoryTag: String
    let statusBadge: String
    let statusColor: Color
    let title: String
    let subtitle: String
    let highlights: [String]
    let ctaText: String
    let gradientColors: [Color]
    let accentColor: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 12) {
                // Top Row: Tag & Status Pill
                HStack {
                    Text(categoryTag)
                        .font(.system(size: 10, weight: .black, design: .rounded))
                        .tracking(1.1)
                        .foregroundColor(accentColor)

                    Spacer()

                    HStack(spacing: 5) {
                        Circle()
                            .fill(statusColor)
                            .frame(width: 6, height: 6)
                        Text(statusBadge)
                            .font(.system(size: 9.5, weight: .heavy, design: .rounded))
                            .tracking(0.5)
                            .foregroundColor(.white)
                    }
                    .padding(.horizontal, 9)
                    .padding(.vertical, 4)
                    .background(statusColor.opacity(0.24))
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(statusColor.opacity(0.5), lineWidth: 0.8)
                    )
                    .cornerRadius(6)
                }

                // Title & Description
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 21, weight: .black, design: .default))
                        .foregroundColor(.white)

                    Text(subtitle)
                        .font(.system(size: 12.5, weight: .regular))
                        .foregroundColor(KLTheme.textSecondary)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                }

                // Provider / Feature Chips
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(highlights, id: \.self) { chip in
                            Text(chip)
                                .font(.system(size: 9.5, weight: .bold, design: .rounded))
                                .foregroundColor(.white.opacity(0.92))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.white.opacity(0.08))
                                .cornerRadius(5)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 5)
                                        .stroke(Color.white.opacity(0.12), lineWidth: 0.6)
                                )
                        }
                    }
                }
                .disabled(true)

                Divider()
                    .background(Color.white.opacity(0.10))

                // Bottom Action Row
                HStack {
                    Text(ctaText)
                        .font(.system(size: 11.5, weight: .heavy, design: .rounded))
                        .tracking(0.6)
                        .foregroundColor(accentColor)

                    Spacer()

                    Text("CHẠM ĐỂ MỞ")
                        .font(.system(size: 9.5, weight: .bold, design: .monospaced))
                        .foregroundColor(KLTheme.textMuted)
                }
            }
            .padding(16)
            .background(
                LinearGradient(
                    colors: gradientColors,
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .cornerRadius(18)
            .overlay(
                RoundedRectangle(cornerRadius: 18)
                    .stroke(
                        LinearGradient(
                            colors: [accentColor.opacity(0.55), KLTheme.borderSubtle],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1.2
                    )
            )
        }
        .buttonStyle(KLScaleButtonStyle(scaleAmount: 0.975))
    }
}

// MARK: - Bento Utility Tile
private struct HubUtilityTile: View {
    let badge: String
    let badgeColor: Color
    let title: String
    let subtitle: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(badge)
                        .font(.system(size: 9.5, weight: .black, design: .rounded))
                        .tracking(0.5)
                        .foregroundColor(badgeColor)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 3.5)
                        .background(badgeColor.opacity(0.15))
                        .cornerRadius(5)

                    Spacer()
                }

                Text(title)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(.white)
                    .lineLimit(1)

                Text(subtitle)
                    .font(.system(size: 11.5, weight: .regular))
                    .foregroundColor(KLTheme.textMuted)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                    .frame(height: 30, alignment: .topLeading)
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(KLTheme.surfaceCard)
            .cornerRadius(14)
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(KLTheme.borderSubtle, lineWidth: 0.8)
            )
        }
        .buttonStyle(KLScaleButtonStyle())
    }
}
