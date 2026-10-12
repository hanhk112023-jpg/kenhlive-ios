import Foundation

final class PhimService {
    static let shared = PhimService()

    private let apiBase = "https://phim.nguonc.com/api"

    // MARK: - Home Sections (8 rich cinema categories, multi-page batch fetch)
    func fetchHomeSections() async -> [PhimSection] {
        async let moi = fetchFilmsBatch(type: "phim-moi-cap-nhat", isDanhSach: false, pages: 1...5)
        async let phimBo = fetchFilmsBatch(type: "phim-bo", isDanhSach: true, pages: 1...5)
        async let phimLe = fetchFilmsBatch(type: "phim-le", isDanhSach: true, pages: 1...5)
        async let hoatHinh = fetchFilmsBatch(type: "hoat-hinh", isDanhSach: true, pages: 1...5)
        async let hanhDong = fetchFilmsBatch(type: "hanh-dong", isCategory: true, pages: 1...3)
        async let tinhCam = fetchFilmsBatch(type: "tinh-cam", isCategory: true, pages: 1...3)
        async let coTrang = fetchFilmsBatch(type: "co-trang", isCategory: true, pages: 1...3)
        async let kinhDi = fetchFilmsBatch(type: "kinh-di", isCategory: true, pages: 1...3)

        let (m, b, l, h, hd, tc, ct, kd) = await (moi, phimBo, phimLe, hoatHinh, hanhDong, tinhCam, coTrang, kinhDi)
        var sections: [PhimSection] = []
        if !m.isEmpty { sections.append(PhimSection(title: "Phim Mới Cập Nhật", films: m)) }
        if !b.isEmpty { sections.append(PhimSection(title: "Phim Bộ Đặc Sắc", films: b)) }
        if !l.isEmpty { sections.append(PhimSection(title: "Phim Lẻ Chiếu Rạp", films: l)) }
        if !h.isEmpty { sections.append(PhimSection(title: "Hoạt Hình & Anime", films: h)) }
        if !hd.isEmpty { sections.append(PhimSection(title: "Hành Động Đỉnh Cao", films: hd)) }
        if !tc.isEmpty { sections.append(PhimSection(title: "Tình Cảm Lãng Mạn", films: tc)) }
        if !ct.isEmpty { sections.append(PhimSection(title: "Cổ Trang Cung Đấu", films: ct)) }
        if !kd.isEmpty { sections.append(PhimSection(title: "Kinh Dị Giật Gân", films: kd)) }

        if sections.isEmpty {
            sections.append(PhimSection(title: "Phim Đề Xuất", films: fallbackFilms()))
        }
        return sections
    }

    // MARK: - Category Batch Fetch (10 pages = 100 films per category)
    func fetchCategoryFilms(slug: String) async -> [FilmItem] {
        let res: [FilmItem]
        if slug == "phim-moi" {
            res = await fetchFilmsBatch(type: "phim-moi-cap-nhat", isDanhSach: false, pages: 1...10)
        } else if ["phim-bo", "phim-le", "hoat-hinh", "tv-shows"].contains(slug) {
            res = await fetchFilmsBatch(type: slug, isDanhSach: true, pages: 1...10)
        } else {
            res = await fetchFilmsBatch(type: slug, isCategory: true, pages: 1...10)
        }
        return res.isEmpty ? fallbackFilms() : res
    }

    // MARK: - Search Films (Multi-page search)
    func searchFilms(keyword: String) async -> [FilmItem] {
        guard let encoded = keyword.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else { return [] }
        return await fetchFilms(endpoint: "films/search?keyword=\(encoded)")
    }

    // MARK: - Concurrent Multi-Page Batch Loader
    func fetchFilmsBatch(type: String, isDanhSach: Bool = false, isCategory: Bool = false, pages: ClosedRange<Int> = 1...5) async -> [FilmItem] {
        await withTaskGroup(of: (Int, [FilmItem]).self) { group in
            for page in pages {
                group.addTask {
                    let ep: String
                    if isCategory {
                        ep = "films/the-loai/\(type)?page=\(page)"
                    } else if isDanhSach {
                        ep = "films/danh-sach/\(type)?page=\(page)"
                    } else {
                        ep = "films/\(type)?page=\(page)"
                    }
                    let films = await self.fetchFilms(endpoint: ep)
                    return (page, films)
                }
            }

            var results: [(Int, [FilmItem])] = []
            for await res in group {
                results.append(res)
            }
            results.sort { $0.0 < $1.0 }
            var unique: [FilmItem] = []
            var seenSlugs = Set<String>()
            for (_, list) in results {
                for item in list {
                    if !seenSlugs.contains(item.slug) {
                        seenSlugs.insert(item.slug)
                        unique.append(item)
                    }
                }
            }
            return unique
        }
    }

    // MARK: - Film Detail & Episodes
    func fetchFilmDetail(slug: String) async -> (description: String, episodes: [EpisodeItem]) {
        guard let url = URL(string: "\(apiBase)/film/\(slug)") else {
            return ("Phim điện ảnh chất lượng cao Vietsub.", [EpisodeItem(name: "Tập 1", slug: "tap-1", embed: "https://phim.nguonc.com")])
        }
        var req = URLRequest(url: url)
        req.setValue("https://phim.nguonc.com/", forHTTPHeaderField: "Referer")
        req.setValue("Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X)", forHTTPHeaderField: "User-Agent")

        do {
            let (data, _) = try await URLSession.shared.data(for: req)
            guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let movie = json["movie"] as? [String: Any] else {
                return ("", [EpisodeItem(name: "Tập Full", slug: "full", embed: "https://phim.nguonc.com")])
            }

            let rawDesc = (movie["description"] as? String ?? "")
                .replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
                .trimmingCharacters(in: .whitespacesAndNewlines)

            var episodes: [EpisodeItem] = []
            if let epServers = movie["episodes"] as? [[String: Any]] {
                for srv in epServers {
                    let serverLabel = (srv["server_name"] as? String) ?? ""
                    let isThuyetMinh = serverLabel.localizedCaseInsensitiveContains("thuyết minh") || serverLabel.localizedCaseInsensitiveContains("lồng tiếng")
                    let prefix = isThuyetMinh ? "[TM] " : ""
                    if let items = srv["items"] as? [[String: Any]] {
                        for item in items {
                            let name = item["name"] as? String ?? "Tập 1"
                            let epSlug = item["slug"] as? String ?? name
                            let embed = (item["embed"] as? String ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
                            let m3u8 = (item["m3u8"] as? String ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
                            let playTarget = !m3u8.isEmpty ? m3u8 : embed
                            if !playTarget.isEmpty {
                                episodes.append(EpisodeItem(name: "\(prefix)\(name)", slug: "\(prefix)\(epSlug)", embed: playTarget))
                            }
                        }
                    }
                }
            }
            if episodes.isEmpty {
                episodes.append(EpisodeItem(name: "Tập 1", slug: "tap-1", embed: "https://phim.nguonc.com"))
            }
            return (rawDesc, episodes)
        } catch {
            return ("", [EpisodeItem(name: "Tập 1", slug: "tap-1", embed: "https://phim.nguonc.com")])
        }
    }

    private func fetchFilms(endpoint: String) async -> [FilmItem] {
        guard let url = URL(string: "\(apiBase)/\(endpoint)") else { return [] }
        var req = URLRequest(url: url)
        req.setValue("https://phim.nguonc.com/", forHTTPHeaderField: "Referer")
        req.setValue("Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X)", forHTTPHeaderField: "User-Agent")

        do {
            let (data, _) = try await URLSession.shared.data(for: req)
            guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let items = json["items"] as? [[String: Any]] else { return [] }

            return items.compactMap { d -> FilmItem? in
                guard let name = d["name"] as? String,
                      let slug = d["slug"] as? String else { return nil }
                let orig = d["original_name"] as? String ?? ""
                let thumb = normalizeImageUrl(d["thumb_url"] as? String ?? "")
                let poster = normalizeImageUrl(d["poster_url"] as? String ?? "")
                let curEp = d["current_episode"] as? String ?? "Full"
                let totEp = (d["total_episodes"] as? Int).map(String.init) ?? (d["total_episodes"] as? String ?? "")
                let quality = d["quality"] as? String ?? "FHD"
                let lang = d["language"] as? String ?? "Vietsub"
                let desc = (d["description"] as? String)?.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)

                return FilmItem(
                    name: name,
                    slug: slug,
                    originalName: orig,
                    thumbUrl: thumb,
                    posterUrl: poster,
                    currentEpisode: curEp,
                    totalEpisodes: totEp,
                    quality: quality,
                    language: lang,
                    year: "2026",
                    categories: [],
                    description: desc
                )
            }
        } catch {
            return []
        }
    }

    private func normalizeImageUrl(_ u: String) -> String {
        let trimmed = u.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty { return "" }
        if trimmed.hasPrefix("http://") || trimmed.hasPrefix("https://") { return trimmed }
        if trimmed.hasPrefix("/") { return "https://img.nguonc.com\(trimmed)" }
        return "https://img.nguonc.com/\(trimmed)"
    }

    private func fallbackFilms() -> [FilmItem] {
        [
            FilmItem(name: "Mỹ Nhân Dư (Phần 1)", slug: "my-nhan-du-phan-1", originalName: "Beauty Remains", currentEpisode: "Tập 18", quality: "FHD", language: "Vietsub", year: "2026", description: "Siêu phẩm tâm lý tình cảm đặc sắc chất lượng cao."),
            FilmItem(name: "Thám Tử Lừng Danh Conan", slug: "conan-movie", originalName: "Detective Conan", currentEpisode: "Full", quality: "4K", language: "Thuyết Minh", year: "2026", description: "Hành trình phá án kịch tính của thám tử lừng danh."),
            FilmItem(name: "Khánh Dư Niên (Phần 2)", slug: "khanh-du-nien-2", originalName: "Joy of Life 2", currentEpisode: "Trọn Bộ", quality: "FHD", language: "Vietsub", year: "2026", description: "Bom tấn cổ trang quyền mưu hấp dẫn nhất năm.")
        ]
    }
}
