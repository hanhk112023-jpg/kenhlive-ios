import SwiftUI

struct PhimView: View {
    @ObservedObject private var storage = StorageManager.shared
    @State private var selectedFilter: String = "tat-ca"
    @State private var sections: [PhimSection] = []
    @State private var categoryFilms: [FilmItem] = []
    @State private var featuredFilms: [FilmItem] = []
    @State private var heroIndex: Int = 0
    @State private var heroSynopsis: String = ""
    @State private var isLoading: Bool = true

    // Search state
    @State private var searchQuery: String = ""
    @State private var searchResults: [FilmItem] = []
    @State private var isSearching: Bool = false
    @State private var searchTask: Task<Void, Never>? = nil

    private let trendingKeywords = [
        "One Piece",
        "Conan",
        "Ao no Hako",
        "Dan Da Dan",
        "Doraemon",
        "Dragon Ball",
        "Lật Mặt",
        "Tây Du Ký",
        "Naruto",
        "Solo Leveling",
        "Jujutsu Kaisen",
        "Bleach"
    ]

    @State private var selectedFilmForEpisodes: FilmItem? = nil
    @State private var initialResumeProgressForSheet: WatchProgress? = nil

    private let filterPills: [KLFilterItem<String>] = [
        KLFilterItem(id: "tat-ca", title: "Trang Chủ Phim"),
        KLFilterItem(id: "lich-su", title: "Đã Lưu & Xem Gần Đây"),
        KLFilterItem(id: "phim-moi", title: "Mới Cập Nhật"),
        KLFilterItem(id: "phim-bo", title: "Phim Bộ Hot"),
        KLFilterItem(id: "phim-le", title: "Phim Lẻ Chiếu Rạp"),
        KLFilterItem(id: "hoat-hinh", title: "Hoạt Hình & Anime"),
        KLFilterItem(id: "han-quoc", title: "Hàn Quốc"),
        KLFilterItem(id: "trung-quoc", title: "Trung Quốc"),
        KLFilterItem(id: "au-my", title: "Âu Mỹ Bom Tấn"),
        KLFilterItem(id: "hanh-dong", title: "Hành Động"),
        KLFilterItem(id: "co-trang", title: "Cổ Trang"),
        KLFilterItem(id: "tinh-cam", title: "Tình Cảm"),
        KLFilterItem(id: "kinh-di", title: "Kinh Dị")
    ]

    private var currentHero: FilmItem? {
        guard !featuredFilms.isEmpty else { return sections.first?.films.first }
        return featuredFilms[heroIndex % featuredFilms.count]
    }

    var body: some View {
        ZStack {
            KLTheme.bgDeep.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 18) {
                    // 1. Netflix Editorial Header Bar
                    HStack(alignment: .center) {
                        HStack(spacing: 8) {
                            Text("K")
                                .font(.system(size: 16, weight: .black, design: .rounded))
                                .foregroundColor(.white)
                                .frame(width: 25, height: 25)
                                .background(KLTheme.netflixRed)
                                .cornerRadius(5)

                            VStack(alignment: .leading, spacing: 1) {
                                Text("RẠP PHIM ĐIỆN ẢNH")
                                    .font(.system(size: 10, weight: .black, design: .rounded))
                                    .tracking(1.6)
                                    .foregroundColor(KLTheme.netflixRed)

                                Text("Kho Phim Netflix Cinema")
                                    .font(.system(size: 21, weight: .heavy))
                                    .foregroundColor(.white)
                            }
                        }

                        Spacer()

                        KLPillBadge(
                            text: "HLS 4K NATIVE",
                            fg: KLTheme.imdbGold,
                            bg: KLTheme.imdbGold.opacity(0.14),
                            border: KLTheme.imdbGold.opacity(0.4)
                        )
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 10)

                    // 2. Real-Time Cinema Search Bar
                    HStack(spacing: 10) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(KLTheme.textMuted)

                        TextField("Tìm tên phim, diễn viên, anime (Conan, Khánh Dư Niên...)", text: $searchQuery)
                            .font(.system(size: 13.5, weight: .medium))
                            .foregroundColor(.white)
                            .autocorrectionDisabled()
                            .textInputAutocapitalization(.never)
                            .onChange(of: searchQuery) { query in
                                performSearch(query: query)
                            }

                        if isSearching {
                            ProgressView()
                                .tint(KLTheme.netflixRed)
                                .scaleEffect(0.8)
                        } else if !searchQuery.isEmpty {
                            Button {
                                searchQuery = ""
                                searchResults = []
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.system(size: 14))
                                    .foregroundColor(KLTheme.textMuted)
                            }
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .background(KLTheme.surfaceCard)
                    .cornerRadius(10)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(searchQuery.isEmpty ? KLTheme.borderSubtle : KLTheme.netflixRed.opacity(0.6), lineWidth: 1)
                    )
                    .padding(.horizontal, 16)

                    // 2b. Trending Keywords Strip (Gợi Ý Bấm Nhanh Chuẩn Netflix)
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 7) {
                            Text("🔥")
                                .font(.system(size: 11))
                            ForEach(trendingKeywords, id: \.self) { kw in
                                let isSelected = searchQuery.lowercased() == kw.lowercased()
                                Button {
                                    KLHaptics.light()
                                    searchQuery = kw
                                    performSearch(query: kw)
                                } label: {
                                    Text(kw)
                                        .font(.system(size: 11.5, weight: isSelected ? .bold : .medium))
                                        .foregroundColor(isSelected ? .white : KLTheme.textSecondary)
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 5)
                                        .background(isSelected ? KLTheme.brandOrange : KLTheme.surfaceCard)
                                        .cornerRadius(12)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(isSelected ? Color.clear : KLTheme.borderSubtle, lineWidth: 0.8)
                                        )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal, 16)
                    }

                    // 3. Search Results Overlay OR Regular Cinema Catalog
                    if !searchQuery.trimmingCharacters(in: .whitespaces).isEmpty {
                        renderSearchResultsView()
                    } else {
                        renderMainCatalogView()
                    }

                    Spacer(minLength: 90)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .refreshable {
                await loadCategory(selectedFilter)
            }

            if isLoading && sections.isEmpty && categoryFilms.isEmpty {
                ProgressView()
                    .tint(KLTheme.netflixRed)
            }
        }
        .task {
            if sections.isEmpty {
                await loadCategory(selectedFilter)
            }
        }
        .sheet(item: $selectedFilmForEpisodes) { film in
            EpisodePickerSheet(
                film: film,
                initialResumeProgress: initialResumeProgressForSheet ?? storage.getProgress(for: film.slug)
            )
        }
    }

    // MARK: - Search Results View
    @ViewBuilder
    private func renderSearchResultsView() -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("KẾT QUẢ TÌM KIẾM")
                    .font(.system(size: 11, weight: .heavy))
                    .tracking(0.8)
                    .foregroundColor(KLTheme.textMuted)

                Spacer()

                Text("\(searchResults.count) PHIM")
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundColor(KLTheme.imdbGold)
            }
            .padding(.horizontal, 16)

            if searchResults.isEmpty && !isSearching {
                VStack(spacing: 12) {
                    Image(systemName: "film.stack")
                        .font(.system(size: 38))
                        .foregroundColor(KLTheme.textMuted)

                    Text("Không tìm thấy phim phù hợp với \"\(searchQuery)\"")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(KLTheme.textSecondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
            } else {
                LazyVGrid(columns: [
                    GridItem(.flexible(), spacing: 10),
                    GridItem(.flexible(), spacing: 10),
                    GridItem(.flexible(), spacing: 10)
                ], spacing: 14) {
                    ForEach(searchResults) { film in
                        Button {
                            KLHaptics.light()
                            selectedFilmForEpisodes = film
                        } label: {
                            PosterCell(film: film)
                        }
                        .buttonStyle(KLScaleButtonStyle())
                    }
                }
                .padding(.horizontal, 16)
            }
        }
    }

    // MARK: - Main Catalog View (Filter Strip, Hero, Continue Watching, Rails/Grid)
    @ViewBuilder
    private func renderMainCatalogView() -> some View {
        VStack(alignment: .leading, spacing: 18) {
            // Category Filter Strip
            KLFilterStrip(items: filterPills, selection: $selectedFilter)
                .onChange(of: selectedFilter) { newCat in
                    Task { await loadCategory(newCat) }
                }

            if selectedFilter == "tat-ca" {
                // Billboard Hero
                if let hero = currentHero {
                    NetflixBillboardHeroCard(
                        film: hero,
                        synopsis: heroSynopsis,
                        currentIndex: heroIndex,
                        totalCount: max(1, featuredFilms.count),
                        isFavorite: storage.isFavoriteFilm(slug: hero.slug),
                        onPlayNow: {
                            KLHaptics.medium()
                            initialResumeProgressForSheet = storage.getProgress(for: hero.slug)
                            selectedFilmForEpisodes = hero
                        },
                        onOpenEpisodes: {
                            KLHaptics.light()
                            initialResumeProgressForSheet = storage.getProgress(for: hero.slug)
                            selectedFilmForEpisodes = hero
                        },
                        onToggleFavorite: {
                            KLHaptics.selection()
                            storage.toggleFavoriteFilm(slug: hero.slug)
                        },
                        onCycleNext: {
                            KLHaptics.light()
                            if featuredFilms.count > 1 {
                                withAnimation(.spring(response: 0.32, dampingFraction: 0.82)) {
                                    heroIndex = (heroIndex + 1) % featuredFilms.count
                                }
                                Task { await loadHeroSynopsis() }
                            }
                        }
                    )
                }

                // Continue Watching Rail
                if !storage.watchHistory.isEmpty {
                    ContinueWatchingRail(items: storage.watchHistory) { item in
                        KLHaptics.medium()
                        let film = FilmItem(
                            name: item.filmName,
                            slug: item.filmSlug,
                            thumbUrl: item.posterUrl,
                            posterUrl: item.posterUrl
                        )
                        initialResumeProgressForSheet = item
                        selectedFilmForEpisodes = film
                    }
                }

                // Catalog Sections
                ForEach(sections) { section in
                    FilmSectionRow(
                        title: section.title,
                        subtitle: section.subtitle,
                        films: section.films,
                        watchHistory: storage.watchHistory,
                        onSelectFilm: { film in
                            KLHaptics.light()
                            selectedFilmForEpisodes = film
                        },
                        onSeeMore: {
                            KLHaptics.selection()
                            if section.title.contains("Mới") { selectedFilter = "phim-moi" }
                            else if section.title.contains("Bộ") { selectedFilter = "phim-bo" }
                            else if section.title.contains("Lẻ") { selectedFilter = "phim-le" }
                            else if section.title.contains("Hoạt Hình") { selectedFilter = "hoat-hinh" }
                            else if section.title.contains("Hàn Quốc") { selectedFilter = "han-quoc" }
                            else if section.title.contains("Trung Quốc") { selectedFilter = "trung-quoc" }
                            else if section.title.contains("Âu Mỹ") { selectedFilter = "au-my" }
                            else if section.title.contains("Hành Động") { selectedFilter = "hanh-dong" }
                        }
                    )
                }
            } else if selectedFilter == "lich-su" {
                // My List & History View
                renderMyListView()
            } else {
                // Filtered Grid View for specific category / country
                renderCategoryGridView()
            }
        }
    }

    // MARK: - Category Grid View
    @ViewBuilder
    private func renderCategoryGridView() -> some View {
        VStack(alignment: .leading, spacing: 12) {
            let title = filterPills.first(where: { $0.id == selectedFilter })?.title ?? "Danh Mục Phim"
            HStack {
                Text(title.uppercased())
                    .font(.system(size: 13, weight: .heavy))
                    .tracking(0.6)
                    .foregroundColor(.white)

                Spacer()

                Text("\(categoryFilms.count) PHIM")
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundColor(KLTheme.imdbGold)
            }
            .padding(.horizontal, 16)

            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 10),
                GridItem(.flexible(), spacing: 10),
                GridItem(.flexible(), spacing: 10)
            ], spacing: 14) {
                ForEach(categoryFilms) { film in
                    Button {
                        KLHaptics.light()
                        selectedFilmForEpisodes = film
                    } label: {
                        PosterCell(film: film)
                    }
                    .buttonStyle(KLScaleButtonStyle())
                }
            }
            .padding(.horizontal, 16)
        }
    }

    // MARK: - My List View
    @ViewBuilder
    private func renderMyListView() -> some View {
        VStack(alignment: .leading, spacing: 18) {
            if !storage.watchHistory.isEmpty {
                ContinueWatchingRail(items: storage.watchHistory) { item in
                    KLHaptics.medium()
                    let film = FilmItem(
                        name: item.filmName,
                        slug: item.filmSlug,
                        thumbUrl: item.posterUrl,
                        posterUrl: item.posterUrl
                    )
                    initialResumeProgressForSheet = item
                    selectedFilmForEpisodes = film
                }
            }

            let favSlugs = storage.favoriteFilmSlugs
            let allLoaded = (sections.flatMap { $0.films } + categoryFilms + featuredFilms)
            let favFilms = allLoaded.filter { favSlugs.contains($0.slug) }

            VStack(alignment: .leading, spacing: 12) {
                Text("PHIM ĐÃ LƯU TRONG DANH SÁCH (\(favSlugs.count))")
                    .font(.system(size: 11.5, weight: .heavy))
                    .tracking(0.8)
                    .foregroundColor(KLTheme.textMuted)
                    .padding(.horizontal, 16)

                if favFilms.isEmpty {
                    VStack(spacing: 10) {
                        Image(systemName: "bookmark")
                            .font(.system(size: 32))
                            .foregroundColor(KLTheme.textMuted)
                        Text("Chưa có phim nào được lưu vào danh sách")
                            .font(.system(size: 12.5, weight: .medium))
                            .foregroundColor(KLTheme.textSecondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 30)
                } else {
                    LazyVGrid(columns: [
                        GridItem(.flexible(), spacing: 10),
                        GridItem(.flexible(), spacing: 10),
                        GridItem(.flexible(), spacing: 10)
                    ], spacing: 14) {
                        ForEach(favFilms) { film in
                            Button {
                                KLHaptics.light()
                                selectedFilmForEpisodes = film
                            } label: {
                                PosterCell(film: film)
                            }
                            .buttonStyle(KLScaleButtonStyle())
                        }
                    }
                    .padding(.horizontal, 16)
                }
            }
        }
    }

    // MARK: - Logic Helpers
    private func performSearch(query: String) {
        searchTask?.cancel()
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            searchResults = []
            isSearching = false
            return
        }

        isSearching = true
        searchTask = Task {
            try? await Task.sleep(nanoseconds: 350_000_000)
            guard !Task.isCancelled else { return }
            let results = await PhimService.shared.searchFilms(keyword: trimmed)
            if !Task.isCancelled {
                searchResults = results
                isSearching = false
            }
        }
    }

    private func loadCategory(_ slug: String) async {
        isLoading = true
        if slug == "tat-ca" {
            // Stage 1: Fast initial load (First 2 shelves ~200ms)
            let initial = await PhimService.shared.fetchQuickInitialSections()
            if !initial.isEmpty {
                sections = initial
                featuredFilms = Array((initial.first?.films ?? []).prefix(10))
                heroIndex = 0
                isLoading = false // Show screen immediately!
            }

            // Stage 2: Concurrently fetch full shelves and append
            let full = await PhimService.shared.fetchHomeSections()
            if !full.isEmpty {
                sections = full
                if featuredFilms.isEmpty {
                    featuredFilms = Array((full.first?.films ?? []).prefix(10))
                }
            }
            isLoading = false
            Task { await loadHeroSynopsis() }
        } else if slug == "lich-su" {
            isLoading = false
        } else {
            let list = await PhimService.shared.fetchCategoryFilms(slug: slug)
            categoryFilms = list
            isLoading = false
        }
    }

    private func loadHeroSynopsis() async {
        guard let hero = currentHero else { return }
        heroSynopsis = hero.description ?? ""
        let detail = await PhimService.shared.fetchFilmDetail(slug: hero.slug)
        if !detail.description.isEmpty {
            heroSynopsis = detail.description
        }
    }
}

// MARK: - Poster Grid Cell (2:3 Aspect Ratio)
private struct PosterCell: View {
    let film: FilmItem

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            ZStack {
                AsyncImage(url: URL(string: film.posterUrl.isEmpty ? film.thumbUrl : film.posterUrl)) { phase in
                    if let img = phase.image {
                        img
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } else {
                        KLTheme.surfaceCard
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 155)
                .clipped()

                // Corner Badges Overlay
                VStack {
                    HStack {
                        Text("★ \(film.imdbScore)")
                            .font(.system(size: 9, weight: .heavy, design: .rounded))
                            .foregroundColor(KLTheme.imdbGold)
                            .padding(.horizontal, 4.5)
                            .padding(.vertical, 2)
                            .background(Color.black.opacity(0.80))
                            .cornerRadius(3.5)

                        Spacer()

                        Text(film.quality)
                            .font(.system(size: 8.5, weight: .black))
                            .foregroundColor(.white)
                            .padding(.horizontal, 4.5)
                            .padding(.vertical, 2)
                            .background(KLTheme.netflixRed)
                            .cornerRadius(3.5)
                    }
                    .padding(5)

                    Spacer()

                    HStack {
                        Text(film.currentEpisode.isEmpty ? "Full" : film.currentEpisode)
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 5)
                            .padding(.vertical, 2)
                            .background(Color.black.opacity(0.80))
                            .cornerRadius(3.5)
                        Spacer()
                    }
                    .padding(5)
                }
            }
            .frame(height: 155)
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.white.opacity(0.12), lineWidth: 0.8)
            )

            Text(film.name)
                .font(.system(size: 11.5, weight: .bold))
                .foregroundColor(.white)
                .lineLimit(1)

            Text("\(film.year) · \(film.language)")
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(KLTheme.textMuted)
                .lineLimit(1)
        }
    }
}

// MARK: - Netflix Cinema Billboard Hero Card
private struct NetflixBillboardHeroCard: View {
    let film: FilmItem
    let synopsis: String
    let currentIndex: Int
    let totalCount: Int
    let isFavorite: Bool
    let onPlayNow: () -> Void
    let onOpenEpisodes: () -> Void
    let onToggleFavorite: () -> Void
    let onCycleNext: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Spacer(minLength: 40)

            // Row 1: Netflix Series Brand Identifier + Index
            HStack(spacing: 7) {
                Text("K")
                    .font(.system(size: 11, weight: .black, design: .rounded))
                    .foregroundColor(.white)
                    .padding(.horizontal, 5)
                    .padding(.vertical, 2)
                    .background(KLTheme.netflixRed)
                    .cornerRadius(3)

                Text("B O M  T Ấ N  Đ I Ệ N  Ả N H")
                    .font(.system(size: 9.5, weight: .heavy, design: .rounded))
                    .foregroundColor(Color.white.opacity(0.85))

                Spacer()

                if totalCount > 1 {
                    Text("\(currentIndex + 1)/\(totalCount)")
                        .font(.system(size: 10.5, weight: .bold, design: .monospaced))
                        .foregroundColor(KLTheme.textSecondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Color.black.opacity(0.65))
                        .cornerRadius(5)
                }
            }

            // Row 2: Movie Title
            Text(film.name)
                .font(.system(size: 22, weight: .black))
                .foregroundColor(.white)
                .lineLimit(2)
                .shadow(color: .black.opacity(0.9), radius: 6, x: 0, y: 2)

            // Row 3: Netflix Metadata Bar
            HStack(spacing: 8) {
                Text("98% Phù Hợp")
                    .font(.system(size: 12, weight: .heavy))
                    .foregroundColor(KLTheme.netflixGreen)

                Text(film.year)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(Color.white.opacity(0.85))

                Text("16+")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 5)
                    .padding(.vertical, 1.5)
                    .overlay(
                        RoundedRectangle(cornerRadius: 3)
                            .stroke(Color.white.opacity(0.45), lineWidth: 1)
                    )

                Text(film.quality)
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 5)
                    .padding(.vertical, 1.5)
                    .background(Color.white.opacity(0.14))
                    .cornerRadius(3)

                Text("★ \(film.imdbScore)")
                    .font(.system(size: 11.5, weight: .heavy))
                    .foregroundColor(KLTheme.imdbGold)
            }

            // Row 4: Netflix TOP 10 Rank Badge
            HStack(spacing: 7) {
                Text("TOP 10")
                    .font(.system(size: 9.5, weight: .black))
                    .foregroundColor(.white)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2.5)
                    .background(KLTheme.netflixRed)
                    .cornerRadius(4)

                Text("Số #\(currentIndex + 1) trong Phim Thịnh Hành Hôm Nay")
                    .font(.system(size: 11.5, weight: .bold))
                    .foregroundColor(.white)
                    .lineLimit(1)
            }

            // Row 5: Synopsis
            Text(synopsis.isEmpty ? "\(film.originalName.isEmpty ? film.name : film.originalName) — Trải nghiệm điện ảnh sắc nét chuẩn Netflix 4K Vietsub & Thuyết minh trên KenhLive." : synopsis)
                .font(.system(size: 12, weight: .regular))
                .foregroundColor(Color.white.opacity(0.78))
                .lineLimit(2)

            // Row 6: Netflix Action Buttons
            HStack(spacing: 8) {
                Button(action: onPlayNow) {
                    HStack(spacing: 6) {
                        Text("▶")
                            .font(.system(size: 12, weight: .black))
                        Text("XEM NGAY")
                            .font(.system(size: 12.5, weight: .black))
                            .tracking(0.4)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10.5)
                    .foregroundColor(.black)
                    .background(Color.white)
                    .cornerRadius(8)
                }
                .buttonStyle(KLScaleButtonStyle())

                Button(action: onOpenEpisodes) {
                    Text("ℹ CHỌN TẬP")
                        .font(.system(size: 11.5, weight: .bold))
                        .padding(.horizontal, 13)
                        .padding(.vertical, 10.5)
                        .foregroundColor(.white)
                        .background(Color.white.opacity(0.18))
                        .cornerRadius(8)
                }
                .buttonStyle(KLScaleButtonStyle())

                Button(action: onToggleFavorite) {
                    Text(isFavorite ? "✓ ĐÃ LƯU" : "+ LƯU")
                        .font(.system(size: 11, weight: .bold))
                        .padding(.horizontal, 11)
                        .padding(.vertical, 10.5)
                        .foregroundColor(isFavorite ? KLTheme.imdbGold : .white)
                        .background(Color.white.opacity(0.14))
                        .cornerRadius(8)
                }
                .buttonStyle(KLScaleButtonStyle())

                if totalCount > 1 {
                    Button(action: onCycleNext) {
                        Text("↻")
                            .font(.system(size: 13, weight: .black))
                            .padding(.horizontal, 11)
                            .padding(.vertical, 9.5)
                            .foregroundColor(.white)
                            .background(Color.white.opacity(0.14))
                            .cornerRadius(8)
                    }
                    .buttonStyle(KLScaleButtonStyle())
                }
            }
            .padding(.top, 4)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            ZStack {
                AsyncImage(url: URL(string: film.posterUrl.isEmpty ? film.thumbUrl : film.posterUrl)) { phase in
                    if let image = phase.image {
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } else {
                        LinearGradient(
                            colors: [Color(red: 0.25, green: 0.05, blue: 0.10), KLTheme.bgDeep],
                            startPoint: .topTrailing,
                            endPoint: .bottomLeading
                        )
                    }
                }

                LinearGradient(
                    colors: [
                        KLTheme.bgDeep.opacity(0.10),
                        KLTheme.bgDeep.opacity(0.55),
                        KLTheme.bgDeep.opacity(0.92),
                        KLTheme.bgDeep
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            }
        )
        .cornerRadius(18)
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(Color.white.opacity(0.14), lineWidth: 1)
        )
        .clipped()
        .padding(.horizontal, 16)
    }
}

// MARK: - Continue Watching Rail
private struct ContinueWatchingRail: View {
    let items: [WatchProgress]
    let onTap: (WatchProgress) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 11) {
            KLSectionHeader(
                title: "Tiếp Tục Xem",
                subtitle: "Khôi phục ngay tập phim đang xem dở",
                trailingText: "\(items.count) PHIM",
                accentColor: KLTheme.netflixRed
            )

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(items) { item in
                        Button {
                            onTap(item)
                        } label: {
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Text("▶ TIẾP TỤC")
                                        .font(.system(size: 9.5, weight: .black))
                                        .foregroundColor(KLTheme.netflixRed)
                                    Spacer()
                                    Text("\(Int(item.progressPercent * 100))%")
                                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                                        .foregroundColor(KLTheme.textSecondary)
                                }

                                Text(item.filmName)
                                    .font(.system(size: 13.5, weight: .bold))
                                    .foregroundColor(.white)
                                    .lineLimit(1)

                                Text(item.episodeName)
                                    .font(.system(size: 11, weight: .medium))
                                    .foregroundColor(KLTheme.textSecondary)

                                GeometryReader { geo in
                                    ZStack(alignment: .leading) {
                                        Capsule()
                                            .fill(Color.white.opacity(0.16))
                                            .frame(height: 4)
                                        Capsule()
                                            .fill(KLTheme.netflixRed)
                                            .frame(width: geo.size.width * max(0.08, item.progressPercent), height: 4)
                                    }
                                }
                                .frame(height: 4)
                            }
                            .padding(14)
                            .frame(width: 220)
                            .background(KLTheme.surfaceCard)
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(KLTheme.borderSubtle, lineWidth: 0.8)
                            )
                        }
                        .buttonStyle(KLScaleButtonStyle())
                    }
                }
                .padding(.horizontal, 16)
            }
        }
    }
}

// MARK: - Horizontal Film Section Row
private struct FilmSectionRow: View {
    let title: String
    let subtitle: String
    let films: [FilmItem]
    let watchHistory: [WatchProgress]
    let onSelectFilm: (FilmItem) -> Void
    var onSeeMore: (() -> Void)? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 7) {
                        Rectangle()
                            .fill(KLTheme.netflixRed)
                            .frame(width: 3.5, height: 14)
                            .cornerRadius(2)

                        Text(title)
                            .font(.system(size: 15, weight: .heavy))
                            .foregroundColor(.white)
                    }

                    Text(subtitle)
                        .font(.system(size: 10.5, weight: .medium))
                        .foregroundColor(KLTheme.textMuted)
                }

                Spacer()

                if let onSeeMore = onSeeMore {
                    Button(action: onSeeMore) {
                        Text("Tất cả ›")
                            .font(.system(size: 11.5, weight: .bold))
                            .foregroundColor(KLTheme.textSecondary)
                    }
                }
            }
            .padding(.horizontal, 16)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(films) { film in
                        let progress = watchHistory.first(where: { $0.filmSlug == film.slug })?.progressPercent ?? 0

                        Button {
                            onSelectFilm(film)
                        } label: {
                            VStack(alignment: .leading, spacing: 6) {
                                ZStack {
                                    AsyncImage(url: URL(string: film.posterUrl.isEmpty ? film.thumbUrl : film.posterUrl)) { phase in
                                        if let img = phase.image {
                                            img
                                                .resizable()
                                                .aspectRatio(contentMode: .fill)
                                        } else {
                                            KLTheme.surfaceCard
                                        }
                                    }
                                    .frame(width: 125, height: 185)
                                    .clipped()

                                    // Gradient Scrim
                                    VStack {
                                        Spacer()
                                        LinearGradient(
                                            colors: [.clear, Color.black.opacity(0.85)],
                                            startPoint: .top,
                                            endPoint: .bottom
                                        )
                                        .frame(height: 50)
                                    }

                                    // Overlay Badges
                                    VStack {
                                        HStack {
                                            Text("★ \(film.imdbScore)")
                                                .font(.system(size: 9, weight: .heavy, design: .rounded))
                                                .foregroundColor(KLTheme.imdbGold)
                                                .padding(.horizontal, 4.5)
                                                .padding(.vertical, 2)
                                                .background(Color.black.opacity(0.78))
                                                .cornerRadius(3.5)

                                            Spacer()

                                            Text(film.quality)
                                                .font(.system(size: 8.5, weight: .black))
                                                .foregroundColor(.white)
                                                .padding(.horizontal, 4.5)
                                                .padding(.vertical, 2)
                                                .background(KLTheme.netflixRed)
                                                .cornerRadius(3.5)
                                        }
                                        .padding(5)

                                        Spacer()

                                        HStack {
                                            Text(film.currentEpisode.isEmpty ? "Full" : film.currentEpisode)
                                                .font(.system(size: 9, weight: .bold))
                                                .foregroundColor(.white)
                                                .padding(.horizontal, 5)
                                                .padding(.vertical, 2)
                                                .background(Color.black.opacity(0.78))
                                                .cornerRadius(3.5)
                                            Spacer()
                                        }
                                        .padding(.horizontal, 5)
                                        .padding(.bottom, progress > 0 ? 7 : 5)

                                        if progress > 0 {
                                            GeometryReader { geo in
                                                ZStack(alignment: .leading) {
                                                    Rectangle()
                                                        .fill(Color.white.opacity(0.25))
                                                        .frame(height: 3)
                                                    Rectangle()
                                                        .fill(KLTheme.netflixRed)
                                                        .frame(width: geo.size.width * max(0.1, progress), height: 3)
                                                }
                                            }
                                            .frame(height: 3)
                                        }
                                    }
                                }
                                .frame(width: 125, height: 185)
                                .cornerRadius(10)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(Color.white.opacity(0.12), lineWidth: 0.8)
                                )

                                Text(film.name)
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(.white)
                                    .lineLimit(1)
                                    .frame(width: 125, alignment: .leading)

                                Text("\(film.year) · \(film.language)")
                                    .font(.system(size: 10, weight: .medium))
                                    .foregroundColor(KLTheme.textMuted)
                                    .lineLimit(1)
                                    .frame(width: 125, alignment: .leading)
                            }
                            .frame(width: 125)
                        }
                        .buttonStyle(KLScaleButtonStyle())
                    }
                }
                .padding(.horizontal, 16)
            }
        }
    }
}

private struct RotatedCardBorderModifier: View {
    var body: some View {
        EmptyView()
    }
}
