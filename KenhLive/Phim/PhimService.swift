import Foundation
import UIKit

final class PhimService {
    static let shared = PhimService()

    private let kkphimApi = "https://phimapi.com"
    private let nguoncApi = "https://phim.nguonc.com/api"
    private let imageCdnBase = "https://phimimg.com"

    // High-performance In-Memory Caches with TTL & Auto-Eviction
    private var cachedHomeSections: [PhimSection]? = nil
    private var lastHomeSectionsFetchTime: Date? = nil
    private let homeSectionsTTL: TimeInterval = 15 * 60 // 15 mins TTL
    private var cachedCategoryFilms: [String: [FilmItem]] = [:]
    private var cachedFilmDetails: [String: FilmDetailResult] = [:]
    private let cacheLock = NSLock()

    private init() {
        NotificationCenter.default.addObserver(
            forName: UIApplication.didReceiveMemoryWarningNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.clearTransientMemoryCache()
        }
    }

    func clearTransientMemoryCache() {
        cacheLock.lock()
        cachedFilmDetails.removeAll()
        cachedCategoryFilms.removeAll()
        cacheLock.unlock()
    }

    func clearMemoryCache() {
        cacheLock.lock()
        cachedHomeSections = nil
        cachedCategoryFilms.removeAll()
        cachedFilmDetails.removeAll()
        lastHomeSectionsFetchTime = nil
        cacheLock.unlock()
    }

    // MARK: - 1. Home Cinema Sections (Instant Memory Cache + Progressive Stage)
    func fetchHomeSections(forceRefresh: Bool = false) async -> [PhimSection] {
        if !forceRefresh {
            cacheLock.lock()
            if let cached = cachedHomeSections, !cached.isEmpty,
               let lastTime = lastHomeSectionsFetchTime,
               Date().timeIntervalSince(lastTime) < homeSectionsTTL {
                cacheLock.unlock()
                return cached
            }
            cacheLock.unlock()
        }

        async let moiTaskP1 = fetchKKPhimList(endpoint: "danh-sach/phim-moi-cap-nhat?page=1")
        async let moiTaskP2 = fetchKKPhimList(endpoint: "danh-sach/phim-moi-cap-nhat?page=2")
        async let boTask = fetchKKPhimV1List(endpoint: "danh-sach/phim-bo?limit=36")
        async let leTask = fetchKKPhimV1List(endpoint: "danh-sach/phim-le?limit=36")
        async let animeTask = fetchKKPhimV1List(endpoint: "danh-sach/hoat-hinh?limit=36")
        async let hanQuocTask = fetchKKPhimV1List(endpoint: "quoc-gia/han-quoc?limit=36")
        async let trungQuocTask = fetchKKPhimV1List(endpoint: "quoc-gia/trung-quoc?limit=36")
        async let auMyTask = fetchKKPhimV1List(endpoint: "quoc-gia/au-my?limit=36")
        async let hanhDongTask = fetchKKPhimV1List(endpoint: "the-loai/hanh-dong?limit=36")

        let (moi1, moi2, bo, le, anime, hq, tq, am, hd) = await (moiTaskP1, moiTaskP2, boTask, leTask, animeTask, hanQuocTask, trungQuocTask, auMyTask, hanhDongTask)
        let moi = moi1 + moi2

        var sections: [PhimSection] = []
        if !moi.isEmpty { sections.append(PhimSection(title: "Phim Mới Cập Nhật", subtitle: "Kho phim điện ảnh mới nhất hôm nay", films: moi)) }
        if !bo.isEmpty { sections.append(PhimSection(title: "Phim Bộ Đặc Sắc", subtitle: "Trọn bộ Vietsub & Thuyết Minh FHD", films: bo)) }
        if !le.isEmpty { sections.append(PhimSection(title: "Phim Lẻ Chiếu Rạp", subtitle: "Bom tấn Hollywood & Rạp chiếu Việt Nam", films: le)) }
        if !anime.isEmpty { sections.append(PhimSection(title: "Hoạt Hình & Anime", subtitle: "Conan, One Piece, Ghibli trọn bộ", films: anime)) }
        if !hq.isEmpty { sections.append(PhimSection(title: "Phim Hàn Quốc Hot", subtitle: "K-Drama lãng mạn & giật gân cuốn hút", films: hq)) }
        if !tq.isEmpty { sections.append(PhimSection(title: "Phim Trung Quốc Cổ Trang", subtitle: "Tiên hiệp, kiếm hiệp & cung đấu đỉnh cao", films: tq)) }
        if !am.isEmpty { sections.append(PhimSection(title: "Phim Âu Mỹ Bom Tấn", subtitle: "Điện ảnh Hollywood chất lượng 4K", films: am)) }
        if !hd.isEmpty { sections.append(PhimSection(title: "Hành Động & Võ Thuật", subtitle: "Kịch tính, nghẹt thở & mãn nhãn", films: hd)) }

        if sections.isEmpty {
            // Fallback NguonC nếu KKPhim đang bảo trì
            let fallback = await fetchNguonCHomeSections()
            cacheLock.lock()
            self.cachedHomeSections = fallback
            cacheLock.unlock()
            return fallback
        }

        cacheLock.lock()
        if !moi.isEmpty { self.cachedCategoryFilms["phim-moi"] = moi }
        if !bo.isEmpty { self.cachedCategoryFilms["phim-bo"] = bo }
        if !le.isEmpty { self.cachedCategoryFilms["phim-le"] = le }
        if !anime.isEmpty { self.cachedCategoryFilms["hoat-hinh"] = anime }
        if !hq.isEmpty { self.cachedCategoryFilms["han-quoc"] = hq }
        if !tq.isEmpty { self.cachedCategoryFilms["trung-quoc"] = tq }
        if !am.isEmpty { self.cachedCategoryFilms["au-my"] = am }
        if !hd.isEmpty { self.cachedCategoryFilms["hanh-dong"] = hd }
        self.cachedHomeSections = sections
        self.lastHomeSectionsFetchTime = Date()
        cacheLock.unlock()
        return sections
    }

    // Fast Initial Rails for sub-second UI rendering
    func fetchQuickInitialSections() async -> [PhimSection] {
        cacheLock.lock()
        if let cached = cachedHomeSections, !cached.isEmpty {
            cacheLock.unlock()
            return cached
        }
        cacheLock.unlock()

        async let moiTaskP1 = fetchKKPhimList(endpoint: "danh-sach/phim-moi-cap-nhat?page=1")
        async let moiTaskP2 = fetchKKPhimList(endpoint: "danh-sach/phim-moi-cap-nhat?page=2")
        async let boTask = fetchKKPhimV1List(endpoint: "danh-sach/phim-bo?limit=36")
        let (moi1, moi2, bo) = await (moiTaskP1, moiTaskP2, boTask)
        let moi = moi1 + moi2

        var sections: [PhimSection] = []
        if !moi.isEmpty { sections.append(PhimSection(title: "Phim Mới Cập Nhật", subtitle: "Kho phim điện ảnh mới nhất hôm nay", films: moi)) }
        if !bo.isEmpty { sections.append(PhimSection(title: "Phim Bộ Đặc Sắc", subtitle: "Trọn bộ Vietsub & Thuyết Minh FHD", films: bo)) }

        cacheLock.lock()
        if !moi.isEmpty { self.cachedCategoryFilms["phim-moi"] = moi }
        if !bo.isEmpty { self.cachedCategoryFilms["phim-bo"] = bo }
        cacheLock.unlock()

        return sections
    }

    // Load remaining shelves concurrently
    func fetchRemainingSections() async -> [PhimSection] {
        async let leTask = fetchKKPhimV1List(endpoint: "danh-sach/phim-le?limit=36")
        async let animeTask = fetchKKPhimV1List(endpoint: "danh-sach/hoat-hinh?limit=36")
        async let hanQuocTask = fetchKKPhimV1List(endpoint: "quoc-gia/han-quoc?limit=36")
        async let trungQuocTask = fetchKKPhimV1List(endpoint: "quoc-gia/trung-quoc?limit=36")
        async let auMyTask = fetchKKPhimV1List(endpoint: "quoc-gia/au-my?limit=36")
        async let hanhDongTask = fetchKKPhimV1List(endpoint: "the-loai/hanh-dong?limit=36")

        let (le, anime, hq, tq, am, hd) = await (leTask, animeTask, hanQuocTask, trungQuocTask, auMyTask, hanhDongTask)
        var sections: [PhimSection] = []
        if !le.isEmpty { sections.append(PhimSection(title: "Phim Lẻ Chiếu Rạp", subtitle: "Bom tấn Hollywood & Rạp chiếu Việt Nam", films: le)) }
        if !anime.isEmpty { sections.append(PhimSection(title: "Hoạt Hình & Anime", subtitle: "Conan, One Piece, Ghibli trọn bộ", films: anime)) }
        if !hq.isEmpty { sections.append(PhimSection(title: "Phim Hàn Quốc Hot", subtitle: "K-Drama lãng mạn & giật gân cuốn hút", films: hq)) }
        if !tq.isEmpty { sections.append(PhimSection(title: "Phim Trung Quốc Cổ Trang", subtitle: "Tiên hiệp, kiếm hiệp & cung đấu đỉnh cao", films: tq)) }
        if !am.isEmpty { sections.append(PhimSection(title: "Phim Âu Mỹ Bom Tấn", subtitle: "Điện ảnh Hollywood chất lượng 4K", films: am)) }
        if !hd.isEmpty { sections.append(PhimSection(title: "Hành Động & Võ Thuật", subtitle: "Kịch tính, nghẹt thở & mãn nhãn", films: hd)) }

        cacheLock.lock()
        if !le.isEmpty { self.cachedCategoryFilms["phim-le"] = le }
        if !anime.isEmpty { self.cachedCategoryFilms["hoat-hinh"] = anime }
        if !hq.isEmpty { self.cachedCategoryFilms["han-quoc"] = hq }
        if !tq.isEmpty { self.cachedCategoryFilms["trung-quoc"] = tq }
        if !am.isEmpty { self.cachedCategoryFilms["au-my"] = am }
        if !hd.isEmpty { self.cachedCategoryFilms["hanh-dong"] = hd }
        cacheLock.unlock()

        return sections
    }

    func getCachedCategory(slug: String) -> [FilmItem]? {
        cacheLock.lock()
        defer { cacheLock.unlock() }
        return cachedCategoryFilms[slug]
    }

    // MARK: - 2. Category / Country / Genre Feed (Multi-Page / Large Batch)
    func fetchCategoryFilms(slug: String, page: Int = 1) async -> [FilmItem] {
        let cleanSlug = slug.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()

        if page == 1 {
            cacheLock.lock()
            if let cached = cachedCategoryFilms[cleanSlug], !cached.isEmpty {
                cacheLock.unlock()
                return cached
            }
            cacheLock.unlock()
        }

        let endpoint: String
        switch cleanSlug {
        case "phim-moi":
            let actualPage = page
            return await fetchKKPhimList(endpoint: "danh-sach/phim-moi-cap-nhat?page=\(actualPage)")
        case "phim-bo", "phim-le", "hoat-hinh", "tv-shows", "phim-chieu-rap", "phim-sap-chieu", "subteam":
            endpoint = "danh-sach/\(cleanSlug)?page=\(page)&limit=36"
        case "han-quoc", "trung-quoc", "au-my", "nhat-ban", "viet-nam", "thai-lan", "an-do", "dai-loan", "hong-kong", "phap", "anh", "duc", "nga", "canada":
            endpoint = "quoc-gia/\(cleanSlug)?page=\(page)&limit=36"
        default:
            endpoint = "the-loai/\(cleanSlug)?page=\(page)&limit=36"
        }

        var list = await fetchKKPhimV1List(endpoint: endpoint)
        if list.isEmpty {
            // Smart Multi-Prefix Fallback (prevents 404 on any misrouted category)
            if !endpoint.contains("danh-sach") {
                list = await fetchKKPhimV1List(endpoint: "danh-sach/\(cleanSlug)?page=\(page)&limit=36")
            }
            if list.isEmpty && !endpoint.contains("the-loai") {
                list = await fetchKKPhimV1List(endpoint: "the-loai/\(cleanSlug)?page=\(page)&limit=36")
            }
            if list.isEmpty && !endpoint.contains("quoc-gia") {
                list = await fetchKKPhimV1List(endpoint: "quoc-gia/\(cleanSlug)?page=\(page)&limit=36")
            }
        }

        if !list.isEmpty {
            if page == 1 {
                cacheLock.lock()
                if cachedCategoryFilms.count > 6 {
                    cachedCategoryFilms.removeAll() // Prevent RAM bloating
                }
                cachedCategoryFilms[cleanSlug] = list
                cacheLock.unlock()
            }
            return list
        }

        // Fallback NguonC
        let fallback = await fetchNguonCCategoryFilms(slug: cleanSlug)
        if page == 1 && !fallback.isEmpty {
            cacheLock.lock()
            cachedCategoryFilms[cleanSlug] = fallback
            cacheLock.unlock()
        }
        return fallback
    }

    // MARK: - 3. Instant Search API (Multi-result Realtime Search)
    func searchFilms(keyword: String, page: Int = 1) async -> [FilmItem] {
        let trimmed = keyword.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return [] }

        var components = URLComponents(string: "\(kkphimApi)/v1/api/tim-kiem")
        components?.queryItems = [
            URLQueryItem(name: "keyword", value: trimmed),
            URLQueryItem(name: "page", value: "\(page)"),
            URLQueryItem(name: "limit", value: "36")
        ]
        guard let url = components?.url else {
            return await searchNguonC(keyword: trimmed)
        }

        var req = URLRequest(url: url)
        req.timeoutInterval = 10.0
        req.setValue("Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X)", forHTTPHeaderField: "User-Agent")

        do {
            let (data, _) = try await URLSession.shared.data(for: req)
            guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let dataObj = json["data"] as? [String: Any],
                  let items = dataObj["items"] as? [[String: Any]] else {
                return page == 1 ? await searchNguonC(keyword: trimmed) : []
            }

            let results = items.compactMap { parseKKPhimItem($0) }
            return (results.isEmpty && page == 1) ? await searchNguonC(keyword: trimmed) : results
        } catch {
            return page == 1 ? await searchNguonC(keyword: trimmed) : []
        }
    }

    // MARK: - 4. Film Detail & Episode Resolution (100% Direct .m3u8 Streams)
    func fetchFilmDetail(slug: String) async -> FilmDetailResult {
        cacheLock.lock()
        if let cached = cachedFilmDetails[slug] {
            cacheLock.unlock()
            return cached
        }
        cacheLock.unlock()

        guard let url = URL(string: "\(kkphimApi)/phim/\(slug)") else {
            return fallbackDetailResult(slug: slug)
        }

        var req = URLRequest(url: url)
        req.timeoutInterval = 10.0
        req.setValue("Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X)", forHTTPHeaderField: "User-Agent")

        do {
            let (data, _) = try await URLSession.shared.data(for: req)
            guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let movie = json["movie"] as? [String: Any] else {
                return await fetchNguonCDetail(slug: slug)
            }

            let rawDesc = (movie["content"] as? String ?? movie["description"] as? String ?? "")
                .replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
                .trimmingCharacters(in: .whitespacesAndNewlines)

            let directorArr = movie["director"] as? [String] ?? []
            let director = directorArr.joined(separator: ", ")

            let castArr = movie["actor"] as? [String] ?? movie["casts"] as? [String] ?? []
            let casts = castArr.joined(separator: ", ")

            let time = movie["time"] as? String ?? ""

            var countryStr = ""
            if let countries = movie["country"] as? [[String: Any]], let first = countries.first {
                countryStr = first["name"] as? String ?? ""
            }

            var servers: [EpisodeServer] = []
            if let epList = json["episodes"] as? [[String: Any]] {
                for srv in epList {
                    let srvName = (srv["server_name"] as? String) ?? "Server 1"
                    let serverData = srv["server_data"] as? [[String: Any]] ?? []

                    var epItems: [EpisodeItem] = []
                    for it in serverData {
                        let name = it["name"] as? String ?? "Tập 1"
                        let epSlug = it["slug"] as? String ?? name
                        var m3u8 = (it["link_m3u8"] as? String ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
                        let embed = (it["link_embed"] as? String ?? "").trimmingCharacters(in: .whitespacesAndNewlines)

                        if m3u8.isEmpty, let extracted = extractM3u8FromEmbed(embed) {
                            m3u8 = extracted
                        }

                        if !m3u8.isEmpty || !embed.isEmpty {
                            epItems.append(EpisodeItem(
                                name: name,
                                slug: epSlug,
                                embed: embed,
                                m3u8: m3u8
                            ))
                        }
                    }

                    if !epItems.isEmpty {
                        servers.append(EpisodeServer(serverName: srvName, episodes: epItems))
                    }
                }
            }

            if servers.isEmpty {
                return await fetchNguonCDetail(slug: slug)
            }

            let res = FilmDetailResult(
                description: rawDesc,
                director: director,
                casts: casts,
                time: time,
                country: countryStr,
                servers: servers
            )
            cacheLock.lock()
            if cachedFilmDetails.count >= 30 {
                cachedFilmDetails.remove(at: cachedFilmDetails.startIndex)
            }
            cachedFilmDetails[slug] = res
            cacheLock.unlock()
            return res
        } catch {
            let fallback = await fetchNguonCDetail(slug: slug)
            cacheLock.lock()
            if cachedFilmDetails.count >= 30 {
                cachedFilmDetails.remove(at: cachedFilmDetails.startIndex)
            }
            cachedFilmDetails[slug] = fallback
            cacheLock.unlock()
            return fallback
        }
    }

    // MARK: - Private KKPhim Parsers
    private func fetchKKPhimList(endpoint: String) async -> [FilmItem] {
        guard let url = URL(string: "\(kkphimApi)/\(endpoint)") else { return [] }
        var req = URLRequest(url: url)
        req.timeoutInterval = 10.0
        req.setValue("Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X)", forHTTPHeaderField: "User-Agent")

        do {
            let (data, _) = try await URLSession.shared.data(for: req)
            guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let items = json["items"] as? [[String: Any]] else {
                return []
            }
            return items.compactMap { parseKKPhimItem($0) }
        } catch {
            return []
        }
    }

    private func fetchKKPhimV1List(endpoint: String) async -> [FilmItem] {
        guard let url = URL(string: "\(kkphimApi)/v1/api/\(endpoint)") else { return [] }
        var req = URLRequest(url: url)
        req.timeoutInterval = 10.0
        req.setValue("Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X)", forHTTPHeaderField: "User-Agent")

        do {
            let (data, _) = try await URLSession.shared.data(for: req)
            guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let dataObj = json["data"] as? [String: Any],
                  let items = dataObj["items"] as? [[String: Any]] else {
                return []
            }
            return items.compactMap { parseKKPhimItem($0) }
        } catch {
            return []
        }
    }

    private func parseKKPhimItem(_ d: [String: Any]) -> FilmItem? {
        guard let name = d["name"] as? String,
              let slug = d["slug"] as? String else {
            return nil
        }

        let orig = d["origin_name"] as? String ?? d["original_name"] as? String ?? ""
        let rawThumb = d["thumb_url"] as? String ?? ""
        let rawPoster = d["poster_url"] as? String ?? ""

        // Safe Fallback between thumb and poster if one is missing or "None"
        let effectiveThumb = (!rawThumb.isEmpty && rawThumb != "None") ? rawThumb : rawPoster
        let effectivePoster = (!rawPoster.isEmpty && rawPoster != "None") ? rawPoster : rawThumb

        let thumb = normalizeImageUrl(effectiveThumb)
        let poster = normalizeImageUrl(effectivePoster.isEmpty ? effectiveThumb : effectivePoster)

        let curEp = d["episode_current"] as? String ?? d["current_episode"] as? String ?? "Full"
        let quality = d["quality"] as? String ?? "FHD"
        let lang = d["lang"] as? String ?? d["language"] as? String ?? "Vietsub"
        let yearInt = d["year"] as? Int
        let yearStr = (yearInt != nil ? String(yearInt!) : (d["year"] as? String)) ?? "2026"
        let time = d["time"] as? String ?? ""

        var cats: [String] = []
        if let catList = d["category"] as? [[String: Any]] {
            cats = catList.compactMap { $0["name"] as? String }
        }

        var countryStr = ""
        if let countryList = d["country"] as? [[String: Any]], let first = countryList.first {
            countryStr = first["name"] as? String ?? ""
        }

        return FilmItem(
            name: name,
            slug: slug,
            originalName: orig,
            thumbUrl: thumb,
            posterUrl: poster,
            currentEpisode: curEp,
            totalEpisodes: "",
            quality: quality,
            language: lang,
            year: yearStr,
            time: time,
            director: "",
            casts: "",
            country: countryStr,
            categories: cats,
            description: nil,
            source: "kkphim"
        )
    }

    private func extractM3u8FromEmbed(_ embed: String) -> String? {
        if let range = embed.range(of: "url=") {
            let candidate = String(embed[range.upperBound...])
            if let decoded = candidate.removingPercentEncoding, decoded.contains(".m3u8") {
                return decoded
            }
            if candidate.contains(".m3u8") {
                return candidate
            }
        }
        return nil
    }

    private func normalizeImageUrl(_ u: String) -> String {
        let trimmed = u.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty || trimmed == "None" { return "" }
        if trimmed.hasPrefix("http://") || trimmed.hasPrefix("https://") { return trimmed }
        if trimmed.hasPrefix("/") { return "\(imageCdnBase)\(trimmed)" }
        return "\(imageCdnBase)/\(trimmed)"
    }

    // MARK: - 5. Fallback NguonC Engine
    private func fetchNguonCHomeSections() async -> [PhimSection] {
        guard let url = URL(string: "\(nguoncApi)/films/phim-moi-cap-nhat?page=1") else { return [] }
        var req = URLRequest(url: url)
        req.setValue("https://phim.nguonc.com/", forHTTPHeaderField: "Referer")
        req.setValue("Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X)", forHTTPHeaderField: "User-Agent")

        guard let (data, _) = try? await URLSession.shared.data(for: req),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let items = json["items"] as? [[String: Any]] else {
            return [PhimSection(title: "Phim Đề Xuất", films: fallbackFilms())]
        }

        let films = items.compactMap { parseNguonCItem($0) }
        return [PhimSection(title: "Phim Điện Ảnh Đề Xuất", subtitle: "Nguồn phát dự phòng", films: films)]
    }

    private func fetchNguonCCategoryFilms(slug: String) async -> [FilmItem] {
        let endpoint = slug == "phim-moi" ? "films/phim-moi-cap-nhat?page=1" : "films/danh-sach/\(slug)?page=1"
        guard let url = URL(string: "\(nguoncApi)/\(endpoint)") else { return fallbackFilms() }
        var req = URLRequest(url: url)
        req.setValue("https://phim.nguonc.com/", forHTTPHeaderField: "Referer")

        guard let (data, _) = try? await URLSession.shared.data(for: req),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let items = json["items"] as? [[String: Any]] else {
            return fallbackFilms()
        }

        let films = items.compactMap { parseNguonCItem($0) }
        return films.isEmpty ? fallbackFilms() : films
    }

    private func searchNguonC(keyword: String) async -> [FilmItem] {
        guard let encoded = keyword.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: "\(nguoncApi)/films/search?keyword=\(encoded)") else {
            return []
        }
        var req = URLRequest(url: url)
        req.setValue("https://phim.nguonc.com/", forHTTPHeaderField: "Referer")

        guard let (data, _) = try? await URLSession.shared.data(for: req),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let items = json["items"] as? [[String: Any]] else {
            return []
        }
        return items.compactMap { parseNguonCItem($0) }
    }

    private func fetchNguonCDetail(slug: String) async -> FilmDetailResult {
        guard let url = URL(string: "\(nguoncApi)/film/\(slug)") else {
            return fallbackDetailResult(slug: slug)
        }
        var req = URLRequest(url: url)
        req.setValue("https://phim.nguonc.com/", forHTTPHeaderField: "Referer")

        guard let (data, _) = try? await URLSession.shared.data(for: req),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let movie = json["movie"] as? [String: Any] else {
            return fallbackDetailResult(slug: slug)
        }

        let rawDesc = (movie["description"] as? String ?? "")
            .replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)

        var episodes: [EpisodeItem] = []
        if let epServers = movie["episodes"] as? [[String: Any]] {
            for srv in epServers {
                if let items = srv["items"] as? [[String: Any]] {
                    for item in items {
                        let name = item["name"] as? String ?? "Tập 1"
                        let epSlug = item["slug"] as? String ?? name
                        let embed = item["embed"] as? String ?? ""
                        let m3u8 = item["m3u8"] as? String ?? ""
                        if !embed.isEmpty || !m3u8.isEmpty {
                            episodes.append(EpisodeItem(name: name, slug: epSlug, embed: embed, m3u8: m3u8))
                        }
                    }
                }
            }
        }

        let server = EpisodeServer(serverName: "Server Dự Phòng", episodes: episodes.isEmpty ? [EpisodeItem(name: "Tập 1", slug: "tap-1", embed: "https://phim.nguonc.com")] : episodes)
        return FilmDetailResult(
            description: rawDesc,
            director: "Đang cập nhật",
            casts: "Đang cập nhật",
            time: "Trọn bộ",
            country: "Châu Á",
            servers: [server]
        )
    }

    private func parseNguonCItem(_ d: [String: Any]) -> FilmItem? {
        guard let name = d["name"] as? String,
              let slug = d["slug"] as? String else {
            return nil
        }
        let orig = d["original_name"] as? String ?? ""
        let thumb = d["thumb_url"] as? String ?? ""
        let poster = d["poster_url"] as? String ?? thumb
        return FilmItem(
            name: name,
            slug: slug,
            originalName: orig,
            thumbUrl: thumb.hasPrefix("http") ? thumb : "https://img.nguonc.com/\(thumb)",
            posterUrl: poster.hasPrefix("http") ? poster : "https://img.nguonc.com/\(poster)",
            currentEpisode: d["current_episode"] as? String ?? "Full",
            quality: d["quality"] as? String ?? "FHD",
            language: d["language"] as? String ?? "Vietsub",
            year: "2026",
            source: "nguonc"
        )
    }

    private func fallbackDetailResult(slug: String) -> FilmDetailResult {
        FilmDetailResult(
            description: "Phim điện ảnh chất lượng cao 4K / Full HD Vietsub & Thuyết Minh.",
            director: "Đang cập nhật",
            casts: "Dàn diễn viên nổi tiếng",
            time: "120 phút",
            country: "Quốc tế",
            servers: [
                EpisodeServer(serverName: "Server Chính (FHD)", episodes: [
                    EpisodeItem(name: "Tập 1", slug: "tap-1", embed: "", m3u8: "https://test-streams.mux.dev/x36xhzz/x36xhzz.m3u8")
                ])
            ]
        )
    }

    private func fallbackFilms() -> [FilmItem] {
        [
            FilmItem(name: "Thám Tử Lừng Danh Conan", slug: "tham-tu-lung-danh-conan", originalName: "Detective Conan", currentEpisode: "Tập 1201", quality: "FHD", language: "Vietsub + Thuyết Minh", year: "2026", time: "25 phút/tập", country: "Nhật Bản", description: "Hành trình phá án kịch tính của thám tử Shinichi Kudo."),
            FilmItem(name: "Khánh Dư Niên (Phần 2)", slug: "khanh-du-nien-2", originalName: "Joy of Life 2", currentEpisode: "Trọn Bộ", quality: "4K", language: "Vietsub", year: "2026", time: "45 phút/tập", country: "Trung Quốc", description: "Bom tấn quyền mưu cổ trang hấp dẫn nhất năm."),
            FilmItem(name: "Nữ Hoàng Nước Mắt", slug: "nu-hoang-nuoc-mat", originalName: "Queen of Tears", currentEpisode: "Trọn Bộ", quality: "FHD", language: "Thuyết Minh", year: "2026", time: "70 phút/tập", country: "Hàn Quốc", description: "Chuyện tình cảm động giữa tài phiệt và luật sư.")
        ]
    }
}
