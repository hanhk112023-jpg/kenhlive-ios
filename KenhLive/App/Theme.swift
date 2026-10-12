import SwiftUI

enum KLTheme {
    // Pure Dark Cinema & Editorial Colors
    static let bgDeep = Color(red: 0.027, green: 0.031, blue: 0.055)       // #07080E
    static let bgElevated = Color(red: 0.055, green: 0.067, blue: 0.106)   // #0E111B
    static let surfaceCard = Color(red: 0.075, green: 0.090, blue: 0.141)  // #131724
    static let surfaceGlass = Color.white.opacity(0.06)
    static let borderSubtle = Color.white.opacity(0.09)
    static let borderActive = Color(red: 1.0, green: 0.396, blue: 0.0)     // #FF6500

    static let brandOrange = Color(red: 1.0, green: 0.396, blue: 0.0)      // #FF6500
    static let liveRed = Color(red: 0.937, green: 0.267, blue: 0.267)      // #EF4444
    static let imdbGold = Color(red: 0.984, green: 0.749, blue: 0.141)     // #FBBF24
    static let accentCyan = Color(red: 0.220, green: 0.741, blue: 0.973)   // #38BDF8

    static let textPrimary = Color.white
    static let textSecondary = Color(red: 0.64, green: 0.68, blue: 0.76)   // #A3AED0
    static let textMuted = Color(red: 0.42, green: 0.46, blue: 0.55)       // #6B758C
}

// MARK: - Minimalist Typography-First Pill Badge (No Icons)
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

// MARK: - Editorial Section Header (Typography-Driven, Zero Icons)
struct KLSectionHeader: View {
    let title: String
    var subtitle: String? = nil
    var trailingText: String? = nil

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 10) {
            Rectangle()
                .fill(KLTheme.brandOrange)
                .frame(width: 3, height: 15)
                .cornerRadius(1.5)

            VStack(alignment: .leading, spacing: 2) {
                Text(title.uppercased())
                    .font(.system(size: 13, weight: .heavy, design: .default))
                    .tracking(0.8)
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
                    .font(.system(size: 11, weight: .semibold, design: .monospaced))
                    .foregroundColor(KLTheme.textSecondary)
            }
        }
        .padding(.horizontal, 16)
    }
}

// MARK: - Filter Pill Strip (Minimalist Text-Only Pills)
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
                        withAnimation(.easeOut(duration: 0.18)) {
                            selection = item.id
                        }
                    } label: {
                        Text(item.title)
                            .font(.system(size: 12.5, weight: isSelected ? .bold : .medium))
                            .tracking(0.2)
                            .foregroundColor(isSelected ? .white : KLTheme.textSecondary)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 7)
                            .background(
                                RoundedRectangle(cornerRadius: 18, style: .continuous)
                                    .fill(isSelected ? KLTheme.brandOrange : KLTheme.surfaceCard)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 18, style: .continuous)
                                    .stroke(isSelected ? KLTheme.brandOrange : KLTheme.borderSubtle, lineWidth: 1)
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 16)
        }
    }
}
