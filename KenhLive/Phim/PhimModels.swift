import Foundation

struct FilmItem: Identifiable, Codable, Hashable {
    var id: String { slug }
    let id_val: String?
    let name: String
    let slug: String
    let originalName: String
    let thumbUrl: String
    let posterUrl: String
    let currentEpisode: String
    let totalEpisodes: String
    let quality: String
    let language: String
    let year: String
    let time: String
    let director: String
    let casts: String
    let country: String
    let categories: [String]
    let description: String?
    let source: String

    init(
        id_val: String? = nil,
        name: String,
        slug: String,
        originalName: String = "",
        thumbUrl: String = "",
        posterUrl: String = "",
        currentEpisode: String = "Full",
        totalEpisodes: String = "",
        quality: String = "FHD",
        language: String = "Vietsub",
        year: String = "2026",
        time: String = "",
        director: String = "",
        casts: String = "",
        country: String = "",
        categories: [String] = [],
        description: String? = nil,
        source: String = "kkphim"
    ) {
        self.id_val = id_val
        self.name = name
        self.slug = slug
        self.originalName = originalName
        self.thumbUrl = thumbUrl
        self.posterUrl = posterUrl
        self.currentEpisode = currentEpisode
        self.totalEpisodes = totalEpisodes
        self.quality = quality
        self.language = language
        self.year = year
        self.time = time
        self.director = director
        self.casts = casts
        self.country = country
        self.categories = categories
        self.description = description
        self.source = source
    }

    enum CodingKeys: String, CodingKey {
        case id_val = "id"
        case name, slug
        case originalName = "original_name"
        case thumbUrl = "thumb_url"
        case posterUrl = "poster_url"
        case currentEpisode = "current_episode"
        case totalEpisodes = "total_episodes"
        case quality, language, year, time, director, casts, country
        case description
        case categories
        case source
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.id_val = try? c.decode(String.self, forKey: .id_val)
        self.name = (try? c.decode(String.self, forKey: .name)) ?? "Phim"
        self.slug = (try? c.decode(String.self, forKey: .slug)) ?? UUID().uuidString
        self.originalName = (try? c.decode(String.self, forKey: .originalName)) ?? ""
        self.thumbUrl = (try? c.decode(String.self, forKey: .thumbUrl)) ?? ""
        self.posterUrl = (try? c.decode(String.self, forKey: .posterUrl)) ?? ""
        self.currentEpisode = (try? c.decode(String.self, forKey: .currentEpisode)) ?? ""
        self.totalEpisodes = (try? c.decode(String.self, forKey: .totalEpisodes)) ?? ""
        self.quality = (try? c.decode(String.self, forKey: .quality)) ?? "FHD"
        self.language = (try? c.decode(String.self, forKey: .language)) ?? "Vietsub"
        self.year = (try? c.decode(String.self, forKey: .year)) ?? "2026"
        self.time = (try? c.decode(String.self, forKey: .time)) ?? ""
        self.director = (try? c.decode(String.self, forKey: .director)) ?? ""
        self.casts = (try? c.decode(String.self, forKey: .casts)) ?? ""
        self.country = (try? c.decode(String.self, forKey: .country)) ?? ""
        self.description = try? c.decode(String.self, forKey: .description)
        self.categories = (try? c.decode([String].self, forKey: .categories)) ?? []
        self.source = (try? c.decode(String.self, forKey: .source)) ?? "kkphim"
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encodeIfPresent(id_val, forKey: .id_val)
        try c.encode(name, forKey: .name)
        try c.encode(slug, forKey: .slug)
        try c.encode(originalName, forKey: .originalName)
        try c.encode(thumbUrl, forKey: .thumbUrl)
        try c.encode(posterUrl, forKey: .posterUrl)
        try c.encode(currentEpisode, forKey: .currentEpisode)
        try c.encode(totalEpisodes, forKey: .totalEpisodes)
        try c.encode(quality, forKey: .quality)
        try c.encode(language, forKey: .language)
        try c.encode(year, forKey: .year)
        try c.encode(time, forKey: .time)
        try c.encode(director, forKey: .director)
        try c.encode(casts, forKey: .casts)
        try c.encode(country, forKey: .country)
        try c.encodeIfPresent(description, forKey: .description)
        try c.encode(categories, forKey: .categories)
        try c.encode(source, forKey: .source)
    }

    var imdbScore: String {
        let sum = name.unicodeScalars.reduce(0) { ($0 &+ Int($1.value)) & 0x7FFF }
        let score = 8.4 + Double(sum % 13) / 10.0
        return String(format: "%.1f", score)
    }
}

struct PhimSection: Identifiable, Hashable {
    var id: String { title }
    let title: String
    let subtitle: String
    let films: [FilmItem]

    init(title: String, subtitle: String = "Điện ảnh chất lượng cao 4K", films: [FilmItem]) {
        self.title = title
        self.subtitle = subtitle
        self.films = films
    }
}

struct EpisodeServer: Identifiable, Hashable {
    var id: String { serverName }
    let serverName: String
    let episodes: [EpisodeItem]
}

struct EpisodeItem: Identifiable, Codable, Hashable {
    var id: String { "\(slug)_\(name)" }
    let name: String
    let slug: String
    let embed: String
    var m3u8: String = ""

    init(name: String, slug: String, embed: String, m3u8: String = "") {
        self.name = name
        self.slug = slug
        self.embed = embed
        self.m3u8 = m3u8
    }
}

struct FilmDetailResult {
    let description: String
    let director: String
    let casts: String
    let time: String
    let country: String
    let servers: [EpisodeServer]

    var allEpisodes: [EpisodeItem] {
        servers.first?.episodes ?? []
    }
}

struct WatchProgress: Identifiable, Codable, Hashable {
    var id: String { "\(filmSlug)_\(episodeSlug.isEmpty ? episodeName : episodeSlug)" }
    let filmSlug: String
    let filmName: String
    let posterUrl: String
    let episodeName: String
    let episodeSlug: String
    let embedUrl: String
    let m3u8Url: String
    let positionMs: Int64
    let durationMs: Int64
    let updatedAt: Date

    init(
        filmSlug: String,
        filmName: String,
        posterUrl: String,
        episodeName: String,
        episodeSlug: String,
        embedUrl: String,
        m3u8Url: String = "",
        positionMs: Int64 = 0,
        durationMs: Int64 = 0,
        updatedAt: Date = Date()
    ) {
        self.filmSlug = filmSlug
        self.filmName = filmName
        self.posterUrl = posterUrl
        self.episodeName = episodeName
        self.episodeSlug = episodeSlug
        self.embedUrl = embedUrl
        self.m3u8Url = m3u8Url
        self.positionMs = positionMs
        self.durationMs = durationMs
        self.updatedAt = updatedAt
    }

    var progressPercent: Double {
        guard durationMs > 0 else { return 0 }
        return min(1.0, max(0.0, Double(positionMs) / Double(durationMs)))
    }
}
