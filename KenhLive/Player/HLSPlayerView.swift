import SwiftUI
import AVFoundation
import AVKit

// MARK: - Native iOS Cinema Player View
struct HLSPlayerView: View {
    let title: String
    let subtitle: String
    var roomNum: String? = nil
    var directUrl: String? = nil
    var streamReferer: String? = nil
    var room: LiveRoom? = nil
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
    @State private var isLoadingStream: Bool = true
    @State private var isPlaying: Bool = true
    @State private var isMuted: Bool = false
    @State private var isAspectFill: Bool = false

    // VOD Timeline State
    @State private var isLiveStream: Bool = true
    @State private var currentTime: Double = 0
    @State private var duration: Double = 0
    @State private var isDraggingSlider: Bool = false
    @State private var sliderValue: Double = 0
    @State private var timeObserverToken: Any? = nil

    // OSD Overlay & Interaction
    @State private var isControlsVisible: Bool = true
    @State private var hideControlsTask: Task<Void, Never>? = nil
    @State private var seekRippleText: String? = nil
    @State private var seekRippleSide: Alignment = .center
    @State private var seekRippleTask: Task<Void, Never>? = nil

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            // 1. Core Native Cinema Player with Aspect Fit / Fill (100% Crash-Proof)
            if let p = player {
                NativeCinemaPlayerRepresentable(player: p, isAspectFill: isAspectFill)
                    .ignoresSafeArea()
            }

            // 2. Gesture Surface (Single tap to toggle, Double tap to seek, Swipe to dismiss)
            GeometryReader { geo in
                Color.clear
                    .contentShape(Rectangle())
                    .onTapGesture(count: 2) { location in
                        let width = geo.size.width
                        if location.x < width * 0.42 {
                            performQuickSeek(seconds: -10, side: .leading)
                        } else if location.x > width * 0.58 {
                            performQuickSeek(seconds: 10, side: .trailing)
                        } else {
                            togglePlayPause()
                        }
                    }
                    .onTapGesture(count: 1) {
                        toggleControls()
                    }
                    .gesture(
                        DragGesture(minimumDistance: 35)
                            .onEnded { value in
                                // Swipe down to dismiss (Standard iOS Modal Gesture)
                                if value.translation.height > 85 && abs(value.translation.width) < 120 {
                                    closePlayer()
                                }
                            }
                    )
                    .gesture(
                        MagnificationGesture()
                            .onEnded { scale in
                                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                    isAspectFill = scale > 1.05
                                }
                            }
                    )
            }
            .ignoresSafeArea()

            // 3. Double-Tap Seek Ripple Feedback Overlay
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
                    .background(Color.black.opacity(0.72))
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
            if isControlsVisible {
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
        }
        .task {
            configureAudioSession()
            await startPlayback()
        }
        .onDisappear {
            closePlayer()
        }
    }

    // MARK: - Top Bar View
    private var topBarView: some View {
        HStack(alignment: .center, spacing: 12) {
            // Dismiss Button (Standard iOS Glass Blur Button)
            Button {
                KLHaptics.light()
                closePlayer()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.white)
                    .frame(width: 36, height: 36)
                    .background(Color.white.opacity(0.18))
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)

            // Title & Subtitle
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 14.5, weight: .bold))
                    .foregroundColor(.white)
                    .lineLimit(1)

                Text(subtitle)
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
                    .background(Color.black.opacity(0.65))
                    .clipShape(Capsule())
                    .overlay(
                        Capsule().stroke(KLTheme.brandOrange.opacity(0.4), lineWidth: 0.8)
                    )
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, isFullscreen ? 48 : 12) // Safe area top offset when fullscreen
        .padding(.bottom, 12)
    }

    // MARK: - Center Controls View
    private var centerControlsView: some View {
        HStack(spacing: 36) {
            // Seek Backward 10s
            Button {
                performQuickSeek(seconds: -10, side: .leading)
            } label: {
                Image(systemName: "gobackward.10")
                    .font(.system(size: 26, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(width: 48, height: 48)
                    .background(Color.black.opacity(0.55))
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)

            // Play / Pause Button
            Button {
                togglePlayPause()
            } label: {
                Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.white)
                    .frame(width: 66, height: 66)
                    .background(
                        LinearGradient(
                            colors: [KLTheme.brandOrange, Color(red: 0.95, green: 0.32, blue: 0.05)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .clipShape(Circle())
                    .shadow(color: KLTheme.brandOrange.opacity(0.4), radius: 10, x: 0, y: 3)
            }
            .buttonStyle(.plain)

            // Seek Forward 10s
            Button {
                performQuickSeek(seconds: 10, side: .trailing)
            } label: {
                Image(systemName: "goforward.10")
                    .font(.system(size: 26, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(width: 48, height: 48)
                    .background(Color.black.opacity(0.55))
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Bottom Bar View
    private var bottomBarView: some View {
        VStack(spacing: 10) {
            // VOD Progress Timeline (Only when duration > 0 and not live)
            if !isLiveStream && duration > 0 && duration.isFinite {
                let safeDuration = max(1.0, duration)
                let safeCurrent = min(max(0, currentTime), safeDuration)
                let safeValue = isDraggingSlider ? min(max(0, sliderValue), safeDuration) : safeCurrent
                VStack(spacing: 4) {
                    Slider(
                        value: Binding(
                            get: { safeValue },
                            set: { newValue in
                                isDraggingSlider = true
                                sliderValue = min(max(0, newValue), safeDuration)
                            }
                        ),
                        in: 0...safeDuration,
                        onEditingChanged: { editing in
                            isDraggingSlider = editing
                            if !editing {
                                seekToTime(sliderValue)
                            }
                            rescheduleAutoHide()
                        }
                    )
                    .tint(KLTheme.brandOrange)

                    HStack {
                        Text(formatTime(safeValue))
                            .font(.system(size: 11, weight: .medium, design: .monospaced))
                            .foregroundColor(KLTheme.textSecondary)

                        Spacer()

                        Text("-" + formatTime(max(0, safeDuration - safeValue)))
                            .font(.system(size: 11, weight: .medium, design: .monospaced))
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
                    .cornerRadius(6)
                }

                Spacer()

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
                    .padding(.vertical, 5)
                    .background(Color.white.opacity(0.16))
                    .cornerRadius(7)
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
                        .background(Color.white.opacity(0.16))
                        .clipShape(Circle())
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
                            .background(Color.white.opacity(0.16))
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(.horizontal, 18)
        .padding(.top, 8)
        .padding(.bottom, isFullscreen ? 36 : 10) // Safe area bottom offset
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
    }

    private func startPlayback() async {
        isLoadingStream = true
        if let r = room {
            let list = await SportsService.shared.resolveStreamServers(room: r)
            servers = list
            if let first = list.first, let url = URL(string: first.url) {
                playUrl(url, referer: first.referer.isEmpty ? r.streamReferer : first.referer)
            }
        } else if let direct = directUrl {
            var targetUrlStr = direct
            if let extracted = extractDirectM3u8(from: direct) {
                targetUrlStr = extracted
            }
            if let url = URL(string: targetUrlStr) {
                let ref = streamReferer ?? ""
                servers = [StreamServer(name: "MÁY CHỦ CHÍNH", url: targetUrlStr, isBackup: false, referer: ref)]
                playUrl(url, referer: ref)
            }
        } else if let num = roomNum {
            let dummy = LiveRoom(roomNum: num, blvName: "BLV", avatar: "", viewers: 0, matchTitle: title, league: subtitle, cover: "", category: "Bóng đá", blvLevel: "", score: 0, notice: "")
            let list = await SportsService.shared.resolveStreamServers(room: dummy)
            servers = list
            if let first = list.first, let url = URL(string: first.url) {
                playUrl(url, referer: first.referer)
            }
        }
        isLoadingStream = false
    }

    private func switchServer(to index: Int) {
        guard index < servers.count, let url = URL(string: servers[index].url) else { return }
        currentServerIndex = index
        playUrl(url, referer: servers[index].referer)
        rescheduleAutoHide()
    }

    private func playUrl(_ url: URL, referer: String) {
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
            self.player = p
            setupTimeObserver(for: p)
        } else {
            player?.replaceCurrentItem(with: item)
        }

        if initialTimeSeconds > 0 {
            let target = CMTime(seconds: initialTimeSeconds, preferredTimescale: 600)
            player?.seek(to: target)
        }

        player?.isMuted = isMuted
        player?.play()
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
            }
            if !dur.isNaN && dur > 0 && !dur.isInfinite {
                self.duration = dur
                self.isLiveStream = false
            } else {
                self.isLiveStream = true
            }
        }
    }

    private func seekToTime(_ seconds: Double) {
        guard let p = player else { return }
        let targetTime = CMTime(seconds: seconds, preferredTimescale: 600)
        p.seek(to: targetTime, toleranceBefore: .zero, toleranceAfter: .zero)
        onProgressUpdate?(seconds, duration)
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

    private func togglePlayPause() {
        guard let p = player else { return }
        KLHaptics.medium()
        if isPlaying {
            p.pause()
            isPlaying = false
            showControlsPermanently()
            onProgressUpdate?(currentTime, duration)
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

    private func closePlayer() {
        hideControlsTask?.cancel()
        seekRippleTask?.cancel()
        if let token = timeObserverToken {
            player?.removeTimeObserver(token)
            timeObserverToken = nil
        }
        if currentTime > 0 {
            onProgressUpdate?(currentTime, duration)
        }
        player?.pause()
        player = nil
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
        vc.videoGravity = isAspectFill ? .resizeAspectFill : .resizeAspect
        return vc
    }

    func updateUIViewController(_ uiViewController: AVPlayerViewController, context: Context) {
        if uiViewController.player != player {
            uiViewController.player = player
        }
        uiViewController.showsPlaybackControls = false
        uiViewController.videoGravity = isAspectFill ? .resizeAspectFill : .resizeAspect
    }
}
