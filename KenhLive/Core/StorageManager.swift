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

    func saveWatchProgress(_ progress: WatchProgress) {
        // Lưu riêng cho từng tập của bộ phim (theo filmSlug + episodeSlug / episodeName)
        var list = watchHistory.filter { item in
            if item.filmSlug != progress.filmSlug { return true }
            let sameSlug = !item.episodeSlug.isEmpty && item.episodeSlug == progress.episodeSlug
            let sameName = !item.episodeName.isEmpty && item.episodeName == progress.episodeName
            let sameId = item.id == progress.id
            return !(sameSlug || sameName || sameId)
        }
        list.insert(progress, at: 0)
        if list.count > 60 { list = Array(list.prefix(60)) }
        watchHistory = list
        if let encoded = try? JSONEncoder().encode(list) {
            defaults.set(encoded, forKey: keyHistory)
        }
    }

    func getProgress(for filmSlug: String, episodeSlug: String? = nil, episodeName: String? = nil) -> WatchProgress? {
        if let epSlug = episodeSlug, !epSlug.isEmpty {
            if let match = watchHistory.first(where: { $0.filmSlug == filmSlug && $0.episodeSlug == epSlug }) {
                return match
            }
        }
        if let epName = episodeName, !epName.isEmpty {
            if let match = watchHistory.first(where: { $0.filmSlug == filmSlug && $0.episodeName == epName }) {
                return match
            }
        }
        // Nếu không chỉ định tập, trả về tập xem gần nhất của phim này
        return watchHistory.first { $0.filmSlug == filmSlug }
    }

    func isEpisodeWatched(filmSlug: String, episodeSlug: String, episodeName: String = "") -> Bool {
        watchHistory.contains { item in
            guard item.filmSlug == filmSlug else { return false }
            if !episodeSlug.isEmpty && item.episodeSlug == episodeSlug { return true }
            if !episodeName.isEmpty && item.episodeName == episodeName { return true }
            return false
        }
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
}
