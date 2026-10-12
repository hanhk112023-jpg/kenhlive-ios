import Foundation

final class IptvService {
    static let shared = IptvService()

    private let vnM3uUrl = "https://iptv-org.github.io/iptv/countries/vn.m3u"
    private let sportsM3uUrl = "https://iptv-org.github.io/iptv/categories/sports.m3u"

    func fetchCuratedChannels() async -> [IptvCategory] {
        var allChannels = await fetchM3uChannels()
        if allChannels.isEmpty {
            allChannels = fallbackChannels()
        }

        // Categorize into clean sections
        let favIds = StorageManager.shared.favoriteChannelIds
        let favorites = allChannels.filter { favIds.contains($0.channelId) }

        let vtv = allChannels.filter { $0.name.localizedCaseInsensitiveContains("vtv") }
        let htv = allChannels.filter { $0.name.localizedCaseInsensitiveContains("htv") || $0.name.localizedCaseInsensitiveContains("vtc") }
        let sports = allChannels.filter {
            $0.name.localizedCaseInsensitiveContains("thể thao") ||
            $0.name.localizedCaseInsensitiveContains("sport") ||
            $0.name.localizedCaseInsensitiveContains("bóng đá") ||
            $0.name.localizedCaseInsensitiveContains("espn")
        }
        let entertainment = allChannels.filter {
            $0.name.localizedCaseInsensitiveContains("thvl") ||
            $0.name.localizedCaseInsensitiveContains("today") ||
            $0.name.localizedCaseInsensitiveContains("hbo") ||
            $0.name.localizedCaseInsensitiveContains("cinemax")
        }

        var categories: [IptvCategory] = []
        if !favorites.isEmpty {
            categories.append(IptvCategory(name: "Yêu Thích", channels: favorites))
        }
        categories.append(IptvCategory(name: "VTV Quốc Gia", channels: vtv.ifEmpty(fallbackVTV())))
        categories.append(IptvCategory(name: "HTV & VTC", channels: htv.ifEmpty(fallbackHTV())))
        categories.append(IptvCategory(name: "Thể Thao", channels: sports.ifEmpty(fallbackSports())))
        categories.append(IptvCategory(name: "Giải Trí & Phim", channels: entertainment.ifEmpty(fallbackEntertainment())))
        categories.append(IptvCategory(name: "Tất Cả Kênh", channels: allChannels))

        return categories
    }

    func resolveStreamUrl(channel: IptvChannel) async -> String {
        if channel.streamUrl.hasPrefix("tv360://") {
            let id = channel.streamUrl.replacingOccurrences(of: "tv360://", with: "")
            if let resolved = await resolveTv360(channelId: id) {
                return resolved
            }
        }
        return channel.streamUrl
    }

    private func resolveTv360(channelId: String) async -> String? {
        // Fallback direct maps for core channels
        let directMap: [String: String] = [
            "20": "https://liveh12.vtvprime.vn/hls/ANNINHTV/index.m3u8",
            "19": "https://liveh12.vtvprime.vn/hls/QPTV/index.m3u8",
            "33": "https://liveh34.vtvprime.vn/hls/HANOI1TV/index.m3u8",
            "26": "https://1011154949.vnns.net/CDN-FPT02/THVL2-HD-1080p/playlist.m3u8"
        ]
        if let direct = directMap[channelId] { return direct }

        let t = Int64(Date().timeIntervalSince1970 * 1000)
        let apiUrl = "https://tv360.vn/public/v1/composite/get-link?id=\(channelId)&type=LIVE&mod=LIVE&subInfo=3&t=\(t)&secured=true"
        guard let url = URL(string: apiUrl) else { return nil }

        var req = URLRequest(url: url)
        req.setValue("https://tv360.vn/", forHTTPHeaderField: "Referer")
        req.setValue("https://tv360.vn", forHTTPHeaderField: "Origin")

        do {
            let (data, _) = try await URLSession.shared.data(for: req)
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let dataObj = json["data"] as? [String: Any],
               let streamUrl = dataObj["streamUrl"] as? String, !streamUrl.isEmpty {
                return streamUrl
            }
        } catch { }

        return nil
    }

    private func fetchM3uChannels() async -> [IptvChannel] {
        guard let url = URL(string: vnM3uUrl) else { return [] }
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            guard let content = String(data: data, encoding: .utf8) else { return [] }
            return parseM3U(content)
        } catch {
            return []
        }
    }

    private func parseM3U(_ content: String) -> [IptvChannel] {
        var list: [IptvChannel] = []
        let lines = content.components(separatedBy: .newlines)
        var currentName = ""
        var currentGroup = "Chung"
        var currentLogo = ""
        var currentId = ""

        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmed.hasPrefix("#EXTINF:") {
                // Parse channel name
                if let commaIndex = trimmed.firstIndex(of: ",") {
                    let rawName = String(trimmed[trimmed.index(after: commaIndex)...]).trimmingCharacters(in: .whitespaces)
                    currentName = rawName.replacingOccurrences(of: "(1080p)", with: "")
                        .replacingOccurrences(of: "(720p)", with: "")
                        .trimmingCharacters(in: .whitespaces)
                }
                // Parse group-title
                if let grpRange = trimmed.range(of: "group-title=\"([^\"]+)\"", options: .regularExpression) {
                    currentGroup = String(trimmed[grpRange]).replacingOccurrences(of: "group-title=\"", with: "").replacingOccurrences(of: "\"", with: "")
                }
                // Parse tvg-logo
                if let logoRange = trimmed.range(of: "tvg-logo=\"([^\"]+)\"", options: .regularExpression) {
                    currentLogo = String(trimmed[logoRange]).replacingOccurrences(of: "tvg-logo=\"", with: "").replacingOccurrences(of: "\"", with: "")
                }
                // Parse tvg-id
                if let idRange = trimmed.range(of: "tvg-id=\"([^\"]+)\"", options: .regularExpression) {
                    currentId = String(trimmed[idRange]).replacingOccurrences(of: "tvg-id=\"", with: "").replacingOccurrences(of: "\"", with: "")
                }
            } else if trimmed.hasPrefix("http://") || trimmed.hasPrefix("https://") {
                if !currentName.isEmpty {
                    let cid = currentId.isEmpty ? "\(currentName)_\(list.count)" : "\(currentId)_\(list.count)"
                    list.append(IptvChannel(
                        channelId: cid,
                        name: currentName,
                        group: currentGroup,
                        logo: currentLogo,
                        streamUrl: trimmed,
                        isLive: true,
                        resolution: "FHD"
                    ))
                }
                currentName = ""
                currentGroup = "Chung"
                currentLogo = ""
                currentId = ""
            }
        }
        return list
    }

    private func fallbackChannels() -> [IptvChannel] {
        fallbackVTV() + fallbackHTV() + fallbackSports() + fallbackEntertainment()
    }

    private func fallbackVTV() -> [IptvChannel] {
        [
            IptvChannel(channelId: "vtv1", name: "VTV1 HD", group: "VTV", logo: "", streamUrl: "https://vtv1.vtvgo.vn/live/playlist.m3u8", resolution: "FHD"),
            IptvChannel(channelId: "vtv2", name: "VTV2 HD", group: "VTV", logo: "", streamUrl: "https://vtv2.vtvgo.vn/live/playlist.m3u8", resolution: "FHD"),
            IptvChannel(channelId: "vtv3", name: "VTV3 HD", group: "VTV", logo: "", streamUrl: "https://vtv3.vtvgo.vn/live/playlist.m3u8", resolution: "FHD"),
            IptvChannel(channelId: "vtv5", name: "VTV5 HD", group: "VTV", logo: "", streamUrl: "https://vtv5.vtvgo.vn/live/playlist.m3u8", resolution: "FHD"),
            IptvChannel(channelId: "vtv6", name: "VTV Cần Thơ", group: "VTV", logo: "", streamUrl: "https://vtvcantho.vtvgo.vn/live/playlist.m3u8", resolution: "FHD"),
            IptvChannel(channelId: "vtv7", name: "VTV7 HD", group: "VTV", logo: "", streamUrl: "https://vtv7.vtvgo.vn/live/playlist.m3u8", resolution: "FHD"),
            IptvChannel(channelId: "vtv8", name: "VTV8 HD", group: "VTV", logo: "", streamUrl: "https://vtv8.vtvgo.vn/live/playlist.m3u8", resolution: "FHD"),
            IptvChannel(channelId: "vtv9", name: "VTV9 HD", group: "VTV", logo: "", streamUrl: "https://vtv9.vtvgo.vn/live/playlist.m3u8", resolution: "FHD")
        ]
    }

    private func fallbackHTV() -> [IptvChannel] {
        [
            IptvChannel(channelId: "htv7", name: "HTV7 HD", group: "HTV", logo: "", streamUrl: "https://htv7.hcmc.vn/live/playlist.m3u8", resolution: "FHD"),
            IptvChannel(channelId: "htv9", name: "HTV9 HD", group: "HTV", logo: "", streamUrl: "https://htv9.hcmc.vn/live/playlist.m3u8", resolution: "FHD"),
            IptvChannel(channelId: "htv_the_thao", name: "HTV Thể Thao", group: "HTV", logo: "", streamUrl: "https://htvtt.hcmc.vn/live/playlist.m3u8", resolution: "FHD"),
            IptvChannel(channelId: "vtc1", name: "VTC1 HD", group: "VTC", logo: "", streamUrl: "https://vtc1.vtc.vn/live/playlist.m3u8", resolution: "FHD"),
            IptvChannel(channelId: "vtc3", name: "VTC3 Thể Thao", group: "VTC", logo: "", streamUrl: "https://vtc3.vtc.vn/live/playlist.m3u8", resolution: "FHD")
        ]
    }

    private func fallbackSports() -> [IptvChannel] {
        [
            IptvChannel(channelId: "on_football", name: "ON Football HD", group: "Thể Thao", logo: "", streamUrl: "https://test-streams.mux.dev/x36xhzz/x36xhzz.m3u8", resolution: "FHD"),
            IptvChannel(channelId: "on_sports", name: "ON Sports+", group: "Thể Thao", logo: "", streamUrl: "https://test-streams.mux.dev/x36xhzz/x36xhzz.m3u8", resolution: "FHD"),
            IptvChannel(channelId: "kplus_sport1", name: "K+ SPORT 1", group: "Thể Thao", logo: "", streamUrl: "https://test-streams.mux.dev/x36xhzz/x36xhzz.m3u8", resolution: "FHD"),
            IptvChannel(channelId: "kplus_sport2", name: "K+ SPORT 2", group: "Thể Thao", logo: "", streamUrl: "https://test-streams.mux.dev/x36xhzz/x36xhzz.m3u8", resolution: "FHD")
        ]
    }

    private func fallbackEntertainment() -> [IptvChannel] {
        [
            IptvChannel(channelId: "thvl1", name: "THVL1 HD", group: "Giải Trí", logo: "", streamUrl: "https://1011154949.vnns.net/CDN-FPT02/THVL2-HD-1080p/playlist.m3u8", resolution: "FHD"),
            IptvChannel(channelId: "thvl2", name: "THVL2 HD", group: "Giải Trí", logo: "", streamUrl: "https://1011154949.vnns.net/CDN-FPT02/THVL2-HD-1080p/playlist.m3u8", resolution: "FHD"),
            IptvChannel(channelId: "antv", name: "ANTV Truyền Hình CAND", group: "Tin Tức", logo: "", streamUrl: "https://liveh12.vtvprime.vn/hls/ANNINHTV/index.m3u8", resolution: "FHD")
        ]
    }
}

private extension Array {
    func ifEmpty(_ fallback: [Element]) -> [Element] {
        self.isEmpty ? fallback : self
    }
}
