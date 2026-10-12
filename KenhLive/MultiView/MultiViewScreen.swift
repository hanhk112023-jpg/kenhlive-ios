import SwiftUI
import AVKit

struct MultiViewSlotItem: Identifiable, Hashable {
    var id: String { title + streamUrl }
    let title: String
    let subtitle: String
    let streamUrl: String
}

struct MultiViewScreen: View {
    @State private var slot0Item = MultiViewSlotItem(
        title: "VTV1 HD",
        subtitle: "Truyền hình Quốc gia",
        streamUrl: "https://vtv1.vtvgo.vn/live/playlist.m3u8"
    )
    @State private var slot1Item = MultiViewSlotItem(
        title: "VTV3 HD",
        subtitle: "Thể thao & Giải trí",
        streamUrl: "https://vtv3.vtvgo.vn/live/playlist.m3u8"
    )

    @State private var activeAudioSlot: Int = 0
    @State private var pickingSlotIndex: Int? = nil
    @State private var availableItems: [MultiViewSlotItem] = []

    var body: some View {
        GeometryReader { geo in
            let isLandscape = geo.size.width > geo.size.height

            ZStack {
                KLTheme.bgDeep.ignoresSafeArea()

                VStack(spacing: 12) {
                    // Header Bar
                    if !isLandscape {
                        HStack(alignment: .lastTextBaseline) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("MULTIVIEW")
                                    .font(.system(size: 11, weight: .black, design: .rounded))
                                    .tracking(1.8)
                                    .foregroundColor(KLTheme.brandOrange)

                                Text("Xem 2 Màn Hình Cùng Lúc")
                                    .font(.system(size: 22, weight: .bold))
                                    .foregroundColor(KLTheme.textPrimary)
                            }

                            Spacer()

                            Text("CHẠM Ô ĐỂ BẬT TIẾNG")
                                .font(.system(size: 10, weight: .bold, design: .monospaced))
                                .foregroundColor(KLTheme.textMuted)
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 12)
                    }

                    // Dual Video Layout
                    if isLandscape {
                        HStack(spacing: 10) {
                            MultiViewCell(
                                index: 0,
                                item: slot0Item,
                                isAudioActive: activeAudioSlot == 0,
                                onSelectAudio: { activeAudioSlot = 0 },
                                onChangeSource: { pickingSlotIndex = 0 }
                            )

                            MultiViewCell(
                                index: 1,
                                item: slot1Item,
                                isAudioActive: activeAudioSlot == 1,
                                onSelectAudio: { activeAudioSlot = 1 },
                                onChangeSource: { pickingSlotIndex = 1 }
                            )
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                    } else {
                        VStack(spacing: 12) {
                            MultiViewCell(
                                index: 0,
                                item: slot0Item,
                                isAudioActive: activeAudioSlot == 0,
                                onSelectAudio: { activeAudioSlot = 0 },
                                onChangeSource: { pickingSlotIndex = 0 }
                            )

                            MultiViewCell(
                                index: 1,
                                item: slot1Item,
                                isAudioActive: activeAudioSlot == 1,
                                onSelectAudio: { activeAudioSlot = 1 },
                                onChangeSource: { pickingSlotIndex = 1 }
                            )
                        }
                        .padding(.horizontal, 16)
                        .padding(.bottom, 86)
                    }
                }
            }
        }
        .task {
            if availableItems.isEmpty {
                await loadAvailableStreams()
            }
        }
        .sheet(isPresented: Binding(
            get: { pickingSlotIndex != nil },
            set: { if !$0 { pickingSlotIndex = nil } }
        )) {
            MultiViewSourcePickerSheet(
                slotNumber: (pickingSlotIndex ?? 0) + 1,
                items: availableItems
            ) { chosen in
                if pickingSlotIndex == 0 {
                    slot0Item = chosen
                } else {
                    slot1Item = chosen
                }
                pickingSlotIndex = nil
            }
        }
    }

    private func loadAvailableStreams() async {
        let (soco, cola, gavang33, giovang) = await SportsService.shared.fetchLiveMatches()
        var items: [MultiViewSlotItem] = []

        for g in (soco + gavang33 + cola + giovang).prefix(10) {
            let top = g.topRoom
            let url = !top.directStreamUrl.isEmpty ? top.directStreamUrl : "https://test-streams.mux.dev/x36xhzz/x36xhzz.m3u8"
            items.append(MultiViewSlotItem(title: g.matchTitle, subtitle: "\(top.providerDisplayName) · \(top.blvName)", streamUrl: url))
        }

        let iptvCats = await IptvService.shared.fetchCuratedChannels()
        let channels = iptvCats.flatMap { $0.channels }.prefix(12)
        items.append(contentsOf: channels.map {
            MultiViewSlotItem(title: $0.name, subtitle: $0.group, streamUrl: $0.streamUrl)
        })

        availableItems = items
    }
}

private struct MultiViewCell: View {
    let index: Int
    let item: MultiViewSlotItem
    let isAudioActive: Bool
    let onSelectAudio: () -> Void
    let onChangeSource: () -> Void

    @State private var player: AVPlayer? = nil

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            Color.black

            if let p = player {
                VideoPlayer(player: p)
                    .disabled(true)
            }

            // Tap area to activate audio for this slot
            Color.clear
                .contentShape(Rectangle())
                .onTapGesture {
                    onSelectAudio()
                }

            // Bottom Overlay Bar
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text("MÀN \(index + 1)")
                            .font(.system(size: 10, weight: .black, design: .monospaced))
                            .foregroundColor(isAudioActive ? KLTheme.brandOrange : KLTheme.textMuted)

                        Text(isAudioActive ? "· ĐANG PHÁT TIẾNG" : "· TẮT TIẾNG")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(isAudioActive ? KLTheme.brandOrange : KLTheme.textMuted)
                    }

                    Text(item.title)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                        .lineLimit(1)
                }

                Spacer()

                Button(action: onChangeSource) {
                    Text("ĐỔI KÊNH")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 7)
                        .background(Color.white.opacity(0.14))
                        .cornerRadius(7)
                }
            }
            .padding(12)
            .background(
                LinearGradient(colors: [.clear, Color.black.opacity(0.85)], startPoint: .top, endPoint: .bottom)
            )
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .cornerRadius(14)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(isAudioActive ? KLTheme.brandOrange : KLTheme.borderSubtle, lineWidth: isAudioActive ? 2.0 : 0.8)
        )
        .onAppear {
            setupPlayer()
        }
        .onChange(of: item) { _ in
            setupPlayer()
        }
        .onChange(of: isAudioActive) { active in
            player?.isMuted = !active
        }
        .onDisappear {
            player?.pause()
            player = nil
        }
    }

    private func setupPlayer() {
        guard let url = URL(string: item.streamUrl) else { return }
        let p = AVPlayer(url: url)
        p.isMuted = !isAudioActive
        p.play()
        player = p
    }
}

private struct MultiViewSourcePickerSheet: View {
    let slotNumber: Int
    let items: [MultiViewSlotItem]
    let onSelect: (MultiViewSlotItem) -> Void

    var body: some View {
        ZStack {
            KLTheme.bgDeep.ignoresSafeArea()

            VStack(alignment: .leading, spacing: 12) {
                Text("CHỌN LUỒNG CHO MÀN HÌNH \(slotNumber)")
                    .font(.system(size: 13, weight: .heavy))
                    .tracking(0.8)
                    .foregroundColor(KLTheme.brandOrange)
                    .padding(.horizontal, 16)
                    .padding(.top, 20)

                ScrollView {
                    LazyVStack(spacing: 8) {
                        ForEach(items) { item in
                            Button {
                                onSelect(item)
                            } label: {
                                HStack {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(item.title)
                                            .font(.system(size: 14.5, weight: .bold))
                                            .foregroundColor(.white)

                                        Text(item.subtitle)
                                            .font(.system(size: 11.5, weight: .regular))
                                            .foregroundColor(KLTheme.textMuted)
                                    }
                                    Spacer()
                                    Text("CHỌN")
                                        .font(.system(size: 11, weight: .bold))
                                        .foregroundColor(KLTheme.brandOrange)
                                }
                                .padding(14)
                                .background(KLTheme.surfaceCard)
                                .cornerRadius(10)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(16)
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
}
