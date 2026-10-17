import SwiftUI
import UIKit

// MARK: - KenhLive Luxury Neo-Dark Cinema Design System
enum KLTheme {
    // Pure Dark OLED Cinema Colors
    static let bgDeep = Color(red: 0.024, green: 0.027, blue: 0.043)       // #06070B Pure OLED
    static let bgElevated = Color(red: 0.047, green: 0.055, blue: 0.086)   // #0C0E16
    static let surfaceCard = Color(red: 0.071, green: 0.082, blue: 0.125)  // #121520
    static let surfaceCardSecondary = Color(red: 0.098, green: 0.114, blue: 0.169) // #191D2B
    static let surfaceGlass = Color.white.opacity(0.06)
    static let surfaceGlassStrong = Color.white.opacity(0.12)
    static let borderSubtle = Color.white.opacity(0.08)
    static let borderMedium = Color.white.opacity(0.15)
    static let borderActive = Color(red: 1.0, green: 0.396, blue: 0.0)     // #FF6500

    // Brand & Functional Accents
    static let brandOrange = Color(red: 1.0, green: 0.396, blue: 0.0)      // #FF6500 Neon Orange
    static let fptOrange = Color(red: 1.0, green: 0.616, blue: 0.361)       // #FF9D5C FPT Tangerine
    static let fptNeonGreen = Color(red: 0.145, green: 1.0, blue: 0.486)    // #25FF7C FPT Neon Status
    static let brandOrangeGradient = LinearGradient(
        colors: [Color(red: 1.0, green: 0.42, blue: 0.0), Color(red: 1.0, green: 0.22, blue: 0.0)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
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

    // Typography Colors
    static let textPrimary = Color.white
    static let textSecondary = Color(red: 0.70, green: 0.74, blue: 0.82)   // #B3BCD1
    static let textMuted = Color(red: 0.46, green: 0.50, blue: 0.59)       // #758096
}

// MARK: - Native Haptics Feedback Engine
enum KLHaptics {
    static func light() {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.prepare()
        generator.impactOccurred()
    }

    static func medium() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.prepare()
        generator.impactOccurred()
    }

    static func heavy() {
        let generator = UIImpactFeedbackGenerator(style: .heavy)
        generator.prepare()
        generator.impactOccurred()
    }

    static func selection() {
        let generator = UISelectionFeedbackGenerator()
        generator.prepare()
        generator.selectionChanged()
    }
}

// MARK: - Fluid Press Scale Button Style
struct KLScaleButtonStyle: ButtonStyle {
    var scaleAmount: CGFloat = 0.96

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? scaleAmount : 1.0)
            .opacity(configuration.isPressed ? 0.90 : 1.0)
            .animation(.spring(response: 0.22, dampingFraction: 0.75), value: configuration.isPressed)
    }
}

// MARK: - Glass Card Modifier
struct KLGlassCardModifier: ViewModifier {
    var cornerRadius: CGFloat = 14
    var borderColor: Color = KLTheme.borderSubtle
    var borderWidth: CGFloat = 0.8
    var backgroundColor: Color = KLTheme.surfaceCard

    func body(content: Content) -> some View {
        content
            .background(backgroundColor)
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(borderColor, lineWidth: borderWidth)
            )
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
    }
}

extension View {
    func klGlassCard(
        cornerRadius: CGFloat = 14,
        borderColor: Color = KLTheme.borderSubtle,
        borderWidth: CGFloat = 0.8,
        backgroundColor: Color = KLTheme.surfaceCard
    ) -> some View {
        self.modifier(KLGlassCardModifier(
            cornerRadius: cornerRadius,
            borderColor: borderColor,
            borderWidth: borderWidth,
            backgroundColor: backgroundColor
        ))
    }
}

// MARK: - Animated Live Pulsing Badge
struct KLLivePulseBadge: View {
    var text: String = "TRỰC TIẾP"
    var color: Color = KLTheme.liveRed
    @State private var isPulsing: Bool = false

    var body: some View {
        HStack(spacing: 5) {
            ZStack {
                Circle()
                    .fill(color.opacity(isPulsing ? 0.3 : 0.8))
                    .frame(width: 9, height: 9)
                    .scaleEffect(isPulsing ? 1.4 : 0.9)

                Circle()
                    .fill(color)
                    .frame(width: 5.5, height: 5.5)
            }
            .animation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true), value: isPulsing)

            Text(text)
                .font(.system(size: 9.5, weight: .black, design: .rounded))
                .tracking(0.6)
                .foregroundColor(.white)
        }
        .padding(.horizontal, 7)
        .padding(.vertical, 3.5)
        .background(color.opacity(0.18))
        .overlay(
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .stroke(color.opacity(0.35), lineWidth: 0.8)
        )
        .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
        .onAppear {
            isPulsing = true
        }
    }
}

// MARK: - Minimalist Pill Badge
struct KLPillBadge: View {
    let text: String
    var fg: Color = .white
    var bg: Color = Color.white.opacity(0.10)
    var border: Color = Color.white.opacity(0.12)

    var body: some View {
        Text(text.uppercased())
            .font(.system(size: 9.5, weight: .bold, design: .rounded))
            .tracking(0.5)
            .foregroundColor(fg)
            .padding(.horizontal, 7)
            .padding(.vertical, 3.5)
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
    var trailingAction: (() -> Void)? = nil
    var accentColor: Color = KLTheme.brandOrange

    var body: some View {
        HStack(alignment: .center, spacing: 10) {
            RoundedRectangle(cornerRadius: 2)
                .fill(accentColor)
                .frame(width: 3.5, height: 16)

            VStack(alignment: .leading, spacing: 2) {
                Text(title.uppercased())
                    .font(.system(size: 13, weight: .heavy, design: .rounded))
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
                if let action = trailingAction {
                    Button(action: {
                        KLHaptics.light()
                        action()
                    }) {
                        HStack(spacing: 3) {
                            Text(trailing)
                                .font(.system(size: 10.5, weight: .bold, design: .rounded))
                            Image(systemName: "chevron.right")
                                .font(.system(size: 8.5, weight: .bold))
                        }
                        .foregroundColor(accentColor)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(accentColor.opacity(0.12))
                        .cornerRadius(6)
                    }
                    .buttonStyle(KLScaleButtonStyle())
                } else {
                    Text(trailing)
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundColor(KLTheme.textSecondary)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 3.5)
                        .background(KLTheme.surfaceCardSecondary)
                        .cornerRadius(6)
                }
            }
        }
        .padding(.horizontal, 16)
    }
}

// MARK: - Ambient Radiant Header Glow (FPT Play / Cinema Aesthetic)
struct KLAmbientHeaderGlow: View {
    var color: Color = KLTheme.fptOrange
    var height: CGFloat = 280
    var opacity: Double = 0.22

    var body: some View {
        RadialGradient(
            colors: [color.opacity(opacity), color.opacity(0.0)],
            center: .top,
            startRadius: 0,
            endRadius: height
        )
        .frame(height: height)
        .allowsHitTesting(false)
        .ignoresSafeArea(edges: .top)
    }
}

// MARK: - Sports Match Action Badge
enum KLMatchActionType {
    case goal, yellowCard, redCard, varDecision
}

struct KLMatchActionBadge: View {
    let type: KLMatchActionType
    var size: CGFloat = 18

    var body: some View {
        Group {
            switch type {
            case .goal:
                Image("fp_action_ban_thang")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            case .yellowCard:
                Image("fp_action_the_vang")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            case .redCard:
                Image("fp_action_the_do")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            case .varDecision:
                Image("fp_action_var")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            }
        }
        .frame(width: size, height: size)
    }
}

// MARK: - Filter Pill Strip
struct KLFilterItem<T: Hashable>: Identifiable, Hashable {
    let id: T
    let title: String
    var badge: String? = nil
    var icon: String? = nil
}

struct KLFilterStrip<T: Hashable>: View {
    let items: [KLFilterItem<T>]
    @Binding var selection: T
    var onSelect: ((T) -> Void)? = nil

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
                        onSelect?(item.id)
                    } label: {
                        HStack(spacing: 5) {
                            if let icon = item.icon {
                                Image(systemName: icon)
                                    .font(.system(size: 10, weight: .bold))
                            }

                            Text(item.title)
                                .font(.system(size: 12, weight: isSelected ? .bold : .medium))
                                .tracking(0.2)

                            if let badge = item.badge {
                                Text(badge)
                                    .font(.system(size: 9.5, weight: .black, design: .monospaced))
                                    .padding(.horizontal, 5)
                                    .padding(.vertical, 1.5)
                                    .background(isSelected ? Color.white.opacity(0.25) : KLTheme.surfaceGlassStrong)
                                    .clipShape(Capsule())
                            }
                        }
                        .foregroundColor(isSelected ? .white : KLTheme.textSecondary)
                        .padding(.horizontal, 13)
                        .padding(.vertical, 7)
                        .background(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(isSelected ? KLTheme.brandOrange : KLTheme.surfaceCard)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
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

// MARK: - Modern Glass Search Input Field
struct KLGlassSearchBar: View {
    @Binding var text: String
    var placeholder: String = "Tìm kiếm..."
    var onSubmit: (() -> Void)? = nil

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(KLTheme.textMuted)

            TextField(placeholder, text: $text)
                .font(.system(size: 13.5, weight: .medium))
                .foregroundColor(.white)
                .autocapitalization(.none)
                .disableAutocorrection(true)
                .onSubmit {
                    onSubmit?()
                }

            if !text.isEmpty {
                Button {
                    KLHaptics.light()
                    text = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 14))
                        .foregroundColor(KLTheme.textMuted)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 9)
        .background(KLTheme.surfaceCard)
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(KLTheme.borderSubtle, lineWidth: 0.8)
        )
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }
}


// MARK: - Modern Skeleton Loading Placeholder
struct KLSkeletonView: View {
    var height: CGFloat = 80
    var cornerRadius: CGFloat = 12

    var body: some View {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            .fill(Color.white.opacity(0.06))
            .frame(height: height)
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(KLTheme.borderSubtle, lineWidth: 0.8)
            )
    }
}

// MARK: - High-Performance In-Memory RAM Image Cache & Instant Loader
final class KLImageCache {
    static let shared = KLImageCache()
    private let cache = NSCache<NSString, UIImage>()

    private init() {
        cache.countLimit = 350
        cache.totalCostLimit = 150 * 1024 * 1024 // 150 MB RAM
    }

    func get(for urlString: String) -> UIImage? {
        cache.object(forKey: urlString as NSString)
    }

    func set(_ image: UIImage, for urlString: String) {
        let cost = Int(image.size.width * image.size.height * 4)
        cache.setObject(image, forKey: urlString as NSString, cost: cost)
    }
}

final class KLImageLoader: ObservableObject {
    @Published var image: UIImage? = nil
    @Published var isLoading: Bool = false
    private var currentUrl: String = ""
    private var downloadTask: Task<Void, Never>? = nil

    func load(urlString: String) {
        guard !urlString.isEmpty else { return }
        if let cached = KLImageCache.shared.get(for: urlString) {
            self.image = cached
            self.isLoading = false
            return
        }

        guard urlString != currentUrl else { return }
        currentUrl = urlString
        isLoading = true

        downloadTask?.cancel()
        downloadTask = Task(priority: .userInitiated) {
            guard let url = URL(string: urlString) else {
                await MainActor.run { self.isLoading = false }
                return
            }

            var req = URLRequest(url: url)
            req.timeoutInterval = 12
            req.cachePolicy = .returnCacheDataElseLoad

            do {
                let (data, _) = try await URLSession.shared.data(for: req)
                guard !Task.isCancelled, let downloaded = UIImage(data: data) else {
                    await MainActor.run { self.isLoading = false }
                    return
                }
                let displayImage = await downloaded.byPreparingForDisplay() ?? downloaded
                KLImageCache.shared.set(displayImage, for: urlString)
                await MainActor.run {
                    self.image = displayImage
                    self.isLoading = false
                }
            } catch {
                if !Task.isCancelled {
                    await MainActor.run { self.isLoading = false }
                }
            }
        }
    }

    func cancel() {
        downloadTask?.cancel()
    }
}

struct KLAsyncImage: View {
    let url: String
    var contentMode: ContentMode = .fill

    @StateObject private var loader = KLImageLoader()

    var body: some View {
        ZStack {
            if let img = loader.image {
                Image(uiImage: img)
                    .resizable()
                    .aspectRatio(contentMode: contentMode)
            } else if loader.isLoading {
                ZStack {
                    Color(red: 0.14, green: 0.14, blue: 0.18)
                    ProgressView().tint(KLTheme.brandOrange).scaleEffect(0.7)
                }
            } else {
                Color(red: 0.14, green: 0.14, blue: 0.18)
            }
        }
        .onAppear {
            loader.load(urlString: url)
        }
        .onChange(of: url) { newUrl in
            loader.load(urlString: newUrl)
        }
        .onDisappear {
            loader.cancel()
        }
    }
}

// MARK: - Cinema Widescreen Continue Watching Film Card
struct KLWatchHistoryCard: View {
    let item: WatchProgress
    let onPlay: () -> Void
    var onDelete: (() -> Void)? = nil

    var body: some View {
        Button(action: onPlay) {
            VStack(alignment: .leading, spacing: 8) {
                // 1. Poster Art (16:9 Cinema Widescreen)
                ZStack(alignment: .bottom) {
                    KLAsyncImage(
                        url: item.posterUrl,
                        contentMode: .fill
                    )
                    .frame(width: 175, height: 108)
                    .clipped()

                    // Subtle Dark Gradient Overlay
                    LinearGradient(
                        colors: [.clear, Color.black.opacity(0.35), Color.black.opacity(0.88)],
                        startPoint: .top,
                        endPoint: .bottom
                    )

                    // Centered Frosted Play Icon
                    Circle()
                        .fill(Color.black.opacity(0.55))
                        .frame(width: 36, height: 36)
                        .overlay(
                            Circle().stroke(Color.white.opacity(0.35), lineWidth: 0.8)
                        )
                        .overlay(
                            Image(systemName: "play.fill")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(.white)
                                .offset(x: 1.5)
                        )
                        .shadow(color: Color.black.opacity(0.6), radius: 6, x: 0, y: 2)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)

                    // Top Bar (Badge Episode on Left, Delete 'xmark' on Right if provided)
                    VStack {
                        HStack {
                            Text(item.episodeName.isEmpty ? "Đang xem" : item.episodeName)
                                .font(.system(size: 9.5, weight: .bold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 3)
                                .background(Color.black.opacity(0.70))
                                .clipShape(Capsule())

                            Spacer()

                            if let onDelete = onDelete {
                                Button(action: onDelete) {
                                    Image(systemName: "xmark")
                                        .font(.system(size: 9, weight: .bold))
                                        .foregroundColor(.white.opacity(0.85))
                                        .frame(width: 22, height: 22)
                                        .background(Color.black.opacity(0.75))
                                        .clipShape(Circle())
                                }
                                .buttonStyle(.plain)
                            } else {
                                Text("\(Int(item.progressPercent * 100))%")
                                    .font(.system(size: 9.5, weight: .bold, design: .monospaced))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 3)
                                    .background(Color(red: 0.85, green: 0.22, blue: 0.28).opacity(0.9))
                                    .clipShape(Capsule())
                            }
                        }
                        Spacer()
                    }
                    .padding(6)

                    // Bottom Crimson Progress Bar
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Rectangle()
                                .fill(Color.white.opacity(0.25))
                                .frame(height: 3.5)

                            Rectangle()
                                .fill(
                                    LinearGradient(
                                        colors: [Color(red: 0.85, green: 0.22, blue: 0.28), Color(red: 1.0, green: 0.38, blue: 0.44)],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(width: geo.size.width * max(0.06, min(1.0, item.progressPercent)), height: 3.5)
                        }
                    }
                    .frame(height: 3.5)
                }
                .frame(width: 175, height: 108)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.white.opacity(0.12), lineWidth: 0.8)
                )

                // 2. Movie Title & Subtitle Info
                VStack(alignment: .leading, spacing: 3) {
                    Text(item.filmName)
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.white)
                        .lineLimit(1)

                    HStack(spacing: 4) {
                        Image(systemName: "clock.arrow.circlepath")
                            .font(.system(size: 10))
                        Text(item.episodeName.isEmpty ? "Xem tiếp" : item.episodeName)
                            .font(.system(size: 11, weight: .medium))
                    }
                    .foregroundColor(KLTheme.textMuted)
                    .lineLimit(1)
                }
                .frame(width: 175, alignment: .leading)
            }
        }
        .buttonStyle(.plain)
    }
}
