import SwiftUI
import UIKit
import CoreImage
import CoreImage.CIFilterBuiltins

struct TelegramFeedbackSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var copiedNotice: Bool = false

    private let telegramUrlString = "https://t.me/T990512S"
    private let telegramHandle = "@T990512S"

    var body: some View {
        ZStack {
            KLTheme.bgDeep.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    // 1. Drag Handle
                    Capsule()
                        .fill(Color.white.opacity(0.2))
                        .frame(width: 40, height: 4.5)
                        .padding(.top, 10)

                    // 2. Header Brand Card
                    VStack(spacing: 8) {
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [KLTheme.telegramBlue, Color(red: 0.1, green: 0.45, blue: 0.85)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 60, height: 60)

                            Text("TG")
                                .font(.system(size: 22, weight: .black, design: .rounded))
                                .foregroundColor(.white)
                        }
                        .padding(.top, 4)

                        HStack(spacing: 5) {
                            Text("BẢN PHÁT HÀNH CHÍNH THỨC")
                                .font(.system(size: 10, weight: .black, design: .rounded))
                                .tracking(1.6)
                                .foregroundColor(KLTheme.brandOrange)

                            Circle()
                                .fill(KLTheme.brandOrange)
                                .frame(width: 5, height: 5)
                        }

                        Text("KenhLive v1.6.0 (Build 132)")
                            .font(.system(size: 22, weight: .heavy, design: .rounded))
                            .foregroundColor(.white)

                        Text("Liquid Glass Cinema, Tìm Kiếm Toàn Năng, Scoreboard Real-Time & Trình Phát AVPlayer Metal 100% Crash-Proof.")
                            .font(.system(size: 12.5, weight: .regular))
                            .foregroundColor(KLTheme.textSecondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 16)
                    }

                    // 3. What's New Feature List
                    VStack(alignment: .leading, spacing: 14) {
                        Text("ĐIỂM NÂNG CẤP NỔI BẬT V1.6.0")
                            .font(.system(size: 10.5, weight: .black, design: .rounded))
                            .tracking(1.2)
                            .foregroundColor(KLTheme.brandOrange)

                        FeatureItemRow(
                            badge: "CINEMA UI",
                            badgeColor: KLTheme.brandOrange,
                            title: "Liquid Glass Design HIG",
                            desc: "Nền OLED Deep Black #06070B, hiệu ứng kính mờ đa tầng Liquid Glass, haptic feedback và thanh tìm kiếm đồng bộ."
                        )

                        FeatureItemRow(
                            badge: "THỂ THAO",
                            badgeColor: KLTheme.liveRed,
                            title: "4 Đài Độc Lập & Real-Time Scores",
                            desc: "Socolive, ColaTV, Gà Vàng 33 & Giờ Vàng TV. Logo CLB ESPN 500x500 CDN, tỉ số tự động và EPG 7 ngày."
                        )

                        FeatureItemRow(
                            badge: "TÌM KIẾM",
                            badgeColor: KLTheme.accentCyan,
                            title: "Universal Cross-Content Search",
                            desc: "Tìm kiếm đồng thời cả Trận Đấu Trực Tiếp, Kênh TV và Kho Phim VOD trong 1 thanh tìm kiếm duy nhất."
                        )

                        FeatureItemRow(
                            badge: "TRÌNH PHÁT",
                            badgeColor: KLTheme.netflixRed,
                            title: "AVPlayerViewController Metal 100%",
                            desc: "Loại bỏ hoàn toàn lỗi CALayer cast crash, safe seek timeline, cử chỉ tua ±10s, pinch zoom và Picture-in-Picture."
                        )
                    }
                    .padding(16)
                    .klGlassCard(cornerRadius: 16)
                    .padding(.horizontal, 16)

                    // 4. Native QR Code Card
                    VStack(spacing: 12) {
                        if let qrImg = generateQRCode(from: telegramUrlString) {
                            Image(uiImage: qrImg)
                                .interpolation(.none)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 130, height: 130)
                                .padding(10)
                                .background(Color.white)
                                .cornerRadius(12)
                        }

                        VStack(spacing: 3) {
                            Text("Quét mã QR hoặc truy cập nhóm hỗ trợ")
                                .font(.system(size: 12.5, weight: .semibold))
                                .foregroundColor(.white)

                            Text(telegramHandle)
                                .font(.system(size: 14.5, weight: .black, design: .monospaced))
                                .foregroundColor(KLTheme.telegramBlue)
                        }
                    }
                    .padding(16)
                    .frame(maxWidth: .infinity)
                    .klGlassCard(cornerRadius: 16)
                    .padding(.horizontal, 16)

                    // 5. Actions
                    VStack(spacing: 10) {
                        Button {
                            KLHaptics.medium()
                            if let url = URL(string: "tg://resolve?domain=T990512S"), UIApplication.shared.canOpenURL(url) {
                                UIApplication.shared.open(url)
                            } else if let url = URL(string: telegramUrlString) {
                                UIApplication.shared.open(url)
                            }
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: "paperplane.fill")
                                    .font(.system(size: 13, weight: .bold))
                                Text("MỞ TELEGRAM @T990512S")
                                    .font(.system(size: 13, weight: .bold))
                                    .tracking(0.5)
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(KLTheme.telegramBlue)
                            .cornerRadius(12)
                        }
                        .buttonStyle(KLScaleButtonStyle())

                        HStack(spacing: 10) {
                            Button {
                                KLHaptics.light()
                                UIPasteboard.general.string = telegramHandle
                                copiedNotice = true
                                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                    copiedNotice = false
                                }
                            } label: {
                                Text(copiedNotice ? "ĐÃ SAO CHÉP ID ✓" : "SAO CHÉP @T990512S")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(copiedNotice ? .green : KLTheme.textSecondary)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                                    .background(Color.white.opacity(0.06))
                                    .cornerRadius(10)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 10)
                                            .stroke(KLTheme.borderSubtle, lineWidth: 0.8)
                                    )
                            }
                            .buttonStyle(KLScaleButtonStyle())

                            Button {
                                KLHaptics.light()
                                dismiss()
                            } label: {
                                Text("ĐÓNG")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                                    .background(Color.white.opacity(0.12))
                                    .cornerRadius(10)
                            }
                            .buttonStyle(KLScaleButtonStyle())
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 24)
                }
            }
        }
    }

    private func generateQRCode(from string: String) -> UIImage? {
        let context = CIContext()
        let filter = CIFilter.qrCodeGenerator()
        filter.message = Data(string.utf8)

        if let outputImage = filter.outputImage {
            let transform = CGAffineTransform(scaleX: 8, y: 8)
            let scaledImage = outputImage.transformed(by: transform)
            if let cgImage = context.createCGImage(scaledImage, from: scaledImage.extent) {
                return UIImage(cgImage: cgImage)
            }
        }
        return nil
    }
}

private struct FeatureItemRow: View {
    let badge: String
    let badgeColor: Color
    let title: String
    let desc: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            KLPillBadge(text: badge, fg: .white, bg: badgeColor.opacity(0.2), border: badgeColor.opacity(0.4))
                .padding(.top, 1)

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 13.5, weight: .bold))
                    .foregroundColor(.white)

                Text(desc)
                    .font(.system(size: 11.5, weight: .regular))
                    .foregroundColor(KLTheme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}
