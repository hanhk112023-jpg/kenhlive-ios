import Foundation

final class PhimService {
    static let shared = PhimService()

    private let apiBase = "https://phim.nguonc.com/api"

    func fetchHomeSections() async -> [PhimSection] {
        async let moi = fetchFilms(endpoint: "films/phim-moi-cap-nhat?page=1")
        async let phimBo = fetchFilms(endpoint: "films/danh-sach/phim-bo?page=1")
        async let phimLe = fetchFilms(endpoint: "films/danh-sach/phim-le?page=1")
        async let hoatHinh = fetchFilms(endpoint: "films/danh-sach/hoat-hinh?page=1")

        let (m, b, l, h) = await (moi, phimBo, phimLe, hoatHinh)
        var sections: [PhimSection] = []
        if !m.isEmpty { sections.append(PhimSection(title: "Phim Mới Cập Nhật", films: m)) }
        if !b.isEmpty { sections.append(PhimSection(title: "Phim Bộ Đặc Sắc", films: b)) }
        if !l.isEmpty { sections.append(PhimSection(title: "Phim Lẻ Chiếu Rạp", films: l)) }
        if !h.isEmpty { sections.append(PhimSection(title: "Hoạt Hình & Anime", films: h)) }

        if sections.isEmpty {
            sections.append(PhimSection(title: "Phim Đề Xuất", films: fallbackFilms()))
        }
        return sections
    }

    func fetchCategoryFilms(slug: String) async -> [FilmItem] {
        let ep: String
        if slug == "phim-moi" {
            ep = "films/phim-moi-cap-nhat?page=1"
        } else if ["phim-bo", "phim-le", "hoat-hinh", "tv-shows"].contains(slug) {
            ep = "films/danh-sach/\(slug)?page=1"
        } else {
            ep = "films/the-loai/\(slug)?page=1"
        }
        let res = await fetchFilms(endpoint: ep)
        return res.isEmpty ? fallbackFilms() : res
    }

    func searchFilms(keyword: String) async -> [FilmItem] {
        guard let encoded = keyword.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else { return [] }
        return await fetchFilms(endpoint: "films/search?keyword=\(encoded)")
    }

    func fetchFilmDetail(slug: String) async -> (description: String, episodes: [EpisodeItem]) {
        guard let url = URL(string: "\(apiBase)/film/\(slug)") else {
            return ("Phim điện ảnh chất lượng cao Vietsub.", [EpisodeItem(name: "Tập 1", slug: "tap-1", embed: "https://phim.nguonc.com")])
        }
        var req = URLRequest(url: url)
        req.setValue("https://phim.nguonc.com/", forHTTPHeaderField: "Referer")

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
                    if let items = srv["items"] as? [[String: Any]] {
                        for item in items {
                            let name = item["name"] as? String ?? "Tập 1"
                            let epSlug = item["slug"] as? String ?? name
                            let embed = item["embed"] as? String ?? ""
                            if !embed.isEmpty {
                                episodes.append(EpisodeItem(name: name, slug: epSlug, embed: embed))
                            }
                        }
                        if !episodes.isEmpty { break }
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
