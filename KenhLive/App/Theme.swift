import SwiftUI
import UIKit

enum KLTheme {
    // Pure Dark OLED Cinema & Editorial Colors
    static let bgDeep = Color(red: 0.027, green: 0.031, blue: 0.055)       // #07080E
    static let bgElevated = Color(red: 0.055, green: 0.067, blue: 0.106)   // #0E111B
    static let surfaceCard = Color(red: 0.075, green: 0.090, blue: 0.141)  // #131724
    static let surfaceGlass = Color.white.opacity(0.08)
    static let borderSubtle = Color.white.opacity(0.10)
    static let borderActive = Color(red: 1.0, green: 0.396, blue: 0.0)     // #FF6500

    // Brand & Functional Accents
    static let brandOrange = Color(red: 1.0, green: 0.396, blue: 0.0)      // #FF6500
    static let liveRed = Color(red: 0.937, green: 0.267, blue: 0.267)      // #EF4444
    static let netflixRed = Color(red: 0.898, green: 0.035, blue: 0.078)   // #E50914
    static let netflixGreen = Color(red: 0.275, green: 0.827, blue: 0.412) // #46D369
    static let imdbGold = Color(red: 0.984, green: 0.749, blue: 0.141)     // #FBBF24
    static let accentCyan = Color(red: 0.220, green: 0.741, blue: 0.973)   // #38BDF8
    static let telegramBlue = Color(red: 0.165, green: 0.671, blue: 0.933) // #2AABEE

    // Provider Colors
    static let socoEmerald = Color(red: 0.063, green: 0.725, blue: 0.506)  // #10B981
    static let gavangAmber = Color(red: 0.961, green: 0.620, blue: 0.043)  // #F59E0B
    static let colaSky = Color(red: 0.055, green: 0.647, blue: 0.914)      // #0EA5E9
    static let giovangPurple = Color(red: 0.659, green: 0.333, blue: 0.969)// #A855F7

    static let textPrimary = Color.white
    static let textSecondary = Color(red: 0.68, green: 0.72, blue: 0.80)   // #ADB8CC
    static let textMuted = Color(red: 0.45, green: 0.49, blue: 0.58)       // #737D94
}

// MARK: - Native Haptics Feedback Engine
enum KLHaptics {
    static func light() {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }

    static func medium() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
    }

    static func selection() {
        let generator = UISelectionFeedbackGenerator()
        generator.selectionChanged()
    }
}

// MARK: - Fluid Press Scale Button Style
struct KLScaleButtonStyle: ButtonStyle {
    var scaleAmount: CGFloat = 0.96

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? scaleAmount : 1.0)
            .opacity(configuration.isPressed ? 0.92 : 1.0)
            .animation(.spring(response: 0.24, dampingFraction: 0.75), value: configuration.isPressed)
    }
}

// MARK: - Minimalist Typography-First Pill Badge
struct KLPillBadge: View {
    let text: String
    var fg: Color = .white
    var bg: Color = Color.white.opacity(0.10)
    var border: Color = Color.white.opacity(0.12)

    var body: some View {
        Text(text.uppercased())
            .font(.system(size: 10, weight: .bold, design: .rounded))
            .tracking(0.6)
            .foregroundColor(fg)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(bg)
            .overlay(
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .stroke(border, lineWidth: 0.8)
            )
            .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
    }
}

// MARK: - Editorial Section Header
struct KLSectionHeader: View {
    let title: String
    var subtitle: String? = nil
    var trailingText: String? = nil
    var accentColor: Color = KLTheme.brandOrange

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 10) {
            Rectangle()
                .fill(accentColor)
                .frame(width: 3.5, height: 16)
                .cornerRadius(2)

            VStack(alignment: .leading, spacing: 2) {
                Text(title.uppercased())
                    .font(.system(size: 13.5, weight: .heavy, design: .default))
                    .tracking(0.7)
                    .foregroundColor(KLTheme.textPrimary)

                if let sub = subtitle, !sub.isEmpty {
                    Text(sub)
                        .font(.system(size: 11, weight: .regular))
                        .foregroundColor(KLTheme.textMuted)
                }
            }

            Spacer()

            if let trailing = trailingText, !trailing.isEmpty {
                Text(trailing)
                    .font(.system(size: 10.5, weight: .bold, design: .monospaced))
                    .foregroundColor(KLTheme.textSecondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(KLTheme.surfaceCard)
                    .cornerRadius(6)
            }
        }
        .padding(.horizontal, 16)
    }
}

// MARK: - Filter Pill Strip
struct KLFilterItem<T: Hashable>: Identifiable, Hashable {
    let id: T
    let title: String
}

struct KLFilterStrip<T: Hashable>: View {
    let items: [KLFilterItem<T>]
    @Binding var selection: T

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(items, id: \.id) { item in
                    let isSelected = selection == item.id
                    Button {
                        KLHaptics.selection()
                        withAnimation(.spring(response: 0.28, dampingFraction: 0.8)) {
                            selection = item.id
                        }
                    } label: {
                        Text(item.title)
                            .font(.system(size: 12.5, weight: isSelected ? .bold : .medium))
                            .tracking(0.2)
                            .foregroundColor(isSelected ? .white : KLTheme.textSecondary)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 7.5)
                            .background(
                                RoundedRectangle(cornerRadius: 18, style: .continuous)
                                    .fill(isSelected ? KLTheme.brandOrange : KLTheme.surfaceCard)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 18, style: .continuous)
                                    .stroke(isSelected ? KLTheme.brandOrange : KLTheme.borderSubtle, lineWidth: 1)
                            )
                    }
                    .buttonStyle(KLScaleButtonStyle())
                }
            }
            .padding(.horizontal, 16)
        }
    }
}
