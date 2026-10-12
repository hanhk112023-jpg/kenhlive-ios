import SwiftUI

struct RoomPickerSheet: View {
    let matchGroup: LiveMatchGroup
    let onSelectRoom: (LiveRoom) -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            KLTheme.bgDeep.ignoresSafeArea()

            VStack(spacing: 0) {
                // Header Bar (Typography-First, Zero Clutter)
                VStack(spacing: 4) {
                    RoundedRectangle(cornerRadius: 2.5)
                        .fill(Color.white.opacity(0.2))
                        .frame(width: 36, height: 5)
                        .padding(.top, 10)
                        .padding(.bottom, 12)

                    Text(matchGroup.league.uppercased())
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .tracking(1.0)
                        .foregroundColor(KLTheme.brandOrange)

                    Text(matchGroup.matchTitle)
                        .font(.system(size: 17, weight: .bold))
                        .foregroundColor(KLTheme.textPrimary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 20)

                    Text("\(matchGroup.rooms.count) PHÒNG TRỰC TIẾP · \(DataNormalizer.formatViewers(matchGroup.totalViewers)) NGƯỜI XEM")
                        .font(.system(size: 11, weight: .medium, design: .monospaced))
                        .foregroundColor(KLTheme.textMuted)
                        .padding(.top, 2)
                }
                .padding(.bottom, 16)

                Divider()
                    .background(KLTheme.borderSubtle)

                // List of Commentator Rooms
                ScrollView {
                    LazyVStack(spacing: 10) {
                        ForEach(matchGroup.rooms) { room in
                            Button {
                                dismiss()
                                onSelectRoom(room)
                            } label: {
                                HStack(spacing: 14) {
                                    VStack(alignment: .leading, spacing: 5) {
                                        HStack(spacing: 8) {
                                            Text(room.blvName.uppercased())
                                                .font(.system(size: 15, weight: .heavy))
                                                .foregroundColor(KLTheme.textPrimary)

                                            if !room.blvLevel.isEmpty {
                                                KLPillBadge(text: room.blvLevel, fg: KLTheme.brandOrange, bg: KLTheme.brandOrange.opacity(0.12), border: KLTheme.brandOrange.opacity(0.25))
                                            }

                                            KLPillBadge(text: "LIVE", fg: .white, bg: KLTheme.liveRed, border: .clear)
                                        }

                                        Text(room.notice)
                                            .font(.system(size: 12, weight: .regular))
                                            .foregroundColor(KLTheme.textSecondary)
                                            .lineLimit(1)
                                    }

                                    Spacer()

                                    VStack(alignment: .trailing, spacing: 3) {
                                        Text(room.formattedViewers)
                                            .font(.system(size: 14, weight: .bold, design: .rounded))
                                            .foregroundColor(KLTheme.textPrimary)

                                        Text("XEM")
                                            .font(.system(size: 9.5, weight: .semibold, design: .monospaced))
                                            .foregroundColor(KLTheme.textMuted)
                                    }

                                    Text("CHỌN")
                                        .font(.system(size: 12, weight: .bold))
                                        .tracking(0.5)
                                        .foregroundColor(KLTheme.brandOrange)
                                        .padding(.horizontal, 14)
                                        .padding(.vertical, 8)
                                        .background(KLTheme.brandOrange.opacity(0.12))
                                        .cornerRadius(8)
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 14)
                                .background(KLTheme.surfaceCard)
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(KLTheme.borderSubtle, lineWidth: 0.8)
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(16)
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }
}
