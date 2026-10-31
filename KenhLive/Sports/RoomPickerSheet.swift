import SwiftUI

struct RoomPickerSheet: View {
    let matchGroup: LiveMatchGroup
    var onSelectRoom: ((LiveRoom) -> Void)? = nil
    @Environment(\.dismiss) private var dismiss
    @State private var activeRoomForPlayer: LiveRoom? = nil

    var body: some View {
        ZStack {
            KLTheme.bgDeep.ignoresSafeArea()

            VStack(spacing: 0) {
                // Header Bar (Typography-First, Zero Clutter)
                VStack(spacing: 4) {
                    RoundedRectangle(cornerRadius: 2.5)
                        .fill(Color.white.opacity(0.2))
                        .frame(width: 36, height: 4.5)
                        .padding(.top, 10)
                        .padding(.bottom, 10)

                    Text(matchGroup.league.uppercased())
                        .font(.system(size: 10.5, weight: .black, design: .rounded))
                        .tracking(1.4)
                        .foregroundColor(KLTheme.brandOrange)

                    Text(matchGroup.matchTitle)
                        .font(.system(size: 17, weight: .bold))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                        .padding(.horizontal, 20)

                    Text("\(matchGroup.rooms.count) PHÒNG BÌNH LUẬN TRỰC TIẾP · \(DataNormalizer.formatViewers(matchGroup.totalViewers)) NGƯỜI XEM")
                        .font(.system(size: 10.5, weight: .semibold, design: .monospaced))
                        .foregroundColor(KLTheme.textMuted)
                        .padding(.top, 2)
                }
                .padding(.bottom, 14)

                Divider()
                    .background(KLTheme.borderSubtle)

                // List of Commentator Rooms
                ScrollView(showsIndicators: false) {
                    LazyVStack(spacing: 10) {
                        ForEach(matchGroup.rooms) { room in
                            Button {
                                KLHaptics.selection()
                                activeRoomForPlayer = room
                                onSelectRoom?(room)
                            } label: {
                                HStack(spacing: 12) {
                                    // Avatar / Initial Icon
                                    ZStack {
                                        Circle()
                                            .fill(
                                                LinearGradient(
                                                    colors: [roomProviderColor(room.provider), roomProviderColor(room.provider).opacity(0.6)],
                                                    startPoint: .topLeading,
                                                    endPoint: .bottomTrailing
                                                )
                                            )
                                            .frame(width: 42, height: 42)

                                        if !room.avatar.isEmpty {
                                            KLAsyncImage(url: room.avatar, contentMode: .fill, isLogo: true)
                                                .frame(width: 42, height: 42)
                                                .clipShape(Circle())
                                        } else {
                                            Image(systemName: "mic.fill")
                                                .font(.system(size: 16, weight: .bold))
                                                .foregroundColor(.white)
                                        }
                                    }

                                    // Room Details
                                    VStack(alignment: .leading, spacing: 4) {
                                        HStack(spacing: 6) {
                                            Text(room.blvName.uppercased())
                                                .font(.system(size: 14.5, weight: .heavy))
                                                .foregroundColor(.white)

                                            KLLivePulseBadge(text: "LIVE", color: KLTheme.liveRed)
                                        }

                                        HStack(spacing: 6) {
                                            Text(room.providerDisplayName)
                                                .font(.system(size: 9, weight: .heavy, design: .rounded))
                                                .foregroundColor(.white)
                                                .padding(.horizontal, 5)
                                                .padding(.vertical, 2)
                                                .background(roomProviderColor(room.provider))
                                                .cornerRadius(4)

                                            if !room.blvLevel.isEmpty {
                                                Text(room.blvLevel)
                                                    .font(.system(size: 9, weight: .bold))
                                                    .foregroundColor(KLTheme.brandOrange)
                                                    .padding(.horizontal, 5)
                                                    .padding(.vertical, 2)
                                                    .background(KLTheme.brandOrange.opacity(0.12))
                                                    .cornerRadius(4)
                                            }

                                            Text(room.notice)
                                                .font(.system(size: 11, weight: .regular))
                                                .foregroundColor(KLTheme.textSecondary)
                                                .lineLimit(1)
                                        }
                                    }

                                    Spacer()

                                    // Viewers & Play Button
                                    VStack(alignment: .trailing, spacing: 2) {
                                        Text(room.formattedViewers)
                                            .font(.system(size: 13, weight: .bold, design: .rounded))
                                            .foregroundColor(.white)

                                        HStack(spacing: 4) {
                                            Text("VÀO XEM")
                                                .font(.system(size: 9, weight: .bold))
                                                .foregroundColor(KLTheme.brandOrange)
                                            Image(systemName: "play.circle.fill")
                                                .font(.system(size: 14))
                                                .foregroundColor(KLTheme.brandOrange)
                                        }
                                    }
                                }
                                .padding(12)
                                .klGlassCard(cornerRadius: 12)
                            }
                            .buttonStyle(KLScaleButtonStyle())
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        .fullScreenCover(item: $activeRoomForPlayer) { room in
            HLSPlayerView(
                title: room.matchTitle,
                subtitle: "\(room.providerDisplayName) · \(room.blvName)",
                room: room,
                onClose: {
                    activeRoomForPlayer = nil
                }
            )
        }
    }

    private func roomProviderColor(_ p: String) -> Color {
        switch p.lowercased() {
        case "gavang", "gavang33": return Color(red: 0.95, green: 0.65, blue: 0.12)
        case "colatv", "cola": return Color(red: 0.18, green: 0.55, blue: 0.96)
        case "giovang", "khandai": return Color(red: 0.92, green: 0.30, blue: 0.24)
        default: return KLTheme.brandOrange
        }
    }
}
