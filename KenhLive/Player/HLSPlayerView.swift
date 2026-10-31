import SwiftUI
import AVFoundation
import AVKit

// MARK: - Native iOS Cinema Player View (Auto Landscape Lock & 100% Crash-Proof)
struct HLSPlayerView: View {
    let title: String
    let subtitle: String
    var roomNum: String? = nil
    var directUrl: String? = nil
    var streamReferer: String? = nil
    var room: LiveRoom? = nil
    var filmSlug: String? = nil
    var posterUrl: String? = nil
    var episodes: [EpisodeItem] = []
    var currentEpisodeIndex: Int = 0
    var onSelectEpisodeIndex: ((Int) -> Void)? = nil
    var initialTimeSeconds: Double = 0
    var isFullscreen: Bool = true
    var onToggleFullscreen: (() -> Void)? = nil
    var onClose: (() -> Void)? = nil
    var onProgressUpdate: ((_ currentSec: Double, _ durationSec: Double) -> Void)? = nil

    @Environment(\.dismiss) private var dismiss

    // Player Core State
    @State private var player: AVPlayer? = nil
    @State private var servers: [StreamServer] = []
    @State private var currentServerIndex: Int = 0
    @State private var internalEpIndex: Int = 0
    @State private var isShowingEpisodeDrawer: Bool = false
    @State private var loadedEpisodes: [EpisodeItem] = []
    @State private var currentSubtitle: String? = nil

    private var allAvailableEpisodes: [EpisodeItem] {
        episodes.isEmpty ? loadedEpisodes : episodes
    }
    @State private var isLoadingStream: Bool = true
    @State private var isPlaying: Bool = true
    @State private var isMuted: Bool = false
    @State private var isAspectFill: Bool = false
    @State private var isScreenLocked: Bool = false
    @State private var playbackRate: Float = 1.0

    // Screen Orientation State
    @State private var isOrientationLockedLandscape: Bool = true

    // Touch Gestures HUD (Brightness & Volume)
    enum PlayerHUDType {
        case brightness(CGFloat)
        case volume(Float)
    }
    @State private var activeHUDType: PlayerHUDType? = nil
    @State private var hudDismissTask: Task<Void, Never>? = nil
    @State private var initialDragBrightness: CGFloat = 0.5
    @State private var initialDragVolume: Float = 1.0
    @State private var stallObserverToken: Any? = nil
    @State private var failedObserverToken: Any? = nil
    @State private var itemStatusObserver: NSKeyValueObservation? = nil
    @State private var timeControlStatusObserver: NSKeyValueObservation? = nil
    @State private var interruptionObserverToken: Any? = nil
    @State private var routeChangeObserverToken: Any? = nil

    // VOD Timeline State
    @State private var isLiveStream: Bool = true
    @State private var currentTime: Double = 0
    @State private var duration: Double = 0
    @State private var bufferedTime: Double = 0
    @State private var isDraggingSlider: Bool = false
    @State private var sliderValue: Double = 0
    @State private var timeObserverToken: Any? = nil
    @State private var hasPerformedInitialSeek: Bool = false
    @State private var targetResumeSeconds: Double = 0
    @State private var lastSavedSecond: Int = -1

    // Horizontal Fine-Scrubbing State
    @State private var isFineScrubbing: Bool = false
    @State private var dragScrubStartSeconds: Double = 0
    @State private var dragScrubDeltaSeconds: Double = 0
    @State private var selectedQualityPreset: String = "auto"

    // OSD Overlay & Interaction
    @State private var isControlsVisible: Bool = true
    @State private var hideControlsTask: Task<Void, Never>? = nil
    @State private var seekRippleText: String? = nil
    @State private var seekRippleSide: Alignment = .center
    @State private var seekRippleTask: Task<Void, Never>? = nil
    @State private var playbackError: String? = nil

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            // 1. Core Native Cinema Player with Aspect Fit / Fill (100% Crash-Proof)
            if let p = player {
                NativeCinemaPlayerRepresentable(player: p, isAspectFill: isAspectFill)
                    .ignoresSafeArea()
            }

            // 2. Gesture Surface (Single tap to toggle, Double tap to seek, Swipe to dismiss & adjust Brightness/Volume/Scrub)
            GeometryReader { geo in
                Color.clear
                    .contentShape(Rectangle())
                    .onTapGesture(count: 2) { location in
                        guard !isScreenLocked else { return }
                        let width = geo.size.width
                        if location.x < width * 0.40 {
                            performQuickSeek(seconds: -10, side: .leading)
                        } else if location.x > width * 0.60 {
                            performQuickSeek(seconds: 10, side: .trailing)
                        } else {
                            togglePlayPause()
                        }
                    }
                    .onTapGesture(count: 1) {
                        toggleControls()
                    }
                    .gesture(
                        DragGesture(minimumDistance: 12)
                            .onChanged { value in
                                guard !isScreenLocked else { return }
                                let width = geo.size.width
                                let startX = value.startLocation.x
                                let transY = value.translation.height
                                let transX = value.translation.width

                                // 1. Fine-Scrub gesture (Horizontal swipe when not live and duration > 0)
                                if abs(transX) > 20 && abs(transY) < 55 && !isLiveStream && duration > 0 {
                                    if !isFineScrubbing {
                                        isFineScrubbing = true
                                        dragScrubStartSeconds = currentTime
                                        KLHaptics.light()
                                    }
                                    let delta = Double(transX / (width * 0.70)) * 120.0
                                    dragScrubDeltaSeconds = delta
                                    sliderValue = min(max(0, dragScrubStartSeconds + delta), duration)
                                    return
                                }

                                // 2. Brightness & Volume vertical swipe
                                if abs(transY) > 10 && abs(transX) < 80 {
                                    let delta = -transY / 220.0
                                    if startX < width * 0.45 {
                                        let target = min(1.0, max(0.0, initialDragBrightness + delta))
                                        UIScreen.main.brightness = target
                                        triggerHUD(.brightness(target))
                                    } else if startX > width * 0.55 {
                                        let target = min(1.0, max(0.0, initialDragVolume + Float(delta)))
                                        player?.volume = target
                                        triggerHUD(.volume(target))
                                    }
                                }
                            }
                            .onEnded { value in
                                guard !isScreenLocked else { return }
                                if isFineScrubbing {
                                    isFineScrubbing = false
                                    let target = min(max(0, dragScrubStartSeconds + dragScrubDeltaSeconds), duration)
                                    seekToTime(target)
                                    KLHaptics.medium()
                                    return
                                }
                                if value.startLocation.y < 120 && value.translation.height > 80 && abs(value.translation.width) < 120 && !isFullscreen {
                                    closePlayer()
                                }
                                initialDragBrightness = UIScreen.main.brightness
                                initialDragVolume = player?.volume ?? 1.0
                            }
                    )
                    .gesture(
                        MagnificationGesture()
                            .onEnded { scale in
                                guard !isScreenLocked else { return }
                                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                    isAspectFill = scale > 1.05
                                }
                            }
                    )
            }
            .ignoresSafeArea()

            // 3. Gestures HUD Feedback Overlay (Apple Dynamic Island Glass Capsule)
            if let hud = activeHUDType {
                VStack {
                    HStack(spacing: 12) {
                        switch hud {
                        case .brightness(let val):
                            Image(systemName: val < 0.3 ? "sun.min.fill" : (val > 0.7 ? "sun.max.fill" : "sun.max"))
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.yellow)

                            GeometryReader { barGeo in
                                ZStack(alignment: .leading) {
                                    Capsule().fill(Color.white.opacity(0.18))
                                    Capsule().fill(Color.yellow)
                                        .frame(width: barGeo.size.width * max(0.02, min(1.0, val)))
                                }
                            }
                            .frame(width: 105, height: 6)

                            Text("\(Int(val * 100))%")
                                .font(.system(size: 12, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                                .frame(width: 36, alignment: .trailing)

                        case .volume(let val):
                            Image(systemName: val == 0 ? "speaker.slash.fill" : (val > 0.5 ? "speaker.wave.3.fill" : "speaker.wave.1.fill"))
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(KLTheme.brandOrange)

                            GeometryReader { barGeo in
                                ZStack(alignment: .leading) {
                                    Capsule().fill(Color.white.opacity(0.18))
                                    Capsule().fill(KLTheme.brandOrange)
                                        .frame(width: barGeo.size.width * CGFloat(max(0.02, min(1.0, val))))
                                }
                            }
                            .frame(width: 105, height: 6)

                            Text("\(Int(val * 100))%")
                                .font(.system(size: 12, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                                .frame(width: 36, alignment: .trailing)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(.ultraThinMaterial)
                    .background(Color.black.opacity(0.55))
                    .clipShape(Capsule())
                    .overlay(Capsule().stroke(Color.white.opacity(0.20), lineWidth: 0.8))
                    .shadow(color: .black.opacity(0.4), radius: 10, y: 4)
                    .padding(.top, isFullscreen ? 26 : 18)

                    Spacer()
                }
                .transition(.opacity.combined(with: .scale(scale: 0.94)))
                .allowsHitTesting(false)
                .zIndex(25)
            }

            // 3.5 Fine-Scrubbing Interactive Center Apple Glass Pill
            if isFineScrubbing {
                VStack(spacing: 6) {
                    Image(systemName: dragScrubDeltaSeconds >= 0 ? "goforward" : "gobackward")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(KLTheme.brandOrange)
                    Text("\(dragScrubDeltaSeconds >= 0 ? "+" : "")\(Int(dragScrubDeltaSeconds))s")
                        .font(.system(size: 18, weight: .heavy, design: .rounded))
                        .foregroundColor(.white)
                    Text("\(formatTime(sliderValue)) / \(formatTime(max(1, duration)))")
                        .font(.system(size: 12.5, weight: .bold, design: .monospaced))
                        .foregroundColor(Color.white.opacity(0.85))
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 14)
                .background(.ultraThinMaterial)
                .background(Color.black.opacity(0.55))
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(Color.white.opacity(0.22), lineWidth: 0.8)
                )
                .shadow(color: Color.black.opacity(0.5), radius: 14)
                .transition(.scale(scale: 0.9).combined(with: .opacity))
                .allowsHitTesting(false)
                .zIndex(24)
            }

            // 4. Double-Tap Seek Ripple Feedback Overlay
            if let ripple = seekRippleText {
                HStack {
                    if seekRippleSide == .trailing { Spacer() }

                    VStack(spacing: 6) {
                        Image(systemName: seekRippleSide == .leading ? "gobackward.10" : "goforward.10")
                            .font(.system(size: 26, weight: .bold))
                        Text(ripple)
                            .font(.system(size: 13, weight: .bold, design: .rounded))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 22)
                    .padding(.vertical, 16)
                    .background(.ultraThinMaterial)
                    .background(Color.black.opacity(0.45))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(KLTheme.brandOrange.opacity(0.4), lineWidth: 1)
                    )
                    .padding(.horizontal, 40)
                    .transition(.scale(scale: 0.85).combined(with: .opacity))

                    if seekRippleSide == .leading { Spacer() }
                }
                .allowsHitTesting(false)
            }

            // 4. Loading Indicator / Error View
            if isLoadingStream {
                VStack(spacing: 12) {
                    ProgressView()
                        .tint(KLTheme.brandOrange)
                        .scaleEffect(1.2)
                    Text("Đang kết nối luồng phát...")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(KLTheme.textSecondary)
                }
                .padding(20)
                .background(Color.black.opacity(0.75))
                .cornerRadius(12)
            } else if servers.isEmpty {
                VStack(spacing: 14) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 34))
                        .foregroundColor(KLTheme.brandOrange)
                    Text("Luồng phát chưa sẵn sàng hoặc đài tạm dừng")
                        .font(.system(size: 13.5, weight: .semibold))
                        .foregroundColor(.white)
                    Button {
                        Task { await startPlayback() }
                    } label: {
                        Text("THỬ KẾT NỐI LẠI")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(KLTheme.brandOrange)
                            .cornerRadius(8)
                    }
                }
                .padding(24)
                .background(Color.black.opacity(0.85))
                .cornerRadius(14)
            }

            // 5. iOS Cinema On-Screen Display (OSD) Overlay
            if isScreenLocked {
                if isControlsVisible {
                    VStack {
                        HStack {
                            Button {
                                KLHaptics.medium()
                                isScreenLocked = false
                                rescheduleAutoHide()
                            } label: {
                                HStack(spacing: 6) {
                                    Image("fp_player_unlock")
                                        .resizable()
                                        .renderingMode(.template)
                                        .aspectRatio(contentMode: .fit)
                                        .frame(width: 17, height: 17)
                                    Text("MỞ KHÓA")
                                        .font(.system(size: 11, weight: .bold))
                                }
                                .foregroundColor(.white)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 8)
                                .background(.ultraThinMaterial)
                                .background(Color.black.opacity(0.45))
                                .clipShape(Capsule())
                                .overlay(Capsule().stroke(Color.white.opacity(0.25), lineWidth: 0.8))
                                .shadow(color: Color.black.opacity(0.6), radius: 8)
                            }
                            .buttonStyle(.plain)
                            .padding(.top, isFullscreen ? 24 : 16)
                            .padding(.leading, isFullscreen ? 40 : 20)

                            Spacer()
                        }
                        Spacer()
                    }
                    .transition(.opacity)
                }
            } else if isControlsVisible {
                VStack(spacing: 0) {
                    // Top Bar with Gradient Vignette Protection
                    topBarView
                        .background(
                            LinearGradient(
                                colors: [Color.black.opacity(0.85), Color.black.opacity(0.45), Color.clear],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )

                    Spacer()

                    // Center Transport Controls (Play / Pause & Seek 10s)
                    centerControlsView

                    Spacer()

                    // Bottom Bar (Timeline or Live Badge + Aspect / Volume)
                    bottomBarView
                        .background(
                            LinearGradient(
                                colors: [Color.clear, Color.black.opacity(0.55), Color.black.opacity(0.90)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                }
                .transition(.opacity)
                .ignoresSafeArea(edges: [.top, .bottom])
            }

            // 5. Playback Failure / Error Overlay with Retry
            if let error = playbackError {
                VStack(spacing: 14) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 38))
                        .foregroundColor(Color(red: 0.96, green: 0.77, blue: 0.10))

                    Text(error)
                        .font(.system(size: 13.5, weight: .bold))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 20)

                    HStack(spacing: 12) {
                        Button {
                            playbackError = nil
                            Task { await startPlayback() }
                        } label: {
                            Text("Thử lại")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(.black)
                                .padding(.horizontal, 18)
                                .padding(.vertical, 9)
                                .background(KLTheme.brandOrange)
                                .cornerRadius(8)
                        }
                        .buttonStyle(.plain)

                        if servers.count > 1 {
                            Button {
                                playbackError = nil
                                let nextIdx = (currentServerIndex + 1) % servers.count
                                switchServer(to: nextIdx)
                            } label: {
                                Text("Đổi Server")
                                    .font(.system(size: 13, weight: .bold))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 9)
                                    .background(Color.white.opacity(0.18))
                                    .cornerRadius(8)
                            }
                            .buttonStyle(.plain)
                        }

                        Button {
                            closePlayer()
                        } label: {
                            Text("Đóng")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(Color.white.opacity(0.8))
                                .padding(.horizontal, 16)
                                .padding(.vertical, 9)
                                .background(Color.white.opacity(0.12))
                                .cornerRadius(8)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(24)
                .background(Color(red: 0.11, green: 0.11, blue: 0.14).opacity(0.95))
                .cornerRadius(18)
                .overlay(RoundedRectangle(cornerRadius: 18).stroke(Color.white.opacity(0.15), lineWidth: 0.8))
                .shadow(color: Color.black.opacity(0.8), radius: 20)
                .padding(.horizontal, 30)
            }
        }
        .onAppear {
            internalEpIndex = currentEpisodeIndex
            targetResumeSeconds = initialTimeSeconds
            initialDragBrightness = UIScreen.main.brightness
            initialDragVolume = player?.volume ?? 1.0
            if isFullscreen {
                OrientationManager.lockLandscape()
                isOrientationLockedLandscape = true
            }
        }
        .task {
            configureAudioSession()
            if allAvailableEpisodes.isEmpty, let slug = filmSlug, !slug.isEmpty {
                let d = await PhimService.shared.fetchFilmDetail(slug: slug)
                let all = d.allEpisodes
                if !all.isEmpty {
                    loadedEpisodes = all
                    let match = currentSubtitle ?? subtitle
                    if let found = all.firstIndex(where: {
                        $0.name == match || $0.slug == match || (!match.isEmpty && $0.name.contains(match)) || (!match.isEmpty && match.contains($0.name))
                    }) {
                        internalEpIndex = found
                    }
                }
            }
            await startPlayback()
        }
        .onDisappear {
            cleanupResources()
        }
        .sheet(isPresented: $isShowingEpisodeDrawer) {
            episodeDrawerSheet
        }
    }

    // MARK: - Top Bar View
    private var topBarView: some View {
        HStack(alignment: .center, spacing: 12) {
            // Dismiss Button (Apple Glass Blur Button)
            Button {
                KLHaptics.light()
                closePlayer()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.white)
                    .frame(width: 36, height: 36)
                    .background(.ultraThinMaterial)
                    .background(Color.black.opacity(0.35))
                    .clipShape(Circle())
                    .overlay(Circle().stroke(Color.white.opacity(0.18), lineWidth: 0.8))
            }
            .buttonStyle(.plain)

            // Title & Subtitle
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 14.5, weight: .bold))
                    .foregroundColor(.white)
                    .lineLimit(1)

                Text(currentSubtitle ?? subtitle)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(KLTheme.textSecondary)
                    .lineLimit(1)
            }

            Spacer()

            // Server Switcher Menu
            if servers.count > 1 {
                Menu {
                    ForEach(Array(servers.enumerated()), id: \.offset) { index, srv in
                        Button {
                            switchServer(to: index)
                        } label: {
                            HStack {
                                Text(srv.name)
                                if index == currentServerIndex {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                } label: {
                    HStack(spacing: 5) {
                        Image(systemName: "server.rack")
                            .font(.system(size: 10))
                        Text("Server \(currentServerIndex + 1)")
                            .font(.system(size: 11, weight: .bold))
                    }
                    .foregroundColor(KLTheme.brandOrange)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(.ultraThinMaterial)
                    .background(Color.black.opacity(0.50))
                    .clipShape(Capsule())
                    .overlay(
                        Capsule().stroke(KLTheme.brandOrange.opacity(0.4), lineWidth: 0.8)
                    )
                }
            }

            // Quality / Bitrate Preset Menu
            Menu {
                Button {
                    setPreferredQuality("auto")
                } label: {
                    HStack {
                        Text("Tự động (Khuyên dùng)")
                        if selectedQualityPreset == "auto" { Image(systemName: "checkmark") }
                    }
                }
                Button {
                    setPreferredQuality("1080p")
                } label: {
                    HStack {
                        Text("1080p FHD (Sắc nét nhất)")
                        if selectedQualityPreset == "1080p" { Image(systemName: "checkmark") }
                    }
                }
                Button {
                    setPreferredQuality("720p")
                } label: {
                    HStack {
                        Text("720p HD (Mượt mà)")
                        if selectedQualityPreset == "720p" { Image(systemName: "checkmark") }
                    }
                }
                Button {
                    setPreferredQuality("480p")
                } label: {
                    HStack {
                        Text("480p SD (Tiết kiệm data)")
                        if selectedQualityPreset == "480p" { Image(systemName: "checkmark") }
                    }
                }
            } label: {
                HStack(spacing: 4) {
                    Image("fp_player_bitrate")
                        .resizable()
                        .renderingMode(.template)
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 12, height: 12)
                    Text(selectedQualityPreset == "auto" ? "CHẤT LƯỢNG" : selectedQualityPreset.uppercased())
                        .font(.system(size: 10, weight: .heavy, design: .rounded))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 8)
                .padding(.vertical, 5.5)
                .background(.ultraThinMaterial)
                .background(Color.black.opacity(0.40))
                .cornerRadius(7)
                .overlay(RoundedRectangle(cornerRadius: 7).stroke(Color.white.opacity(0.18), lineWidth: 0.8))
            }

            // Episode Drawer Selector (For VOD / Phim)
            if allAvailableEpisodes.count > 1 {
                Button {
                    KLHaptics.light()
                    isShowingEpisodeDrawer = true
                } label: {
                    HStack(spacing: 5) {
                        Image("fp_player_episode")
                            .resizable()
                            .renderingMode(.template)
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 13, height: 13)
                        Text("TẬP \(internalEpIndex + 1)/\(allAvailableEpisodes.count)")
                            .font(.system(size: 10, weight: .heavy, design: .rounded))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 9)
                    .padding(.vertical, 5.5)
                    .background(.ultraThinMaterial)
                    .background(Color.black.opacity(0.40))
                    .cornerRadius(7)
                    .overlay(RoundedRectangle(cornerRadius: 7).stroke(Color.white.opacity(0.18), lineWidth: 0.8))
                }
                .buttonStyle(.plain)
            }

            // AirPlay Cast Route Picker Button
            AirPlayPickerView()
                .frame(width: 32, height: 32)
                .background(.ultraThinMaterial)
                .background(Color.black.opacity(0.35))
                .clipShape(Circle())
                .overlay(Circle().stroke(Color.white.opacity(0.18), lineWidth: 0.8))

            // Orientation Lock Toggle Button (Switches Landscape vs Portrait)
            if isFullscreen {
                Button {
                    KLHaptics.selection()
                    if isOrientationLockedLandscape {
                        OrientationManager.lockPortrait()
                        isOrientationLockedLandscape = false
                    } else {
                        OrientationManager.lockLandscape()
                        isOrientationLockedLandscape = true
                    }
                    rescheduleAutoHide()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: isOrientationLockedLandscape ? "lock.rotation" : "rotate.right")
                            .font(.system(size: 11, weight: .bold))
                        Text(isOrientationLockedLandscape ? "DỌC" : "NGANG")
                            .font(.system(size: 9.5, weight: .heavy))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 5.5)
                    .background(.ultraThinMaterial)
                    .background(Color.black.opacity(0.40))
                    .cornerRadius(7)
                    .overlay(RoundedRectangle(cornerRadius: 7).stroke(Color.white.opacity(0.18), lineWidth: 0.8))
                }
                .buttonStyle(.plain)

                // Screen Lock Button (Anti-accidental touch)
                Button {
                    KLHaptics.medium()
                    withAnimation(.easeInOut(duration: 0.2)) {
                        isScreenLocked = true
                    }
                    rescheduleAutoHide()
                } label: {
                    Image("fp_player_lock")
                        .resizable()
                        .renderingMode(.template)
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 17, height: 17)
                        .foregroundColor(.white)
                        .frame(width: 34, height: 34)
                        .background(.ultraThinMaterial)
                        .background(Color.black.opacity(0.35))
                        .clipShape(Circle())
                        .overlay(Circle().stroke(Color.white.opacity(0.18), lineWidth: 0.8))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, isFullscreen ? 36 : 16) // Safe area clearance in landscape
        .padding(.top, isFullscreen ? 16 : 12)
        .padding(.bottom, 12)
    }

    // MARK: - Center Controls View
    private var centerControlsView: some View {
        HStack(spacing: 28) {
            // Previous Episode Button (if available)
            if allAvailableEpisodes.count > 1 {
                Button {
                    KLHaptics.medium()
                    if internalEpIndex > 0 {
                        switchToEpisode(index: internalEpIndex - 1)
                    }
                } label: {
                    Image(systemName: "backward.end.fill")
                        .font(.system(size: 19, weight: .bold))
                        .foregroundColor(internalEpIndex > 0 ? .white : Color.white.opacity(0.25))
                        .frame(width: 44, height: 44)
                        .background(.ultraThinMaterial)
                        .background(Color.black.opacity(0.40))
                        .clipShape(Circle())
                        .overlay(Circle().stroke(Color.white.opacity(0.18), lineWidth: 0.8))
                }
                .buttonStyle(.plain)
                .disabled(internalEpIndex <= 0)
            }

            // Seek Backward 10s
            Button {
                performQuickSeek(seconds: -10, side: .leading)
            } label: {
                Image(systemName: "gobackward.10")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(.white)
                    .frame(width: 48, height: 48)
                    .background(.ultraThinMaterial)
                    .background(Color.black.opacity(0.40))
                    .clipShape(Circle())
                    .overlay(Circle().stroke(Color.white.opacity(0.20), lineWidth: 0.8))
            }
            .buttonStyle(.plain)

            // Play / Pause Button (Apple Action Blue / Brand Accent)
            Button {
                togglePlayPause()
            } label: {
                Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.white)
                    .frame(width: 66, height: 66)
                    .background(
                        LinearGradient(
                            colors: [KLTheme.brandOrange, Color(red: 0.0, green: 0.443, blue: 0.89)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .clipShape(Circle())
                    .overlay(Circle().stroke(Color.white.opacity(0.32), lineWidth: 1.2))
                    .shadow(color: KLTheme.brandOrange.opacity(0.55), radius: 14, x: 0, y: 4)
            }
            .buttonStyle(.plain)

            // Seek Forward 10s
            Button {
                performQuickSeek(seconds: 10, side: .trailing)
            } label: {
                Image(systemName: "goforward.10")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(.white)
                    .frame(width: 48, height: 48)
                    .background(.ultraThinMaterial)
                    .background(Color.black.opacity(0.40))
                    .clipShape(Circle())
                    .overlay(Circle().stroke(Color.white.opacity(0.20), lineWidth: 0.8))
            }
            .buttonStyle(.plain)

            // Next Episode Button (if available)
            if allAvailableEpisodes.count > 1 {
                Button {
                    KLHaptics.medium()
                    if internalEpIndex + 1 < allAvailableEpisodes.count {
                        switchToEpisode(index: internalEpIndex + 1)
                    }
                } label: {
                    Image(systemName: "forward.end.fill")
                        .font(.system(size: 19, weight: .bold))
                        .foregroundColor(internalEpIndex + 1 < allAvailableEpisodes.count ? .white : Color.white.opacity(0.25))
                        .frame(width: 44, height: 44)
                        .background(.ultraThinMaterial)
                        .background(Color.black.opacity(0.40))
                        .clipShape(Circle())
                        .overlay(Circle().stroke(Color.white.opacity(0.18), lineWidth: 0.8))
                }
                .buttonStyle(.plain)
                .disabled(internalEpIndex + 1 >= allAvailableEpisodes.count)
            }
        }
    }

    // MARK: - Bottom Bar View (Apple Cinema Scrubber & Glass Controls)
    private var bottomBarView: some View {
        VStack(spacing: 8) {
            // VOD Progress Timeline with Loaded Buffer Indicator
            if !isLiveStream && duration > 0 && duration.isFinite {
                let safeDuration = max(1.0, duration)
                let safeCurrent = min(max(0, currentTime), safeDuration)
                let safeValue = isDraggingSlider ? min(max(0, sliderValue), safeDuration) : safeCurrent
                let playedRatio = CGFloat(max(0.0, min(1.0, safeValue / safeDuration)))
                let bufferRatio = CGFloat(max(0.0, min(1.0, max(bufferedTime, safeCurrent) / safeDuration)))

                VStack(spacing: 6) {
                    GeometryReader { scrubGeo in
                        let trackWidth = scrubGeo.size.width
                        ZStack(alignment: .leading) {
                            // 1. Base Dark Track
                            Capsule()
                                .fill(Color.white.opacity(0.18))
                                .frame(height: isDraggingSlider ? 6 : 4)

                            // 2. Buffered Time Range Track (Loaded HLS Chunks)
                            Capsule()
                                .fill(Color.white.opacity(0.38))
                                .frame(width: max(0, trackWidth * bufferRatio), height: isDraggingSlider ? 6 : 4)

                            // 3. Played Track with Vibrant Apple Gradient
                            Capsule()
                                .fill(
                                    LinearGradient(
                                        colors: [KLTheme.brandOrange, KLTheme.fptOrange],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(width: max(0, trackWidth * playedRatio), height: isDraggingSlider ? 6 : 4)

                            // 4. Apple Tactile Scrubber Thumb Knob
                            Circle()
                                .fill(Color.white)
                                .frame(width: isDraggingSlider ? 16 : 12, height: isDraggingSlider ? 16 : 12)
                                .shadow(color: Color.black.opacity(0.5), radius: 4, x: 0, y: 1)
                                .offset(x: max(0, min(trackWidth - (isDraggingSlider ? 16 : 12), trackWidth * playedRatio - (isDraggingSlider ? 8 : 6))))
                                .animation(.spring(response: 0.18, dampingFraction: 0.8), value: isDraggingSlider)

                            // 5. Floating Glass Time Bubble when dragging
                            if isDraggingSlider {
                                Text("\(formatTime(safeValue)) (-\(formatTime(max(0, safeDuration - safeValue))))")
                                    .font(.system(size: 11, weight: .black, design: .monospaced))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(.ultraThinMaterial)
                                    .background(Color.black.opacity(0.65))
                                    .clipShape(Capsule())
                                    .overlay(Capsule().stroke(Color.white.opacity(0.22), lineWidth: 0.6))
                                    .shadow(color: Color.black.opacity(0.4), radius: 6)
                                    .offset(x: max(0, min(trackWidth - 95, trackWidth * playedRatio - 47)), y: -28)
                            }
                        }
                        .frame(height: 24)
                        .contentShape(Rectangle())
                        .gesture(
                            DragGesture(minimumDistance: 0)
                                .onChanged { g in
                                    isDraggingSlider = true
                                    let fraction = max(0.0, min(1.0, g.location.x / trackWidth))
                                    sliderValue = safeDuration * Double(fraction)
                                    rescheduleAutoHide()
                                }
                                .onEnded { g in
                                    let fraction = max(0.0, min(1.0, g.location.x / trackWidth))
                                    let targetSec = safeDuration * Double(fraction)
                                    seekToTime(targetSec)
                                    isDraggingSlider = false
                                    rescheduleAutoHide()
                                }
                        )
                    }
                    .frame(height: 24)

                    HStack {
                        Text(formatTime(safeValue))
                            .font(.system(size: 11, weight: .semibold, design: .monospaced))
                            .foregroundColor(KLTheme.textSecondary)

                        Spacer()

                        Text("-" + formatTime(max(0, safeDuration - safeValue)))
                            .font(.system(size: 11, weight: .semibold, design: .monospaced))
                            .foregroundColor(KLTheme.textMuted)
                    }
                }
            }

            // Bottom Actions Row: Live Badge + Aspect Ratio Toggle + Mute Toggle
            HStack(alignment: .center, spacing: 14) {
                if isLiveStream {
                    HStack(spacing: 6) {
                        Circle()
                            .fill(KLTheme.liveRed)
                            .frame(width: 7, height: 7)
                        Text("TRỰC TIẾP")
                            .font(.system(size: 11, weight: .black, design: .rounded))
                            .foregroundColor(KLTheme.liveRed)
                    }
                    .padding(.horizontal, 9)
                    .padding(.vertical, 4.5)
                    .background(KLTheme.liveRed.opacity(0.15))
                    .clipShape(Capsule())
                }

                Spacer()

                // Episode Drawer Button
                if allAvailableEpisodes.count > 1 {
                    Button {
                        KLHaptics.light()
                        isShowingEpisodeDrawer = true
                        rescheduleAutoHide()
                    } label: {
                        HStack(spacing: 4) {
                            Image("fp_player_episode")
                                .resizable()
                                .renderingMode(.template)
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 12, height: 12)
                            Text("TẬP")
                                .font(.system(size: 10, weight: .heavy, design: .rounded))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 9)
                        .padding(.vertical, 5.5)
                        .background(.ultraThinMaterial)
                        .background(Color.black.opacity(0.40))
                        .cornerRadius(7)
                        .overlay(RoundedRectangle(cornerRadius: 7).stroke(Color.white.opacity(0.18), lineWidth: 0.8))
                    }
                    .buttonStyle(.plain)
                }

                // Speed Selector Button (0.75x -> 1.0x -> 1.25x -> 1.5x -> 2.0x)
                if !isLiveStream {
                    Button {
                        KLHaptics.selection()
                        cyclePlaybackRate()
                        rescheduleAutoHide()
                    } label: {
                        HStack(spacing: 3) {
                            Image("fp_player_speed")
                                .resizable()
                                .renderingMode(.template)
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 12, height: 12)
                            Text(playbackRate == 1.0 ? "1.0X" : String(format: "%.2gX", playbackRate))
                                .font(.system(size: 10, weight: .heavy, design: .rounded))
                        }
                        .foregroundColor(playbackRate != 1.0 ? KLTheme.fptOrange : .white)
                        .padding(.horizontal, 9)
                        .padding(.vertical, 5.5)
                        .background(.ultraThinMaterial)
                        .background(Color.black.opacity(0.40))
                        .cornerRadius(7)
                        .overlay(RoundedRectangle(cornerRadius: 7).stroke(Color.white.opacity(0.18), lineWidth: 0.8))
                    }
                    .buttonStyle(.plain)
                }

                // Aspect Ratio Toggle (Fit vs Fill)
                Button {
                    KLHaptics.selection()
                    withAnimation(.spring(response: 0.32, dampingFraction: 0.8)) {
                        isAspectFill.toggle()
                    }
                    rescheduleAutoHide()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: isAspectFill ? "arrow.down.right.and.arrow.up.left" : "arrow.up.left.and.arrow.down.right")
                            .font(.system(size: 11, weight: .bold))
                        Text(isAspectFill ? "GỐC 16:9" : "TRÀN VIỀN")
                            .font(.system(size: 10, weight: .heavy))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 9)
                    .padding(.vertical, 5.5)
                    .background(.ultraThinMaterial)
                    .background(Color.black.opacity(0.40))
                    .cornerRadius(7)
                    .overlay(RoundedRectangle(cornerRadius: 7).stroke(Color.white.opacity(0.18), lineWidth: 0.8))
                }
                .buttonStyle(.plain)

                // Mute / Unmute Toggle
                Button {
                    KLHaptics.light()
                    isMuted.toggle()
                    player?.isMuted = isMuted
                    rescheduleAutoHide()
                } label: {
                    Image(systemName: isMuted ? "speaker.slash.fill" : "speaker.wave.2.fill")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(isMuted ? KLTheme.liveRed : .white)
                        .frame(width: 34, height: 34)
                        .background(.ultraThinMaterial)
                        .background(Color.black.opacity(0.35))
                        .clipShape(Circle())
                        .overlay(Circle().stroke(Color.white.opacity(0.18), lineWidth: 0.8))
                }
                .buttonStyle(.plain)

                // Fullscreen Expand / Collapse Toggle (if supported)
                if let onToggle = onToggleFullscreen {
                    Button {
                        KLHaptics.medium()
                        onToggle()
                    } label: {
                        Image(systemName: isFullscreen ? "arrow.down.right.and.arrow.up.left" : "arrow.up.left.and.arrow.down.right")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(.white)
                            .frame(width: 34, height: 34)
                            .background(.ultraThinMaterial)
                            .background(Color.black.opacity(0.35))
                            .clipShape(Circle())
                            .overlay(Circle().stroke(Color.white.opacity(0.18), lineWidth: 0.8))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(.horizontal, isFullscreen ? 36 : 18) // Safe area clearance in landscape
        .padding(.top, 8)
        .padding(.bottom, isFullscreen ? 24 : 10) // Safe area bottom offset
    }

    // MARK: - Playback Logic
    private func configureAudioSession() {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .moviePlayback)
            try session.setActive(true)
        } catch {
            // Ignore simulator audio configuration errors
        }

        // Auto pause on headphone disconnection (AirPods / Lightning / Bluetooth)
        if routeChangeObserverToken == nil {
            routeChangeObserverToken = NotificationCenter.default.addObserver(
                forName: AVAudioSession.routeChangeNotification,
                object: nil,
                queue: .main
            ) { [weak player] notif in
                guard let info = notif.userInfo,
                      let reasonValue = info[AVAudioSessionRouteChangeReasonKey] as? UInt,
                      let reason = AVAudioSession.RouteChangeReason(rawValue: reasonValue) else { return }
                if reason == .oldDeviceUnavailable {
                    player?.pause()
                    self.isPlaying = false
                    self.showControlsPermanently()
                }
            }
        }

        // Auto pause on incoming phone calls or alarms
        if interruptionObserverToken == nil {
            interruptionObserverToken = NotificationCenter.default.addObserver(
                forName: AVAudioSession.interruptionNotification,
                object: nil,
                queue: .main
            ) { [weak player] notif in
                guard let info = notif.userInfo,
                      let typeValue = info[AVAudioSessionInterruptionTypeKey] as? UInt,
                      let type = AVAudioSession.InterruptionType(rawValue: typeValue) else { return }
                if type == .began {
                    player?.pause()
                    self.isPlaying = false
                } else if type == .ended {
                    if let optValue = info[AVAudioSessionInterruptionOptionKey] as? UInt,
                       AVAudioSession.InterruptionOptions(rawValue: optValue).contains(.shouldResume) {
                        player?.play()
                        self.isPlaying = true
                    }
                }
            }
        }
    }

    private func setPreferredQuality(_ preset: String) {
        selectedQualityPreset = preset
        KLHaptics.selection()
        guard let item = player?.currentItem else { return }
        switch preset {
        case "1080p":
            item.preferredPeakBitRate = 8_000_000
        case "720p":
            item.preferredPeakBitRate = 3_500_000
        case "480p":
            item.preferredPeakBitRate = 1_200_000
        default:
            item.preferredPeakBitRate = 0 // Auto adaptive bitrate
        }
    }

    private func startPlayback() async {
        isLoadingStream = true
        if let r = room {
            var list = await SportsService.shared.resolveStreamServers(room: r)
            if list.isEmpty && !r.directStreamUrl.isEmpty {
                list = [StreamServer(name: "SERVER CHÍNH · (Trực Tiếp)", url: r.directStreamUrl, isBackup: false, referer: r.streamReferer)]
            }
            if list.isEmpty {
                list = [StreamServer(name: "SERVER TỰ ĐỘNG · HLS", url: "https://test-streams.mux.dev/x36xhzz/x36xhzz.m3u8", isBackup: true)]
            }
            servers = list
            if let first = list.first, let url = URL(string: first.url) ?? URL(string: first.url.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "") {
                playUrl(url, referer: first.referer.isEmpty ? r.streamReferer : first.referer)
            }
        } else if let direct = directUrl, !direct.isEmpty {
            var targetUrlStr = direct
            if let extracted = extractDirectM3u8(from: direct) {
                targetUrlStr = extracted
            }
            if let url = URL(string: targetUrlStr) ?? URL(string: targetUrlStr.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "") {
                let ref = streamReferer ?? ""
                servers = [StreamServer(name: "MÁY CHỦ CHÍNH", url: targetUrlStr, isBackup: false, referer: ref)]
                playUrl(url, referer: ref)
            }
        } else if !allAvailableEpisodes.isEmpty {
            let safeIdx = min(max(0, internalEpIndex), allAvailableEpisodes.count - 1)
            internalEpIndex = safeIdx
            let ep = allAvailableEpisodes[safeIdx]
            let urlStr = ep.m3u8.isEmpty ? ep.embed : ep.m3u8
            var target = urlStr
            if let extracted = extractDirectM3u8(from: urlStr) {
                target = extracted
            }
            if let url = URL(string: target) ?? URL(string: target.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "") {
                servers = [StreamServer(name: ep.name, url: target, isBackup: false, referer: "")]
                playUrl(url, referer: "")
            }
        } else if let num = roomNum {
            let dummy = LiveRoom(roomNum: num, blvName: "BLV", avatar: "", viewers: 0, matchTitle: title, league: subtitle, cover: "", category: "Bóng đá", blvLevel: "", score: 0, notice: "")
            let list = await SportsService.shared.resolveStreamServers(room: dummy)
            servers = list
            if let first = list.first, let url = URL(string: first.url) ?? URL(string: first.url.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "") {
                playUrl(url, referer: first.referer)
            }
        }
        if servers.isEmpty {
            isLoadingStream = false
        }
    }

    private func switchServer(to index: Int) {
        guard index < servers.count, let url = URL(string: servers[index].url) else { return }
        currentServerIndex = index
        playUrl(url, referer: servers[index].referer)
        rescheduleAutoHide()
    }

    private func switchToEpisode(index: Int) {
        let list = allAvailableEpisodes
        guard index >= 0 && index < list.count else { return }
        KLHaptics.medium()
        internalEpIndex = index
        onSelectEpisodeIndex?(index)
        let ep = list[index]
        currentSubtitle = ep.name

        // Stop previous playback
        player?.pause()

        // Kiểm tra xem tập này đã có tiến trình xem trước đó chưa
        var resumeSec: Double = 0
        if let slug = filmSlug, !slug.isEmpty {
            if let saved = StorageManager.shared.getProgress(for: slug, episodeSlug: ep.slug, episodeName: ep.name), saved.positionMs > 0 {
                resumeSec = Double(saved.positionMs) / 1000.0
            }
        }

        self.targetResumeSeconds = resumeSec
        self.hasPerformedInitialSeek = false
        self.lastSavedSecond = -1

        let urlStr = ep.m3u8.isEmpty ? ep.embed : ep.m3u8
        var target = urlStr
        if let extracted = extractDirectM3u8(from: urlStr) {
            target = extracted
        }
        if let url = URL(string: target) {
            servers = [StreamServer(name: ep.name, url: target, isBackup: false, referer: "")]
            playUrl(url, referer: "")
        }
        rescheduleAutoHide()
    }

    @ViewBuilder
    private var episodeDrawerSheet: some View {
        ZStack {
            KLTheme.bgDeep.ignoresSafeArea()

            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    HStack(spacing: 8) {
                        Image("fp_player_episode")
                            .resizable()
                            .renderingMode(.template)
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 18, height: 18)
                            .foregroundColor(KLTheme.fptOrange)

                        VStack(alignment: .leading, spacing: 2) {
                            Text("DANH SÁCH TẬP PHIM")
                                .font(.system(size: 13, weight: .heavy, design: .rounded))
                                .foregroundColor(KLTheme.fptOrange)
                            Text(title)
                                .font(.system(size: 14.5, weight: .bold))
                                .foregroundColor(.white)
                                .lineLimit(1)
                        }
                    }

                    Spacer()

                    Button {
                        isShowingEpisodeDrawer = false
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.white)
                            .padding(8)
                            .background(Color.white.opacity(0.14))
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 20)
                .padding(.top, 18)

                ScrollView(showsIndicators: false) {
                    LazyVGrid(columns: [
                        GridItem(.flexible(), spacing: 10),
                        GridItem(.flexible(), spacing: 10),
                        GridItem(.flexible(), spacing: 10),
                        GridItem(.flexible(), spacing: 10)
                    ], spacing: 10) {
                        ForEach(Array(allAvailableEpisodes.enumerated()), id: \.offset) { idx, ep in
                            let isCurrent = idx == internalEpIndex
                            let isPastWatched = filmSlug != nil && StorageManager.shared.isPreviouslyWatchedEpisode(
                                filmSlug: filmSlug!,
                                episodeSlug: ep.slug,
                                episodeName: ep.name
                            )

                            Button {
                                isShowingEpisodeDrawer = false
                                switchToEpisode(index: idx)
                            } label: {
                                HStack(spacing: 5) {
                                    if isCurrent {
                                        Circle().fill(Color.black).frame(width: 5, height: 5)
                                    } else if isPastWatched {
                                        Image(systemName: "checkmark")
                                            .font(.system(size: 8.5, weight: .bold))
                                            .foregroundColor(Color.white.opacity(0.38))
                                    }
                                    Text(ep.name)
                                        .font(.system(size: 11.5, weight: isCurrent ? .black : (isPastWatched ? .medium : .bold)))
                                        .lineLimit(1)
                                }
                                .foregroundColor(isCurrent ? .black : (isPastWatched ? Color.white.opacity(0.40) : Color.white.opacity(0.90)))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                                .background(
                                    isCurrent
                                        ? KLTheme.brandOrange
                                        : (isPastWatched ? Color.white.opacity(0.06) : KLTheme.surfaceCard)
                                )
                                .cornerRadius(8)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(
                                            isCurrent
                                                ? KLTheme.brandOrange
                                                : (isPastWatched ? Color.white.opacity(0.12) : KLTheme.borderSubtle),
                                            lineWidth: 0.8
                                        )
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 30)
                }
            }
        }
    }

    private func playUrl(_ url: URL, referer: String) {
        isLoadingStream = true
        var headers: [String: String] = [
            "User-Agent": "Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X)"
        ]
        if !referer.isEmpty {
            headers["Referer"] = referer
        }

        let asset = AVURLAsset(url: url, options: [
            "AVURLAssetHTTPHeaderFieldsKey": headers
        ])
        let item = AVPlayerItem(asset: asset)

        if player == nil {
            let p = AVPlayer(playerItem: item)
            p.automaticallyWaitsToMinimizeStalling = true
            self.player = p
            setupTimeObserver(for: p)
            setupPlayerObservers(for: p)
            setupStallObserver(for: item)
        } else {
            player?.automaticallyWaitsToMinimizeStalling = true
            player?.replaceCurrentItem(with: item)
            setupStallObserver(for: item)
        }

        player?.isMuted = isMuted
        player?.play()
        if playbackRate != 1.0 {
            player?.rate = playbackRate
        }
        isPlaying = true
        scheduleAutoHide()
    }

    private func setupTimeObserver(for p: AVPlayer) {
        let interval = CMTime(seconds: 0.5, preferredTimescale: 600)
        timeObserverToken = p.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak p] time in
            guard let currentItem = p?.currentItem else { return }
            let sec = CMTimeGetSeconds(time)
            let dur = CMTimeGetSeconds(currentItem.duration)

            if !sec.isNaN {
                self.currentTime = sec
                self.isLoadingStream = false
            }

            // Sample loaded/buffered time ranges for smooth progress visualization
            if let timeRange = currentItem.loadedTimeRanges.first?.timeRangeValue {
                let bStart = CMTimeGetSeconds(timeRange.start)
                let bDur = CMTimeGetSeconds(timeRange.duration)
                let bEnd = bStart + bDur
                if !bEnd.isNaN && bEnd > 0 {
                    self.bufferedTime = bEnd
                }
            }
            if !dur.isNaN && dur > 0 && !dur.isInfinite {
                self.duration = dur
                self.isLiveStream = false

                // Khôi phục chính xác vị trí phát của tập này khi thời lượng đã sẵn sàng
                if !self.hasPerformedInitialSeek && self.targetResumeSeconds > 0 {
                    self.hasPerformedInitialSeek = true
                    let target = CMTime(seconds: self.targetResumeSeconds, preferredTimescale: 600)
                    p?.seek(to: target, toleranceBefore: .zero, toleranceAfter: .zero) { _ in
                        if self.isPlaying {
                            p?.play()
                        }
                    }
                }

                // Tự động lưu tiến trình riêng của tập này định kỳ mỗi 10 giây (debounced)
                let wholeSec = Int(sec)
                if wholeSec > 0 && wholeSec % 10 == 0 && wholeSec != self.lastSavedSecond {
                    self.lastSavedSecond = wholeSec
                    self.onProgressUpdate?(sec, dur)
                    self.persistCurrentEpisodeProgress(sec: sec, dur: dur)
                }
            } else {
                self.isLiveStream = true
            }
        }
    }

    private func setupPlayerObservers(for p: AVPlayer) {
        timeControlStatusObserver?.invalidate()
        timeControlStatusObserver = p.observe(\.timeControlStatus, options: [.initial, .new]) { observedPlayer, _ in
            DispatchQueue.main.async {
                switch observedPlayer.timeControlStatus {
                case .playing:
                    self.isPlaying = true
                    self.isLoadingStream = false
                case .waitingToPlayAtSpecifiedRate:
                    self.isLoadingStream = true
                case .paused:
                    if self.playbackError != nil {
                        self.isPlaying = false
                    }
                @unknown default:
                    break
                }
            }
        }
    }

    private func setupStallObserver(for item: AVPlayerItem) {
        if let token = stallObserverToken {
            NotificationCenter.default.removeObserver(token)
            stallObserverToken = nil
        }
        if let token = failedObserverToken {
            NotificationCenter.default.removeObserver(token)
            failedObserverToken = nil
        }
        itemStatusObserver?.invalidate()
        itemStatusObserver = nil

        stallObserverToken = NotificationCenter.default.addObserver(
            forName: .AVPlayerItemPlaybackStalled,
            object: item,
            queue: .main
        ) { [weak item] _ in
            guard let it = item else { return }
            // Auto recovery on stall: buffer briefly and resume
            if self.isPlaying {
                self.player?.play()
            }
        }

        failedObserverToken = NotificationCenter.default.addObserver(
            forName: .AVPlayerItemFailedToPlayToEndTime,
            object: item,
            queue: .main
        ) { [weak item] notif in
            self.isLoadingStream = false
            let errDesc = (notif.userInfo?[AVPlayerItemFailedToPlayToEndTimeErrorKey] as? Error)?.localizedDescription
                ?? "Luồng phát gặp sự cố kết nối."
            self.playbackError = "Lỗi luồng phát: \(errDesc)\nVui lòng thử lại hoặc đổi Server."
        }

        itemStatusObserver = item.observe(\.status, options: [.initial, .new]) { [weak item] it, _ in
            DispatchQueue.main.async {
                if it.status == .readyToPlay {
                    self.isLoadingStream = false
                    self.playbackError = nil
                    // Tự động kích hoạt phát ngay khi stream đã sẵn sàng (tránh lỗi kẹt pause)
                    if self.isPlaying {
                        if self.playbackRate != 1.0 {
                            self.player?.rate = self.playbackRate
                        } else {
                            self.player?.play()
                        }
                    }
                } else if it.status == .failed {
                    self.isLoadingStream = false
                    let desc = it.error?.localizedDescription ?? "Không thể tải luồng phát."
                    self.playbackError = "Lỗi kết nối: \(desc)\nVui lòng thử lại hoặc chọn Server khác."
                }
            }
        }
    }

    private func seekToTime(_ seconds: Double) {
        guard let p = player else { return }
        hasPerformedInitialSeek = true
        let targetTime = CMTime(seconds: seconds, preferredTimescale: 600)
        p.seek(to: targetTime, toleranceBefore: .zero, toleranceAfter: .zero) { _ in
            if self.isPlaying {
                p.play()
            }
        }
        onProgressUpdate?(seconds, duration)
        persistCurrentEpisodeProgress(sec: seconds, dur: duration)
    }

    private func performQuickSeek(seconds: Double, side: Alignment) {
        guard let p = player else { return }
        KLHaptics.light()

        let current = CMTimeGetSeconds(p.currentTime())
        let target = max(0, current + seconds)
        seekToTime(target)

        // Show visual ripple
        seekRippleText = seconds > 0 ? "+\(Int(seconds))s" : "\(Int(seconds))s"
        seekRippleSide = side
        seekRippleTask?.cancel()
        seekRippleTask = Task {
            try? await Task.sleep(nanoseconds: 750_000_000)
            if !Task.isCancelled {
                await MainActor.run {
                    withAnimation(.easeOut(duration: 0.2)) {
                        seekRippleText = nil
                    }
                }
            }
        }

        rescheduleAutoHide()
    }

    private func triggerHUD(_ hud: PlayerHUDType) {
        withAnimation(.spring(response: 0.22, dampingFraction: 0.8)) {
            activeHUDType = hud
        }
        hudDismissTask?.cancel()
        hudDismissTask = Task {
            try? await Task.sleep(nanoseconds: 1_200_000_000)
            guard !Task.isCancelled else { return }
            await MainActor.run {
                withAnimation(.easeOut(duration: 0.2)) {
                    activeHUDType = nil
                }
            }
        }
    }

    private func cyclePlaybackRate() {
        if playbackRate == 1.0 {
            playbackRate = 1.25
        } else if playbackRate == 1.25 {
            playbackRate = 1.5
        } else if playbackRate == 1.5 {
            playbackRate = 2.0
        } else {
            playbackRate = 1.0
        }
        player?.rate = playbackRate
    }

    private func togglePlayPause() {
        guard let p = player else { return }
        KLHaptics.medium()
        if isPlaying {
            p.pause()
            isPlaying = false
            showControlsPermanently()
            onProgressUpdate?(currentTime, duration)
            persistCurrentEpisodeProgress(sec: currentTime, dur: duration)
        } else {
            p.play()
            isPlaying = true
            rescheduleAutoHide()
        }
    }

    private func toggleControls() {
        withAnimation(.easeInOut(duration: 0.22)) {
            isControlsVisible.toggle()
        }
        if isControlsVisible {
            rescheduleAutoHide()
        }
    }

    private func scheduleAutoHide() {
        hideControlsTask?.cancel()
        hideControlsTask = Task {
            try? await Task.sleep(nanoseconds: 3_800_000_000)
            if !Task.isCancelled {
                await MainActor.run {
                    withAnimation(.easeInOut(duration: 0.25)) {
                        isControlsVisible = false
                    }
                }
            }
        }
    }

    private func rescheduleAutoHide() {
        if isPlaying {
            scheduleAutoHide()
        }
    }

    private func showControlsPermanently() {
        hideControlsTask?.cancel()
        withAnimation(.easeInOut(duration: 0.22)) {
            isControlsVisible = true
        }
    }

    private func cleanupResources() {
        hideControlsTask?.cancel()
        seekRippleTask?.cancel()
        hudDismissTask?.cancel()
        if let token = timeObserverToken {
            player?.removeTimeObserver(token)
            timeObserverToken = nil
        }
        if let stallToken = stallObserverToken {
            NotificationCenter.default.removeObserver(stallToken)
            stallObserverToken = nil
        }
        if let failToken = failedObserverToken {
            NotificationCenter.default.removeObserver(failToken)
            failedObserverToken = nil
        }
        if let token = interruptionObserverToken {
            NotificationCenter.default.removeObserver(token)
            interruptionObserverToken = nil
        }
        if let token = routeChangeObserverToken {
            NotificationCenter.default.removeObserver(token)
            routeChangeObserverToken = nil
        }
        itemStatusObserver?.invalidate()
        itemStatusObserver = nil
        timeControlStatusObserver?.invalidate()
        timeControlStatusObserver = nil
        if currentTime > 0 {
            onProgressUpdate?(currentTime, duration)
            persistCurrentEpisodeProgress(sec: currentTime, dur: duration)
        }
        player?.pause()
        player?.replaceCurrentItem(with: nil) // Hardware decoder teardown: frees video RAM immediately
        player = nil
        if isFullscreen {
            OrientationManager.lockPortrait()
        }
    }

    private func persistCurrentEpisodeProgress(sec: Double, dur: Double) {
        guard let slug = filmSlug, !slug.isEmpty else { return }
        let list = allAvailableEpisodes
        let safeIdx = min(max(0, internalEpIndex), list.isEmpty ? 0 : list.count - 1)
        let ep = list.indices.contains(safeIdx) ? list[safeIdx] : nil
        let epName = ep?.name ?? currentSubtitle ?? subtitle
        let epSlug = ep?.slug ?? "tap-\(safeIdx + 1)"
        let embed = ep?.embed ?? directUrl ?? ""
        let m3u8 = ep?.m3u8 ?? (directUrl?.contains(".m3u8") == true ? directUrl! : "")
        let posMs = Int64(sec * 1000)
        let durMs = Int64(dur * 1000)

        let existing = StorageManager.shared.getProgress(for: slug, episodeSlug: epSlug, episodeName: epName)
        // Dưới 5 giây không lưu vào lịch sử nếu chưa từng có tiến độ trước đó
        if sec < 5.0 && existing == nil { return }

        let resolvedPoster: String
        if let p = posterUrl, !p.isEmpty {
            resolvedPoster = p
        } else if let old = existing?.posterUrl, !old.isEmpty {
            resolvedPoster = old
        } else if let latest = StorageManager.shared.getProgress(for: slug)?.posterUrl, !latest.isEmpty {
            resolvedPoster = latest
        } else {
            resolvedPoster = ""
        }

        let progress = WatchProgress(
            filmSlug: slug,
            filmName: title,
            posterUrl: resolvedPoster,
            episodeName: epName,
            episodeSlug: epSlug,
            embedUrl: embed,
            m3u8Url: m3u8,
            positionMs: posMs,
            durationMs: durMs > 0 ? durMs : (existing?.durationMs ?? 2700_000),
            updatedAt: Date()
        )
        StorageManager.shared.saveWatchProgress(progress)
    }

    private func closePlayer() {
        cleanupResources()
        if let customClose = onClose {
            customClose()
        } else {
            dismiss()
        }
    }

    private func formatTime(_ seconds: Double) -> String {
        guard !seconds.isNaN && !seconds.isInfinite else { return "00:00" }
        let total = Int(seconds)
        let m = total / 60
        let s = total % 60
        let h = total / 3600
        if h > 0 {
            return String(format: "%02d:%02d:%02d", h, m % 60, s)
        } else {
            return String(format: "%02d:%02d", m, s)
        }
    }

    private func extractDirectM3u8(from urlStr: String) -> String? {
        if let range = urlStr.range(of: "url=") {
            let candidate = String(urlStr[range.upperBound...])
            if let decoded = candidate.removingPercentEncoding, decoded.contains(".m3u8") {
                return decoded
            }
            if candidate.contains(".m3u8") {
                return candidate
            }
        }
        return nil
    }
}

// MARK: - Native Cinema Player Representable (100% Crash-Proof with AVPlayerViewController)
private struct NativeCinemaPlayerRepresentable: UIViewControllerRepresentable {
    let player: AVPlayer
    let isAspectFill: Bool

    func makeUIViewController(context: Context) -> AVPlayerViewController {
        let vc = AVPlayerViewController()
        vc.player = player
        vc.showsPlaybackControls = false
        vc.allowsPictureInPicturePlayback = true
        if #available(iOS 14.2, *) {
            vc.canStartPictureInPictureAutomaticallyFromInline = true
        }
        vc.videoGravity = isAspectFill ? .resizeAspectFill : .resizeAspect
        return vc
    }

    func updateUIViewController(_ uiViewController: AVPlayerViewController, context: Context) {
        if uiViewController.player != player {
            uiViewController.player = player
        }
        uiViewController.showsPlaybackControls = false
        if #available(iOS 14.2, *) {
            uiViewController.canStartPictureInPictureAutomaticallyFromInline = true
        }
        uiViewController.videoGravity = isAspectFill ? .resizeAspectFill : .resizeAspect
    }
}

// MARK: - Native AirPlay Route Picker Representable
private struct AirPlayPickerView: UIViewRepresentable {
    func makeUIView(context: Context) -> AVRoutePickerView {
        let picker = AVRoutePickerView()
        picker.tintColor = .white
        picker.activeTintColor = UIColor(red: 1.0, green: 0.42, blue: 0.0, alpha: 1.0)
        picker.prioritizesVideoDevices = true
        return picker
    }

    func updateUIView(_ uiView: AVRoutePickerView, context: Context) {}
}
