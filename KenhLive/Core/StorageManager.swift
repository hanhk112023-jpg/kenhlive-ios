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
        var list = watchHistory.filter { $0.filmSlug != progress.filmSlug }
        list.insert(progress, at: 0)
        if list.count > 40 { list = Array(list.prefix(40)) }
        watchHistory = list
        if let encoded = try? JSONEncoder().encode(list) {
            defaults.set(encoded, forKey: keyHistory)
        }
    }

    func getProgress(for filmSlug: String) -> WatchProgress? {
        watchHistory.first { $0.filmSlug == filmSlug }
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
}
