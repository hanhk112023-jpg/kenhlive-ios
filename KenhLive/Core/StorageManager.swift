import Foundation

final class StorageManager: ObservableObject {
    static let shared = StorageManager()

    private let defaults = UserDefaults.standard
    private let keyHistory = "kl_watch_history_v1"
    private let keyWatchedEpisodes = "kl_watched_episode_keys_v1"
    private let keyFavFilms = "kl_fav_films_v1"
    private let keyFavChannels = "kl_fav_channels_v1"

    @Published var watchHistory: [WatchProgress] = []
    @Published var watchedEpisodeKeys: Set<String> = []
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
        if let list = defaults.stringArray(forKey: keyWatchedEpisodes) {
            self.watchedEpisodeKeys = Set(list)
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

    // MARK: - Save Watch Progress (Chỉ lưu duy nhất 1 tập xem gần nhất cho mỗi bộ phim)
    func saveWatchProgress(_ progress: WatchProgress) {
        // 1. Đánh dấu tập này vào tập hợp các tập đã xem
        let epSlugKey = "\(progress.filmSlug):\(progress.episodeSlug.trimmingCharacters(in: .whitespacesAndNewlines).lowercased())"
        watchedEpisodeKeys.insert(epSlugKey)
        if !progress.episodeName.isEmpty {
            let epNameKey = "\(progress.filmSlug):\(progress.episodeName.trimmingCharacters(in: .whitespacesAndNewlines).lowercased())"
            watchedEpisodeKeys.insert(epNameKey)
        }
        if let num = extractEpisodeNumber(from: progress.episodeName.isEmpty ? progress.episodeSlug : progress.episodeName) {
            watchedEpisodeKeys.insert("\(progress.filmSlug):ep_\(num)")
        }
        defaults.set(Array(watchedEpisodeKeys), forKey: keyWatchedEpisodes)

        // 2. CHỈ LƯU DUY NHẤT 1 TẬP XEM GẦN NHẤT cho bộ phim này trong watchHistory
        var finalProgress = progress
        if finalProgress.posterUrl.isEmpty, let old = watchHistory.first(where: { $0.filmSlug == progress.filmSlug }), !old.posterUrl.isEmpty {
            finalProgress = WatchProgress(
                filmSlug: progress.filmSlug,
                filmName: progress.filmName,
                posterUrl: old.posterUrl,
                episodeName: progress.episodeName,
                episodeSlug: progress.episodeSlug,
                embedUrl: progress.embedUrl,
                m3u8Url: progress.m3u8Url,
                positionMs: progress.positionMs,
                durationMs: progress.durationMs,
                updatedAt: progress.updatedAt
            )
        }
        var list = watchHistory.filter { $0.filmSlug != progress.filmSlug }
        list.insert(finalProgress, at: 0)
        if list.count > 60 { list = Array(list.prefix(60)) }
        watchHistory = list
        if let encoded = try? JSONEncoder().encode(list) {
            defaults.set(encoded, forKey: keyHistory)
        }
    }

    func getProgress(for filmSlug: String, episodeSlug: String? = nil, episodeName: String? = nil) -> WatchProgress? {
        guard let latest = watchHistory.first(where: { $0.filmSlug == filmSlug }) else {
            return nil
        }
        let isSpecific = (episodeSlug != nil && !episodeSlug!.isEmpty) || (episodeName != nil && !episodeName!.isEmpty)
        if isSpecific {
            if isLatestWatchedEpisode(filmSlug: filmSlug, episodeSlug: episodeSlug ?? "", episodeName: episodeName ?? "") {
                return latest
            }
            return nil
        }
        return latest
    }

    // Kiểm tra xem tập này có phải là tập xem gần nhất không (để hiện thanh tiến độ resume)
    func isLatestWatchedEpisode(filmSlug: String, episodeSlug: String, episodeName: String = "") -> Bool {
        guard let latest = watchHistory.first(where: { $0.filmSlug == filmSlug }) else { return false }
        let targetSlug = episodeSlug.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let targetName = episodeName.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let latestSlug = latest.episodeSlug.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let latestName = latest.episodeName.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()

        if !targetSlug.isEmpty && latestSlug == targetSlug { return true }
        if !targetName.isEmpty && latestName == targetName { return true }

        let n1 = extractEpisodeNumber(from: targetName.isEmpty ? targetSlug : targetName)
        let n2 = extractEpisodeNumber(from: latestName.isEmpty ? latestSlug : latestName)
        return n1 != nil && n1 == n2
    }

    // Kiểm tra xem tập này đã từng được xem trong quá khứ chưa (để đổi sang màu xám mờ và icon tick xám)
    func isPreviouslyWatchedEpisode(filmSlug: String, episodeSlug: String, episodeName: String = "") -> Bool {
        if isLatestWatchedEpisode(filmSlug: filmSlug, episodeSlug: episodeSlug, episodeName: episodeName) {
            return false
        }
        let epSlugKey = "\(filmSlug):\(episodeSlug.trimmingCharacters(in: .whitespacesAndNewlines).lowercased())"
        let epNameKey = "\(filmSlug):\(episodeName.trimmingCharacters(in: .whitespacesAndNewlines).lowercased())"
        if watchedEpisodeKeys.contains(epSlugKey) || watchedEpisodeKeys.contains(epNameKey) {
            return true
        }
        if let num = extractEpisodeNumber(from: episodeName.isEmpty ? episodeSlug : episodeName) {
            if watchedEpisodeKeys.contains("\(filmSlug):ep_\(num)") {
                return true
            }
        }
        return false
    }

    func isEpisodeWatched(filmSlug: String, episodeSlug: String, episodeName: String = "") -> Bool {
        return isLatestWatchedEpisode(filmSlug: filmSlug, episodeSlug: episodeSlug, episodeName: episodeName) ||
               isPreviouslyWatchedEpisode(filmSlug: filmSlug, episodeSlug: episodeSlug, episodeName: episodeName)
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
        watchedEpisodeKeys = []
        defaults.removeObject(forKey: keyHistory)
        defaults.removeObject(forKey: keyWatchedEpisodes)
    }

    func removeWatchProgress(id: String) {
        watchHistory.removeAll { $0.id == id }
        if let encoded = try? JSONEncoder().encode(watchHistory) {
            defaults.set(encoded, forKey: keyHistory)
        }
    }

    func removeWatchProgress(filmSlug: String) {
        watchHistory.removeAll { $0.filmSlug == filmSlug }
        watchedEpisodeKeys = watchedEpisodeKeys.filter { !$0.hasPrefix("\(filmSlug):") }
        if let encoded = try? JSONEncoder().encode(watchHistory) {
            defaults.set(encoded, forKey: keyHistory)
        }
        defaults.set(Array(watchedEpisodeKeys), forKey: keyWatchedEpisodes)
    }

    // MARK: - Consolidated Grouped History (1 bộ gộp vào 1 card duy nhất)
    var consolidatedWatchHistory: [ConsolidatedWatchItem] {
        return watchHistory.map { item in
            let pastCount = watchedEpisodeKeys.filter { $0.hasPrefix("\(item.filmSlug):") }.count
            return ConsolidatedWatchItem(
                filmSlug: item.filmSlug,
                filmName: item.filmName,
                posterUrl: item.posterUrl,
                latestEpisodeName: item.episodeName,
                latestEpisodeSlug: item.episodeSlug,
                latestProgress: item,
                totalEpisodesWatched: max(1, pastCount),
                progressPercent: item.progressPercent,
                updatedAt: item.updatedAt
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
