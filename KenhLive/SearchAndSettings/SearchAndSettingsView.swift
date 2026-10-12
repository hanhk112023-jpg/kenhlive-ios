import SwiftUI

struct SearchAndSettingsView: View {
    @State private var searchKeyword: String = ""
    @State private var searchResults: [FilmItem] = []
    @State private var isSearching: Bool = false
    @State private var selectedFilm: FilmItem? = nil
    @State private var activePlayback: PhimView.ActiveVodPlayback? = nil

    @AppStorage("kl_stream_quality") private var selectedQuality: String = "Tự động (FHD)"
    @State private var isCacheCleared: Bool = false

    private let qualityOptions = ["Tự động (FHD)", "Cao (1080p)", "Ổn định (720p)"]

    var body: some View {
        ZStack {
            KLTheme.bgDeep.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 24) {
                    // Header
                    VStack(alignment: .leading, spacing: 2) {
                        Text("TÌM KIẾM & HỆ THỐNG")
                            .font(.system(size: 11, weight: .black, design: .rounded))
                            .tracking(1.8)
                            .foregroundColor(KLTheme.brandOrange)

                        Text("Tìm Kiếm & Cài Đặt")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(KLTheme.textPrimary)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 12)

                    // Unified Search Bar
                    HStack {
                        TextField("Tìm trận đấu, kênh TV, hoặc tên phim...", text: $searchKeyword)
                            .font(.system(size: 14.5, weight: .medium))
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .onSubmit {
                                Task { await performSearch() }
                            }

                        if !searchKeyword.isEmpty {
                            Button("XÓA") {
                                searchKeyword = ""
                                searchResults = []
                            }
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(KLTheme.textSecondary)
                            .padding(.trailing, 14)
                        }
                    }
                    .background(KLTheme.surfaceCard)
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(KLTheme.borderSubtle, lineWidth: 0.8)
                    )
                    .padding(.horizontal, 16)

                    // Search Results
                    if !searchResults.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            KLSectionHeader(
                                title: "Kết Quả Tìm Kiếm",
                                trailingText: "\(searchResults.count) KẾT QUẢ"
                            )

                            LazyVStack(spacing: 8) {
                                ForEach(searchResults) { film in
                                    Button {
                                        selectedFilm = film
                                    } label: {
                                        HStack(spacing: 12) {
                                            AsyncImage(url: URL(string: film.thumbUrl.isEmpty ? film.posterUrl : film.thumbUrl)) { phase in
                                                if let img = phase.image {
                                                    img.resizable().aspectRatio(contentMode: .fill)
                                                } else {
                                                    KLTheme.surfaceCard
                                                }
                                            }
                                            .frame(width: 48, height: 68)
                                            .cornerRadius(6)
                                            .clipped()

                                            VStack(alignment: .leading, spacing: 4) {
                                                Text(film.name)
                                                    .font(.system(size: 14.5, weight: .bold))
                                                    .foregroundColor(.white)
                                                    .lineLimit(1)

                                                Text("\(film.year) · \(film.quality) · \(film.language)")
                                                    .font(.system(size: 11.5, weight: .regular))
                                                    .foregroundColor(KLTheme.textSecondary)
                                            }

                                            Spacer()

                                            KLPillBadge(text: "XEM", fg: KLTheme.brandOrange, bg: KLTheme.brandOrange.opacity(0.12), border: .clear)
                                        }
                                        .padding(10)
                                        .background(KLTheme.surfaceCard)
                                        .cornerRadius(10)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding(.horizontal, 16)
                        }
                    }

                    // Settings Group 1: Stream Quality Preferences
                    VStack(alignment: .leading, spacing: 12) {
                        KLSectionHeader(title: "Chất Lượng Video Trực Tuyến")

                        VStack(spacing: 0) {
                            ForEach(Array(qualityOptions.enumerated()), id: \.offset) { index, opt in
                                Button {
                                    selectedQuality = opt
                                } label: {
                                    HStack {
                                        Text(opt)
                                            .font(.system(size: 14, weight: .medium))
                                            .foregroundColor(.white)

                                        Spacer()

                                        if selectedQuality == opt {
                                            Text("ĐANG CHỌN")
                                                .font(.system(size: 10, weight: .bold, design: .monospaced))
                                                .foregroundColor(KLTheme.brandOrange)
                                        }
                                    }
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 14)
                                }
                                .buttonStyle(.plain)

                                if index < qualityOptions.count - 1 {
                                    Divider().background(KLTheme.borderSubtle).padding(.horizontal, 16)
                                }
                            }
                        }
                        .background(KLTheme.surfaceCard)
                        .cornerRadius(14)
                        .padding(.horizontal, 16)
                    }

                    // Settings Group 2: App Data & Cache
                    VStack(alignment: .leading, spacing: 12) {
                        KLSectionHeader(title: "Dữ Liệu & Bộ Nhớ")

                        VStack(spacing: 0) {
                            Button {
                                clearCache()
                            } label: {
                                HStack {
                                    Text("Xóa bộ nhớ đệm (Cache)")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(.white)

                                    Spacer()

                                    Text(isCacheCleared ? "ĐÃ XÓA SẠCH" : "DỌN DẸP")
                                        .font(.system(size: 11, weight: .bold))
                                        .foregroundColor(isCacheCleared ? .green : KLTheme.textSecondary)
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 14)
                            }
                            .buttonStyle(.plain)

                            Divider().background(KLTheme.borderSubtle).padding(.horizontal, 16)

                            // Contact & Feedback
                            Link(destination: URL(string: "https://t.me/T990512S")!) {
                                HStack {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Liên hệ & Báo lỗi nhà phát triển")
                                            .font(.system(size: 14, weight: .medium))
                                            .foregroundColor(.white)

                                        Text("Telegram: @T990512S")
                                            .font(.system(size: 11, weight: .regular))
                                            .foregroundColor(KLTheme.textMuted)
                                    }

                                    Spacer()

                                    Text("MỞ")
                                        .font(.system(size: 11, weight: .bold))
                                        .foregroundColor(KLTheme.brandOrange)
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 14)
                            }
                            .buttonStyle(.plain)
                        }
                        .background(KLTheme.surfaceCard)
                        .cornerRadius(14)
                        .padding(.horizontal, 16)
                    }

                    // Version & Device Info
                    HStack {
                        Spacer()
                        VStack(spacing: 3) {
                            Text("KENHLIVE IOS · PHIÊN BẢN 1.0.0 (BẢN DỰNG 1)")
                                .font(.system(size: 10.5, weight: .bold, design: .monospaced))
                                .foregroundColor(KLTheme.textMuted)

                            Text("THIẾT KẾ DÀNH RIÊNG CHO IPHONE")
                                .font(.system(size: 9.5, weight: .medium, design: .monospaced))
                                .foregroundColor(KLTheme.textMuted.opacity(0.8))
                        }
                        Spacer()
                    }
                    .padding(.top, 10)
                    .padding(.bottom, 90)
                }
            }
        }
        .sheet(item: $selectedFilm) { film in
            EpisodePickerSheet(film: film) { ep in
                activePlayback = PhimView.ActiveVodPlayback(film: film, episode: ep)
            }
        }
        .fullScreenCover(item: $activePlayback) { item in
            VodWebPlayerView(film: item.film, episode: item.episode)
        }
    }

    private func performSearch() async {
        guard !searchKeyword.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        isSearching = true
        searchResults = await PhimService.shared.searchFilms(keyword: searchKeyword)
        isSearching = false
    }

    private func clearCache() {
        URLCache.shared.removeAllCachedResponses()
        isCacheCleared = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            isCacheCleared = false
        }
    }
}
