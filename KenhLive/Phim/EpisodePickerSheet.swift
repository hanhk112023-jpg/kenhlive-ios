import SwiftUI

struct EpisodePickerSheet: View {
    let film: FilmItem
    let onSelectEpisode: (EpisodeItem) -> Void
    @Environment(\.dismiss) private var dismiss

    @State private var synopsis: String = ""
    @State private var episodes: [EpisodeItem] = []
    @State private var isLoading: Bool = true

    var body: some View {
        ZStack {
            KLTheme.bgDeep.ignoresSafeArea()

            VStack(alignment: .leading, spacing: 0) {
                // Header
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        KLPillBadge(text: "IMDb \(film.imdbScore)", fg: KLTheme.imdbGold, bg: KLTheme.imdbGold.opacity(0.12), border: KLTheme.imdbGold.opacity(0.3))
                        KLPillBadge(text: "\(film.quality) · \(film.language)", fg: .white, bg: Color.white.opacity(0.10), border: .clear)
                        KLPillBadge(text: film.year, fg: KLTheme.textSecondary, bg: Color.white.opacity(0.06), border: .clear)
                        Spacer()
                    }

                    Text(film.name)
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white)

                    if !film.originalName.isEmpty {
                        Text(film.originalName)
                            .font(.system(size: 12.5, weight: .medium))
                            .foregroundColor(KLTheme.textMuted)
                    }

                    if !synopsis.isEmpty {
                        Text(synopsis)
                            .font(.system(size: 12.5, weight: .regular))
                            .foregroundColor(KLTheme.textSecondary)
                            .lineLimit(3)
                            .padding(.top, 2)
                    }
                }
                .padding(16)

                Divider()
                    .background(KLTheme.borderSubtle)

                if isLoading {
                    Spacer()
                    HStack {
                        Spacer()
                        ProgressView()
                            .tint(KLTheme.brandOrange)
                        Spacer()
                    }
                    Spacer()
                } else {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("DANH SÁCH TẬP (\(episodes.count))")
                                .font(.system(size: 11, weight: .heavy))
                                .tracking(0.8)
                                .foregroundColor(KLTheme.textMuted)

                            LazyVGrid(columns: [
                                GridItem(.flexible(), spacing: 10),
                                GridItem(.flexible(), spacing: 10),
                                GridItem(.flexible(), spacing: 10)
                            ], spacing: 10) {
                                ForEach(episodes) { ep in
                                    Button {
                                        dismiss()
                                        onSelectEpisode(ep)
                                    } label: {
                                        Text(ep.name)
                                            .font(.system(size: 13, weight: .bold))
                                            .foregroundColor(.white)
                                            .frame(maxWidth: .infinity)
                                            .padding(.vertical, 12)
                                            .background(KLTheme.surfaceCard)
                                            .cornerRadius(10)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 10)
                                                    .stroke(KLTheme.borderSubtle, lineWidth: 0.8)
                                            )
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                        .padding(16)
                    }
                }
            }
        }
        .task {
            isLoading = true
            let detail = await PhimService.shared.fetchFilmDetail(slug: film.slug)
            synopsis = detail.description.isEmpty ? (film.description ?? "") : detail.description
            episodes = detail.episodes
            isLoading = false
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }
}
