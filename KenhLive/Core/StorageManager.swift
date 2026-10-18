import Foundation

final class StorageManager: ObservableObject {
    static let shared = StorageManager()

    private let defaults = UserDefaults.standard
    private let keyHistory = "kl_watch_history_v1"
    private let keyFavFilms = "kl_fav_films_v1"
    private let keyFavChannels = "kl_fav_channels_v1"

    @Published var watchHistory: [WatchProgress] = []
    @Published var favoriteFilmSlugs: Set<String> = []
    @Published var favoriteChannelIds: Set<String> = []

    private init() {
        loadData()
    }

    private func loadData() {
        if let data = defaults.data(forKey: keyHistory),
           let list = try? JSONDecoder().decode([WatchProgress].self, from: data) {
            self.watchHistory = list
        }
        if let list = defaults.stringArray(forKey: keyFavFilms) {
            self.favoriteFilmSlugs = Set(list)
        }
        if let list = defaults.stringArray(forKey: keyFavChannels) {
            self.favoriteChannelIds = Set(list)
        }
    }

    func extractEpisodeNumber(from text: String) -> Int? {
        let digits = text.components(separatedBy: CharacterSet.decimalDigits.inverted).filter { !$0.isEmpty }
        if let last = digits.last, let n = Int(last) {
            return n
        }
        return nil
    }

    func saveWatchProgress(_ progress: WatchProgress) {
        // Lưu riêng cho từng tập của bộ phim (theo filmSlug + episodeSlug / episodeName / episodeNumber)
        let progNum = extractEpisodeNumber(from: progress.episodeName.isEmpty ? progress.episodeSlug : progress.episodeName)
        var list = watchHistory.filter { item in
            if item.filmSlug != progress.filmSlug { return true }
            let sameSlug = !item.episodeSlug.isEmpty && item.episodeSlug.lowercased() == progress.episodeSlug.lowercased()
            let sameName = !item.episodeName.isEmpty && item.episodeName.lowercased() == progress.episodeName.lowercased()
            let sameId = item.id == progress.id
            let itemNum = extractEpisodeNumber(from: item.episodeName.isEmpty ? item.episodeSlug : item.episodeName)
            let sameNum = (progNum != nil && itemNum != nil && progNum == itemNum)
            return !(sameSlug || sameName || sameId || sameNum)
        }
        list.insert(progress, at: 0)
        if list.count > 100 { list = Array(list.prefix(100)) }
        watchHistory = list
        if let encoded = try? JSONEncoder().encode(list) {
            defaults.set(encoded, forKey: keyHistory)
        }
    }

    func getProgress(for filmSlug: String, episodeSlug: String? = nil, episodeName: String? = nil) -> WatchProgress? {
        let isSpecificEpisodeRequested = (episodeSlug != nil && !episodeSlug!.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty) ||
                                         (episodeName != nil && !episodeName!.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

        if isSpecificEpisodeRequested {
            let targetSlug = (episodeSlug ?? "").trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            let targetName = (episodeName ?? "").trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            let targetNum = extractEpisodeNumber(from: targetName.isEmpty ? targetSlug : targetName)

            // 1. Tìm tập khớp chính xác slug, name hoặc số tập
            if let match = watchHistory.first(where: { item in
                guard item.filmSlug == filmSlug else { return false }
                let itemSlug = item.episodeSlug.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
                let itemName = item.episodeName.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()

                if !targetSlug.isEmpty && itemSlug == targetSlug { return true }
                if !targetName.isEmpty && itemName == targetName { return true }

                if let tn = targetNum {
                    let itemNum = extractEpisodeNumber(from: itemName.isEmpty ? itemSlug : itemName)
                    if let `in` = itemNum, tn == `in` {
                        return true
                    }
                }
                return false
            }) {
                return match
            }

            // ĐÃ YÊU CẦU TẬP CỤ THỂ MÀ CHƯA XEM -> TRẢ VỀ NIL (TUYỆT ĐỐI KHÔNG FALLBACK SANG TẬP KHÁC)
            return nil
        }

        // CHỈ khi KHÔNG chỉ định tập (hasSpecificEpisode == false), mới trả về tập xem gần nhất của phim này để resume
        return watchHistory.first { $0.filmSlug == filmSlug }
    }

    func isEpisodeWatched(filmSlug: String, episodeSlug: String, episodeName: String = "") -> Bool {
        guard let prog = getProgress(for: filmSlug, episodeSlug: episodeSlug, episodeName: episodeName) else {
            return false
        }
        return prog.positionMs > 0
    }

    func toggleFavoriteFilm(slug: String) {
        if favoriteFilmSlugs.contains(slug) {
            favoriteFilmSlugs.remove(slug)
        } else {
            favoriteFilmSlugs.insert(slug)
        }
        defaults.set(Array(favoriteFilmSlugs), forKey: keyFavFilms)
    }

    func isFavoriteFilm(slug: String) -> Bool {
        favoriteFilmSlugs.contains(slug)
    }

    func toggleFavoriteChannel(id: String) {
        if favoriteChannelIds.contains(id) {
            favoriteChannelIds.remove(id)
        } else {
            favoriteChannelIds.insert(id)
        }
        defaults.set(Array(favoriteChannelIds), forKey: keyFavChannels)
    }

    func isFavoriteChannel(id: String) -> Bool {
        favoriteChannelIds.contains(id)
    }

    func clearWatchHistory() {
        watchHistory = []
        defaults.removeObject(forKey: keyHistory)
    }

    func removeWatchProgress(id: String) {
        watchHistory.removeAll { $0.id == id }
        if let encoded = try? JSONEncoder().encode(watchHistory) {
            defaults.set(encoded, forKey: keyHistory)
        }
    }

    func removeWatchProgress(filmSlug: String) {
        watchHistory.removeAll { $0.filmSlug == filmSlug }
        if let encoded = try? JSONEncoder().encode(watchHistory) {
            defaults.set(encoded, forKey: keyHistory)
        }
    }

    // MARK: - Consolidated Grouped History (1 bộ gộp vào 1 card duy nhất)
    var consolidatedWatchHistory: [ConsolidatedWatchItem] {
        var grouped: [String: [WatchProgress]] = [:]
        var order: [String] = []
        for item in watchHistory {
            if grouped[item.filmSlug] == nil {
                grouped[item.filmSlug] = []
                order.append(item.filmSlug)
            }
            grouped[item.filmSlug]?.append(item)
        }

        return order.compactMap { slug in
            guard let items = grouped[slug], let latest = items.first else { return nil }
            return ConsolidatedWatchItem(
                filmSlug: slug,
                filmName: latest.filmName,
                posterUrl: latest.posterUrl,
                latestEpisodeName: latest.episodeName,
                latestEpisodeSlug: latest.episodeSlug,
                latestProgress: latest,
                totalEpisodesWatched: items.count,
                progressPercent: latest.progressPercent,
                updatedAt: latest.updatedAt
            )
        }
    }

    func getFormattedCacheSize() -> String {
        let diskBytes = KLDiskImageCache.shared.diskUsageBytes()
        let urlBytes = Int64(URLCache.shared.currentDiskUsage)
        let total = diskBytes + urlBytes
        if total < 1024 * 1024 {
            return String(format: "%.1f KB", Double(max(0, total)) / 1024.0)
        } else if total < 1024 * 1024 * 1024 {
            return String(format: "%.1f MB", Double(total) / (1024.0 * 1024.0))
        } else {
            return String(format: "%.2f GB", Double(total) / (1024.0 * 1024.0 * 1024.0))
        }
    }

    func clearAllCaches() {
        URLCache.shared.removeAllCachedResponses()
        KLImageCache.shared.clear()
        KLDiskImageCache.shared.clear()
        PhimService.shared.clearMemoryCache()
    }
}

// MARK: - Consolidated Watch Item (1 Bộ Phim Tinh Gọn)
struct ConsolidatedWatchItem: Identifiable, Hashable {
    var id: String { filmSlug }
    let filmSlug: String
    let filmName: String
    let posterUrl: String
    let latestEpisodeName: String
    let latestEpisodeSlug: String
    let latestProgress: WatchProgress
    let totalEpisodesWatched: Int
    let progressPercent: Double
    let updatedAt: Date
}
