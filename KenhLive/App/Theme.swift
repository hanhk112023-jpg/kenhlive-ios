import SwiftUI
import UIKit
import ImageIO

// MARK: - Apple Design System Specification (DESIGN-apple.md)
enum KLTheme {
    // Canvas & Dark Surfaces (DESIGN-apple.md colors)
    static let bgDeep = Color(red: 0.0, green: 0.0, blue: 0.0)             // #000000 surface-black (OLED void & nav)
    static let bgElevated = Color(red: 0.145, green: 0.145, blue: 0.153)   // #252527 surface-tile-3
    static let surfaceCard = Color(red: 0.153, green: 0.153, blue: 0.161)  // #272729 surface-tile-1
    static let surfaceCardSecondary = Color(red: 0.165, green: 0.165, blue: 0.173) // #2a2a2c surface-tile-2
    static let surfaceGlass = Color.white.opacity(0.06)
    static let surfaceGlassStrong = Color.white.opacity(0.12)
    static let borderSubtle = Color.white.opacity(0.08)                     // 1px hairline border
    static let borderMedium = Color.white.opacity(0.15)
    static let borderActive = Color(red: 0.0, green: 0.40, blue: 0.80)     // #0066cc Action Blue

    // Apple Brand & Accent Tokens
    static let brandOrange = Color(red: 0.0, green: 0.40, blue: 0.80)      // #0066cc Action Blue (Primary CTA)
    static let fptOrange = Color(red: 0.161, green: 0.592, blue: 1.0)       // #2997ff Sky Link Blue (for dark surfaces)
    static let fptNeonGreen = Color(red: 0.145, green: 1.0, blue: 0.486)    // #25FF7C Status Green
    static let brandOrangeGradient = LinearGradient(
        colors: [Color(red: 0.0, green: 0.40, blue: 0.80), Color(red: 0.0, green: 0.443, blue: 0.89)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    static let liveRed = Color(red: 0.937, green: 0.267, blue: 0.267)      // #EF4444 System Red for Live
    static let netflixRed = Color(red: 0.0, green: 0.40, blue: 0.80)       // Aligned to Apple Action Blue #0066cc
    static let netflixGreen = Color(red: 0.275, green: 0.827, blue: 0.412) // #46D369
    static let imdbGold = Color(red: 0.984, green: 0.749, blue: 0.141)     // #FBBF24
    static let accentCyan = Color(red: 0.161, green: 0.592, blue: 1.0)     // #2997ff Sky Link Blue
    static let telegramBlue = Color(red: 0.0, green: 0.40, blue: 0.80)     // #0066cc Action Blue

    // Provider Colors
    static let socoEmerald = Color(red: 0.063, green: 0.725, blue: 0.506)  // #10B981
    static let gavangAmber = Color(red: 0.961, green: 0.620, blue: 0.043)  // #F59E0B
    static let colaSky = Color(red: 0.161, green: 0.592, blue: 1.0)        // #2997ff Sky Link Blue
    static let giovangPurple = Color(red: 0.659, green: 0.333, blue: 0.969)// #A855F7

    // Apple Typography & Surface Colors
    static let textPrimary = Color.white                                   // body-on-dark #ffffff
    static let textSecondary = Color(red: 0.80, green: 0.80, blue: 0.80)   // body-muted #cccccc
    static let textMuted = Color(red: 0.478, green: 0.478, blue: 0.478)   // ink-muted-48 #7a7a7a
    static let appleActionBlue = Color(red: 0.0, green: 0.40, blue: 0.80)  // #0066cc Action Blue
    static let appleSkyBlue = Color(red: 0.161, green: 0.592, blue: 1.0)   // #2997ff Sky Link Blue
    static let appleParchment = Color(red: 0.961, green: 0.961, blue: 0.969) // #f5f5f7 Parchment
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

// MARK: - Fluid Press Scale Button Style (Apple transform: scale(0.95))
struct KLScaleButtonStyle: ButtonStyle {
    var scaleAmount: CGFloat = 0.95

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? scaleAmount : 1.0)
            .opacity(configuration.isPressed ? 0.90 : 1.0)
            .animation(.spring(response: 0.20, dampingFraction: 0.75), value: configuration.isPressed)
    }
}

// MARK: - Glass Card Modifier (Apple store-utility-card: rounded.lg 18px, hairline border)
struct KLGlassCardModifier: ViewModifier {
    var cornerRadius: CGFloat = 18
    var borderColor: Color = KLTheme.borderSubtle
    var borderWidth: CGFloat = 1.0
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
        cornerRadius: CGFloat = 18,
        borderColor: Color = KLTheme.borderSubtle,
        borderWidth: CGFloat = 1.0,
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

// MARK: - Editorial Section Header (Apple typography tagline / caption-strong)
struct KLSectionHeader: View {
    let title: String
    var subtitle: String? = nil
    var trailingText: String? = nil
    var trailingAction: (() -> Void)? = nil
    var accentColor: Color = KLTheme.brandOrange

    var body: some View {
        HStack(alignment: .center, spacing: 10) {
            RoundedRectangle(cornerRadius: 1.5)
                .fill(accentColor)
                .frame(width: 3.0, height: 16)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 21, weight: .semibold, design: .default))
                    .tracking(-0.28)
                    .foregroundColor(KLTheme.textPrimary)

                if let sub = subtitle, !sub.isEmpty {
                    Text(sub)
                        .font(.system(size: 14, weight: .regular, design: .default))
                        .tracking(-0.22)
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
                        HStack(spacing: 4) {
                            Text(trailing)
                                .font(.system(size: 14, weight: .regular, design: .default))
                            Image(systemName: "chevron.right")
                                .font(.system(size: 11, weight: .semibold))
                        }
                        .foregroundColor(KLTheme.fptOrange)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Color.white.opacity(0.06))
                        .clipShape(Capsule())
                    }
                    .buttonStyle(KLScaleButtonStyle())
                } else {
                    Text(trailing)
                        .font(.system(size: 12, weight: .regular, design: .default))
                        .foregroundColor(KLTheme.textSecondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(KLTheme.surfaceCardSecondary)
                        .clipShape(Capsule())
                }
            }
        }
        .padding(.horizontal, 16)
    }
}

// MARK: - Ambient Radiant Header Glow (Apple photography-first soft lighting)
struct KLAmbientHeaderGlow: View {
    var color: Color = Color.black
    var height: CGFloat = 280
    var opacity: Double = 0.0

    var body: some View {
        // Zero decorative gradients according to DESIGN-apple.md
        Color.clear
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

// MARK: - Apple Filter Pill Strip (configurator-option-chip / button-secondary-pill)
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
                        HStack(spacing: 6) {
                            if let icon = item.icon {
                                Image(systemName: icon)
                                    .font(.system(size: 11, weight: .regular))
                            }

                            Text(item.title)
                                .font(.system(size: 14, weight: isSelected ? .semibold : .regular, design: .default))
                                .tracking(-0.22)

                            if let badge = item.badge {
                                Text(badge)
                                    .font(.system(size: 11, weight: .medium, design: .default))
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(isSelected ? Color.white.opacity(0.20) : Color.white.opacity(0.08))
                                    .clipShape(Capsule())
                            }
                        }
                        .foregroundColor(isSelected ? .white : KLTheme.textSecondary)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 9)
                        .background(
                            Capsule()
                                .fill(isSelected ? KLTheme.appleActionBlue : KLTheme.surfaceCard)
                        )
                        .overlay(
                            Capsule()
                                .stroke(isSelected ? KLTheme.appleActionBlue : KLTheme.borderSubtle, lineWidth: 1)
                        )
                    }
                    .buttonStyle(KLScaleButtonStyle())
                }
            }
            .padding(.horizontal, 16)
        }
    }
}

// MARK: - Modern Apple Search Input Field (search-input: rounded.pill, 44px height)
struct KLGlassSearchBar: View {
    @Binding var text: String
    var placeholder: String = "Tìm kiếm..."
    var onSubmit: (() -> Void)? = nil

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 14, weight: .regular))
                .foregroundColor(KLTheme.textMuted)

            TextField(placeholder, text: $text)
                .font(.system(size: 15, weight: .regular, design: .default))
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
                        .font(.system(size: 15))
                        .foregroundColor(KLTheme.textMuted)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 16)
        .frame(height: 44)
        .background(KLTheme.surfaceCard)
        .overlay(
            Capsule()
                .stroke(KLTheme.borderSubtle, lineWidth: 1)
        )
        .clipShape(Capsule())
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
        cache.countLimit = 800
        cache.totalCostLimit = 250 * 1024 * 1024 // 250 MB RAM
    }

    func get(for urlString: String) -> UIImage? {
        guard !urlString.isEmpty else { return nil }
        return cache.object(forKey: urlString as NSString)
    }

    func set(_ image: UIImage, for urlString: String) {
        guard !urlString.isEmpty else { return }
        let cost = Int(image.size.width * image.size.height * 4)
        cache.setObject(image, forKey: urlString as NSString, cost: cost)
    }

    func clear() {
        cache.removeAllObjects()
    }
}

// MARK: - Persistent Disk Cache for Zero-Latency App-Wide Image Restores
final class KLDiskImageCache {
    static let shared = KLDiskImageCache()
    private let cacheDir: URL

    private init() {
        let urls = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)
        let dir = urls[0].appendingPathComponent("kl_img_cache", isDirectory: true)
        if !FileManager.default.fileExists(atPath: dir.path) {
            try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        }
        self.cacheDir = dir
    }

    private func filename(for key: String) -> String {
        let safe = key.replacingOccurrences(of: "[^a-zA-Z0-9_.-]", with: "_", options: .regularExpression)
        // Deterministic djb2 hash (persistent across app launches, unlike Swift String.hashValue)
        var hash: UInt64 = 5381
        for byte in key.utf8 {
            hash = ((hash << 5) &+ hash) &+ UInt64(byte)
        }
        let suffix = safe.count > 30 ? String(safe.suffix(30)) : safe
        return "\(hash)_\(suffix).jpg"
    }

    func get(for key: String) -> UIImage? {
        guard !key.isEmpty else { return nil }
        let file = cacheDir.appendingPathComponent(filename(for: key))
        guard FileManager.default.fileExists(atPath: file.path) else { return nil }
        guard let data = try? Data(contentsOf: file) else { return nil }
        return UIImage(data: data)
    }

    // Giới hạn trần cứng: 50MB cho bộ nhớ đệm ảnh (Tự động xoay vòng LRU)
    private let maxDiskBytes: Int64 = 50 * 1024 * 1024
    private let targetTrimBytes: Int64 = 35 * 1024 * 1024

    func set(_ data: Data, for key: String) {
        guard !key.isEmpty, !data.isEmpty else { return }
        let file = cacheDir.appendingPathComponent(filename(for: key))
        try? data.write(to: file, options: .atomic)

        // Tự động kiểm tra và xả ảnh cũ nhất chạy nền nếu vượt quá 50MB
        DispatchQueue.global(qos: .utility).async { [weak self] in
            self?.trimIfNeeded()
        }
    }

    private func trimIfNeeded() {
        guard let files = try? FileManager.default.contentsOfDirectory(
            at: cacheDir,
            includingPropertiesForKeys: [.fileSizeKey, .contentModificationDateKey]
        ) else { return }

        var items: [(url: URL, date: Date, size: Int64)] = []
        var total: Int64 = 0

        for file in files {
            guard let rv = try? file.resourceValues(forKeys: [.fileSizeKey, .contentModificationDateKey]),
                  let size = rv.fileSize,
                  let date = rv.contentModificationDate else { continue }
            let s = Int64(size)
            total += s
            items.append((url: file, date: date, size: s))
        }

        guard total > maxDiskBytes else { return }

        // Sắp xếp theo ngày cũ nhất lên đầu (LRU - Least Recently Used)
        items.sort { $0.date < $1.date }

        for item in items {
            try? FileManager.default.removeItem(at: item.url)
            total -= item.size
            if total <= targetTrimBytes {
                break
            }
        }
    }

    func clear() {
        if let files = try? FileManager.default.contentsOfDirectory(at: cacheDir, includingPropertiesForKeys: nil) {
            for file in files {
                try? FileManager.default.removeItem(at: file)
            }
        }
    }

    func diskUsageBytes() -> Int64 {
        var total: Int64 = 0
        if let files = try? FileManager.default.contentsOfDirectory(at: cacheDir, includingPropertiesForKeys: [.fileSizeKey]) {
            for file in files {
                if let size = try? file.resourceValues(forKeys: [.fileSizeKey]).fileSize {
                    total += Int64(size)
                }
            }
        }
        return total
    }
}

actor KLImageDownloader {
    static let shared = KLImageDownloader()
    private var inFlight: [String: Task<UIImage?, Never>] = [:]

    func fetch(urlString: String) async -> UIImage? {
        guard !urlString.isEmpty, let url = URL(string: urlString) else { return nil }

        // Level 1: Memory RAM Cache (Instant)
        if let cached = KLImageCache.shared.get(for: urlString) {
            return cached
        }

        // Level 2: Local Disk Cache (< 2ms, avoid network entirely)
        if let diskImg = KLDiskImageCache.shared.get(for: urlString) {
            KLImageCache.shared.set(diskImg, for: urlString)
            return diskImg
        }

        // Level 3: In-flight deduplication (Coalescing concurrent identical requests)
        if let ongoing = inFlight[urlString] {
            return await ongoing.value
        }

        let downloadTask = Task<UIImage?, Never> {
            var req = URLRequest(url: url)
            req.timeoutInterval = 12
            // Không lưu đúp vào URLCache vì KLDiskImageCache đã quản lý độc lập có giới hạn trần
            req.cachePolicy = .reloadIgnoringLocalCacheData
            req.setValue("Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X)", forHTTPHeaderField: "User-Agent")

            do {
                let (data, _) = try await URLSession.shared.data(for: req)
                guard !Task.isCancelled, let rawImage = UIImage(data: data) else { return nil }

                // Save raw file bytes to disk cache asynchronously
                KLDiskImageCache.shared.set(data, for: urlString)

                // Downsample to poster display dimensions (~360x540) to cut GPU/RAM pressure
                let targetSize = CGSize(width: 360, height: 540)
                let preparedThumb = await rawImage.byPreparingThumbnail(ofSize: targetSize)
                let preparedDisplay = await rawImage.byPreparingForDisplay()
                let displayImage = preparedThumb ?? (preparedDisplay ?? rawImage)

                KLImageCache.shared.set(displayImage, for: urlString)
                return displayImage
            } catch {
                return nil
            }
        }

        inFlight[urlString] = downloadTask
        let result = await downloadTask.value
        inFlight.removeValue(forKey: urlString)
        return result
    }
}

struct KLAsyncImage: View {
    let url: String
    var contentMode: ContentMode = .fill

    @State private var image: UIImage? = nil
    @State private var isLoading: Bool = false
    @State private var loadTask: Task<Void, Never>? = nil

    init(url: String, contentMode: ContentMode = .fill) {
        self.url = url
        self.contentMode = contentMode
        // Frame-0 synchronous RAM cache check: renders image on first frame without flickering!
        if let cached = KLImageCache.shared.get(for: url) {
            _image = State(initialValue: cached)
        }
    }

    var body: some View {
        ZStack {
            if let img = image {
                Image(uiImage: img)
                    .resizable()
                    .aspectRatio(contentMode: contentMode)
            } else {
                // Sleek Netflix-style Shimmer Glass Placeholder
                LinearGradient(
                    colors: [
                        Color(red: 0.12, green: 0.12, blue: 0.16),
                        Color(red: 0.18, green: 0.18, blue: 0.23),
                        Color(red: 0.12, green: 0.12, blue: 0.16)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            }
        }
        .onAppear {
            if image == nil {
                loadImage()
            }
        }
        .onChange(of: url) { _ in
            loadImage()
        }
        .onDisappear {
            // Cancel pending network task on scroll fling
            loadTask?.cancel()
            loadTask = nil
        }
    }

    private func loadImage() {
        guard !url.isEmpty else { return }

        // Fast path 1: Instant RAM
        if let cached = KLImageCache.shared.get(for: url) {
            self.image = cached
            self.isLoading = false
            return
        }

        loadTask?.cancel()
        self.isLoading = true

        loadTask = Task {
            let fetched = await KLImageDownloader.shared.fetch(urlString: url)
            guard !Task.isCancelled else { return }
            await MainActor.run {
                withAnimation(.easeOut(duration: 0.22)) {
                    self.image = fetched
                    self.isLoading = false
                }
            }
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

// MARK: - Cinema Consolidated Widescreen History Card (1 Bộ Phim Tinh Gọn)
struct KLCinemaConsolidatedHistoryCard: View {
    let item: ConsolidatedWatchItem
    let onPlay: () -> Void
    var onDelete: (() -> Void)? = nil

    var body: some View {
        Button(action: onPlay) {
            VStack(alignment: .leading, spacing: 8) {
                // 1. Poster Art (16:9 Cinema Widescreen with Gradient & Badges)
                ZStack(alignment: .bottom) {
                    KLAsyncImage(
                        url: item.posterUrl,
                        contentMode: .fill
                    )
                    .frame(width: 180, height: 110)
                    .clipped()

                    // Subtle Dark Gradient Overlay
                    LinearGradient(
                        colors: [.clear, Color.black.opacity(0.40), Color.black.opacity(0.92)],
                        startPoint: .top,
                        endPoint: .bottom
                    )

                    // Centered Frosted Play Icon
                    Circle()
                        .fill(Color.black.opacity(0.55))
                        .frame(width: 38, height: 38)
                        .overlay(
                            Circle().stroke(Color.white.opacity(0.35), lineWidth: 0.8)
                        )
                        .overlay(
                            Image(systemName: "play.fill")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.white)
                                .offset(x: 1.5)
                        )
                        .shadow(color: Color.black.opacity(0.6), radius: 6, x: 0, y: 2)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)

                    // Top Bar (Left: Latest Episode Badge, Right: Delete or Total Episodes Pill)
                    VStack {
                        HStack {
                            Text(item.latestEpisodeName.isEmpty ? "Đang xem" : item.latestEpisodeName)
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 7)
                                .padding(.vertical, 3.5)
                                .background(Color.black.opacity(0.75))
                                .clipShape(Capsule())

                            Spacer()

                            if let onDelete = onDelete {
                                Button(action: onDelete) {
                                    Image(systemName: "xmark")
                                        .font(.system(size: 9.5, weight: .bold))
                                        .foregroundColor(.white.opacity(0.85))
                                        .frame(width: 24, height: 24)
                                        .background(Color.black.opacity(0.75))
                                        .clipShape(Circle())
                                }
                                .buttonStyle(.plain)
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
                                        colors: [Color(red: 0.85, green: 0.22, blue: 0.28), Color(red: 1.0, green: 0.40, blue: 0.45)],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(width: geo.size.width * max(0.06, min(1.0, item.progressPercent)), height: 3.5)
                        }
                    }
                    .frame(height: 3.5)
                }
                .frame(width: 180, height: 110)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.white.opacity(0.12), lineWidth: 0.8)
                )

                // 2. Movie Title & Consolidated Subtitle Info
                VStack(alignment: .leading, spacing: 3) {
                    Text(item.filmName)
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.white)
                        .lineLimit(1)

                    HStack(spacing: 4) {
                        Image(systemName: "play.circle.fill")
                            .font(.system(size: 10))
                            .foregroundColor(KLTheme.brandOrange)

                        let epText = item.latestEpisodeName.isEmpty ? "Tiếp tục xem" : item.latestEpisodeName
                        let infoText = item.totalEpisodesWatched > 1 ? "\(epText) · \(item.totalEpisodesWatched) tập đã xem" : "\(epText) · \(Int(item.progressPercent * 100))%"
                        Text(infoText)
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(KLTheme.textMuted)
                    }
                    .lineLimit(1)
                }
                .frame(width: 180, alignment: .leading)
            }
        }
        .buttonStyle(.plain)
    }
}
