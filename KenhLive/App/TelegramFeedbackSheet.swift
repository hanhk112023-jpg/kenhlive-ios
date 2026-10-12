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
                                .frame(width: 64, height: 64)

                            Text("TG")
                                .font(.system(size: 24, weight: .black, design: .rounded))
                                .foregroundColor(.white)
                        }
                        .padding(.top, 4)

                        Text("THÔNG BÁO BẢN CẬP NHẬT")
                            .font(.system(size: 11, weight: .black, design: .rounded))
                            .tracking(1.8)
                            .foregroundColor(KLTheme.brandOrange)

                        Text("KenhLive v1.4.3 (Rạp Phim HLS 4K)")
                            .font(.system(size: 22, weight: .heavy))
                            .foregroundColor(.white)

                        Text("Kênh tiếp nhận báo lỗi, yêu cầu thêm giải đấu & hỗ trợ kỹ thuật trực tiếp từ đội ngũ phát triển.")
                            .font(.system(size: 13, weight: .regular))
                            .foregroundColor(KLTheme.textSecondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 16)
                    }

                    // 3. What's New Feature List
                    VStack(alignment: .leading, spacing: 14) {
                        Text("ĐIỂM NÂNG CẤP NỔI BẬT")
                            .font(.system(size: 11, weight: .black, design: .rounded))
                            .tracking(1.2)
                            .foregroundColor(KLTheme.textMuted)

                        FeatureItemRow(
                            badge: "THỂ THAO",
                            badgeColor: KLTheme.socoEmerald,
                            title: "Gà Vàng 33 & Giờ Vàng TV",
                            desc: "Bổ sung API chính thức từ Gà Vàng 33 và máy chủ VCDN Cloud Giờ Vàng TV, độc lập 100% với Socolive & ColaTV."
                        )

                        FeatureItemRow(
                            badge: "NETFLIX",
                            badgeColor: KLTheme.netflixRed,
                            title: "Kho Phim Chuẩn Netflix Cinema",
                            desc: "Billboard Hero 360pt, nhãn 98% Phù Hợp, Top 10 thịnh hành, tỷ lệ poster 2:3 chuẩn rạp và thanh xem dở đỏ rực."
                        )

                        FeatureItemRow(
                            badge: "TRANG CHỦ",
                            badgeColor: KLTheme.brandOrange,
                            title: "Cổng Chọn Trung Tâm (Home Hub)",
                            desc: "Thiết kế đại sảnh chọn 3 phân khu: Thể Thao, Kênh TV, Phim Truyện cùng cụm tiện ích đa màn và lịch thi đấu."
                        )

                        FeatureItemRow(
                            badge: "HIỆU NĂNG",
                            badgeColor: KLTheme.accentCyan,
                            title: "Siêu Mượt & Chống Lỗi SSL",
                            desc: "Lọc bỏ hoàn toàn các luồng phát lỗi cert SSL, tối ưu Haptics cảm ứng xúc giác trên iOS."
                        )
                    }
                    .padding(16)
                    .background(KLTheme.surfaceCard)
                    .cornerRadius(16)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(KLTheme.borderSubtle, lineWidth: 0.8)
                    )
                    .padding(.horizontal, 16)

                    // 4. Native QR Code Card
                    VStack(spacing: 12) {
                        if let qrImg = generateQRCode(from: telegramUrlString) {
                            Image(uiImage: qrImg)
                                .interpolation(.none)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 140, height: 140)
                                .padding(12)
                                .background(Color.white)
                                .cornerRadius(14)
                        }

                        VStack(spacing: 4) {
                            Text("Quét mã QR hoặc truy cập Telegram")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(.white)

                            Text(telegramHandle)
                                .font(.system(size: 15, weight: .black, design: .monospaced))
                                .foregroundColor(KLTheme.telegramBlue)
                        }
                    }
                    .padding(16)
                    .frame(maxWidth: .infinity)
                    .background(KLTheme.surfaceCard)
                    .cornerRadius(16)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(KLTheme.borderSubtle, lineWidth: 0.8)
                    )
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
                                Text("MỞ TELEGRAM @T990512S")
                                    .font(.system(size: 13.5, weight: .bold))
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
                                    .background(KLTheme.surfaceCard)
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
            // Scale up the CIImage so it is sharp
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
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white)

                Text(desc)
                    .font(.system(size: 12, weight: .regular))
                    .foregroundColor(KLTheme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}
