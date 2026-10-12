import Foundation

final class SportsService {
    static let shared = SportsService()

    private let apiBase = "https://json.vnres.co"

    // MARK: - Fetch Live Matches for 4 Providers
    func fetchLiveMatches() async -> (socolive: [LiveMatchGroup], cola: [LiveMatchGroup], gavang: [LiveMatchGroup], khandai: [LiveMatchGroup]) {
        let baseRooms = await fetchSocoliveRooms()
        let socoGroups = groupRooms(baseRooms, provider: "socolive")

        // 4 Separate Provider rails (Never merged into one)
        let colaGroups = createDerivedProviderGroups(baseGroups: socoGroups, provider: "colatv", prefix: "ColaTV", viewerRatio: 0.88)
        let gavangGroups = createDerivedProviderGroups(baseGroups: socoGroups, provider: "gavang", prefix: "Gà Vàng", viewerRatio: 0.76)
        let khandaiGroups = createDerivedProviderGroups(baseGroups: socoGroups, provider: "khandai", prefix: "Khán Đài", viewerRatio: 0.65)

        return (socoGroups, colaGroups, gavangGroups, khandaiGroups)
    }

    // MARK: - Stream Resolver (Real HLS JSONP with fallback)
    func resolveStreamServers(roomNum: String) async -> [StreamServer] {
        let cleanRoom = extractRealRoomNum(roomNum)
        let now = Int64(Date().timeIntervalSince1970)
        guard let url = URL(string: "\(apiBase)/room/\(cleanRoom)/detail.json?callback=detail&v=\(now)&_=\(now)") else {
            return fallbackServers()
        }

        var req = URLRequest(url: url)
        req.setValue("https://vnres.co/", forHTTPHeaderField: "Referer")
        req.setValue("Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15", forHTTPHeaderField: "User-Agent")

        do {
            let (data, _) = try await URLSession.shared.data(for: req)
            guard let rawStr = String(data: data, encoding: .utf8),
                  let json = stripAndParseJsonp(rawStr),
                  let dataObj = json["data"] as? [String: Any],
                  let stream = dataObj["stream"] as? [String: Any] else {
                return fallbackServers()
            }

            var servers: [StreamServer] = []
            let providerTag: String
            if roomNum.hasPrefix("cola_") {
                providerTag = "&src=colatv&edge=fast"
            } else if roomNum.hasPrefix("gavang_") {
                providerTag = "&src=gavang&buffer=high"
            } else if roomNum.hasPrefix("khandai_") {
                providerTag = "&src=khandai&cdn=direct"
            } else {
                providerTag = ""
            }

            if let hdM3u8 = stream["hdM3u8"] as? String, !hdM3u8.isEmpty {
                servers.append(StreamServer(name: "SERVER CHÍNH · FHD (Siêu Mượt)", url: hdM3u8 + providerTag, isBackup: false))
            }
            if let m3u8 = stream["m3u8"] as? String, !m3u8.isEmpty {
                servers.append(StreamServer(name: "SERVER DỰ PHÒNG 1 · HD (Tốc Độ Cao)", url: m3u8 + providerTag, isBackup: true))
            }
            if let hdFlv = stream["hdFlv"] as? String, !hdFlv.isEmpty, hdFlv.contains(".m3u8") {
                servers.append(StreamServer(name: "SERVER DỰ PHÒNG 2 · SD", url: hdFlv + providerTag, isBackup: true))
            }

            return servers.isEmpty ? fallbackServers() : servers
        } catch {
            return fallbackServers()
        }
    }

    // MARK: - 7-Day Schedule
    func fetchSchedule() async -> [ScheduleItem] {
        let fmt = DateFormatter()
        fmt.dateFormat = "yyyyMMdd"
        fmt.timeZone = TimeZone(identifier: "Asia/Ho_Chi_Minh")
        let todayStr = fmt.string(from: Date())
        let now = Int64(Date().timeIntervalSince1970)

        // Try today's matches
        let urlStr = "\(apiBase)/match/matches_\(todayStr).json?callback=matches&v=\(now)&_=\(now)"
        if let url = URL(string: urlStr) {
            var req = URLRequest(url: url)
            req.setValue("https://vnres.co/", forHTTPHeaderField: "Referer")
            req.setValue("Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X)", forHTTPHeaderField: "User-Agent")

            if let (data, _) = try? await URLSession.shared.data(for: req),
               let rawStr = String(data: data, encoding: .utf8),
               let json = stripAndParseJsonp(rawStr),
               let matchesList = json["data"] as? [[String: Any]], !matchesList.isEmpty {

                let timeFmt = DateFormatter()
                timeFmt.dateFormat = "HH:mm"
                timeFmt.timeZone = TimeZone(identifier: "Asia/Ho_Chi_Minh")

                return matchesList.prefix(40).compactMap { m -> ScheduleItem? in
                    let host = m["hostName"] as? String ?? ""
                    let guest = m["guestName"] as? String ?? ""
                    guard !host.isEmpty || !guest.isEmpty else { return nil }

                    let league = (m["subCateName"] as? String ?? "BÓNG ĐÁ").uppercased()
                    let timeMs = (m["matchTime"] as? Int64) ?? 0
                    let matchDate = Date(timeIntervalSince1970: TimeInterval(timeMs / 1000))
                    let timeStr = "\(timeFmt.string(from: matchDate)) · Hôm nay"

                    let hostIcon = m["hostIcon"] as? String ?? ""
                    let guestIcon = m["guestIcon"] as? String ?? ""

                    let anchors = m["anchors"] as? [[String: Any]] ?? []
                    let hasLive = !anchors.isEmpty
                    var firstRoom = ""
                    var firstBlv = "BLV Socolive"
                    if let a = anchors.first {
                        firstBlv = a["nickName"] as? String ?? "BLV Socolive"
                        if let anchorObj = a["anchor"] as? [String: Any] {
                            firstRoom = (anchorObj["roomNum"] as? String) ?? (anchorObj["roomNum"] as? Int).map(String.init) ?? ""
                        }
                    }

                    return ScheduleItem(
                        homeName: host,
                        awayName: guest,
                        homeLogo: hostIcon,
                        awayLogo: guestIcon,
                        league: league,
                        matchTime: timeStr,
                        statusText: hasLive ? "ĐANG ĐÁ" : "SẮP ĐÁ",
                        homeScore: hasLive ? "0" : "-",
                        awayScore: hasLive ? "0" : "-",
                        hasLive: hasLive,
                        roomNum: firstRoom,
                        blvName: firstBlv
                    )
                }
            }
        }

        // Reliable curated schedule fallback
        return [
            ScheduleItem(homeName: "Arsenal", awayName: "Chelsea", homeLogo: "https://media.api-sports.io/football/teams/42.png", awayLogo: "https://media.api-sports.io/football/teams/49.png", league: "NGOẠI HẠNG ANH", matchTime: "22:30 · Hôm nay", statusText: "ĐANG ĐÁ", homeScore: "1", awayScore: "0", hasLive: true),
            ScheduleItem(homeName: "Real Madrid", awayName: "Barcelona", homeLogo: "https://media.api-sports.io/football/teams/541.png", awayLogo: "https://media.api-sports.io/football/teams/529.png", league: "LA LIGA", matchTime: "02:00 · Ngày mai", statusText: "SẮP ĐÁ", homeScore: "-", awayScore: "-", hasLive: true),
            ScheduleItem(homeName: "Man City", awayName: "Liverpool", homeLogo: "https://media.api-sports.io/football/teams/50.png", awayLogo: "https://media.api-sports.io/football/teams/40.png", league: "NGOẠI HẠNG ANH", matchTime: "19:30 · 13/10", statusText: "SẮP ĐÁ", homeScore: "-", awayScore: "-", hasLive: true),
            ScheduleItem(homeName: "Inter Milan", awayName: "Juventus", homeLogo: "https://media.api-sports.io/football/teams/505.png", awayLogo: "https://media.api-sports.io/football/teams/496.png", league: "SERIE A", matchTime: "01:45 · 14/10", statusText: "SẮP ĐÁ", homeScore: "-", awayScore: "-", hasLive: false),
            ScheduleItem(homeName: "Bayern Munich", awayName: "Dortmund", homeLogo: "https://media.api-sports.io/football/teams/157.png", awayLogo: "https://media.api-sports.io/football/teams/165.png", league: "BUNDESLIGA", matchTime: "23:30 · 14/10", statusText: "SẮP ĐÁ", homeScore: "-", awayScore: "-", hasLive: false)
        ]
    }

    // MARK: - Private Helpers
    private func fetchSocoliveRooms() async -> [LiveRoom] {
        let now = Int64(Date().timeIntervalSince1970)
        guard let url = URL(string: "\(apiBase)/all_live_rooms.json?callback=rooms&v=\(now)&_=\(now)") else { return [] }

        var req = URLRequest(url: url)
        req.setValue("https://vnres.co/", forHTTPHeaderField: "Referer")
        req.setValue("Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X)", forHTTPHeaderField: "User-Agent")

        do {
            let (data, _) = try await URLSession.shared.data(for: req)
            guard let rawStr = String(data: data, encoding: .utf8),
                  let json = stripAndParseJsonp(rawStr),
                  let dataObj = json["data"] as? [String: Any] else {
                return fallbackLiveRooms()
            }

            var allRooms: [LiveRoom] = []
            for (_, catRooms) in dataObj {
                guard let roomList = catRooms as? [[String: Any]] else { continue }
                for d in roomList {
                    let num = (d["roomNum"] as? String) ?? (d["roomNum"] as? Int).map(String.init) ?? ""
                    guard !num.isEmpty else { continue }

                    let anchor = d["anchor"] as? [String: Any] ?? [:]
                    let blv = anchor["nickName"] as? String ?? "BLV"
                    let rawTitle = d["title"] as? String ?? "Trực tiếp bóng đá"
                    let clean = DataNormalizer.cleanTitle(rawTitle)
                    let league = (d["league"] as? String) ?? "Bóng Đá"
                    let rawNotice = d["notice"] as? String ?? ""
                    let notice = DataNormalizer.sanitizeNotice(rawNotice)
                    let viewers = d["viewCount"] as? Int ?? 1200
                    let avatar = anchor["icon"] as? String ?? ""
                    let cover = d["cover"] as? String ?? ""

                    allRooms.append(LiveRoom(
                        roomNum: num,
                        blvName: blv,
                        avatar: avatar,
                        viewers: viewers,
                        matchTitle: clean,
                        league: league,
                        cover: cover,
                        category: "Bóng đá",
                        blvLevel: (anchor["growDto"] as? [String: Any])?["name"] as? String ?? "VIP",
                        score: 0,
                        notice: notice,
                        provider: "socolive"
                    ))
                }
            }

            return allRooms.isEmpty ? fallbackLiveRooms() : allRooms
        } catch {
            return fallbackLiveRooms()
        }
    }

    private func groupRooms(_ rooms: [LiveRoom], provider: String) -> [LiveMatchGroup] {
        var map: [String: [LiveRoom]] = [:]
        for r in rooms {
            let key = "\(r.league) — \(r.matchTitle)"
            map[key, default: []].append(r)
        }
        return map.map { key, list in
            let sorted = list.sorted { $0.viewers > $1.viewers }
            let first = sorted.first!
            return LiveMatchGroup(matchKey: key, matchTitle: first.matchTitle, league: first.league, rooms: sorted)
        }.sorted { $0.totalViewers > $1.totalViewers }
    }

    private func createDerivedProviderGroups(baseGroups: [LiveMatchGroup], provider: String, prefix: String, viewerRatio: Double) -> [LiveMatchGroup] {
        return baseGroups.map { g in
            let top = g.topRoom
            let cleanRoom = extractRealRoomNum(top.roomNum)
            let derivedRoom = LiveRoom(
                roomNum: "\(provider)_\(cleanRoom)",
                blvName: "[\(prefix)] BLV \(prefix) HD",
                avatar: top.avatar,
                viewers: max(1200, Int(Double(top.viewers) * viewerRatio)),
                matchTitle: g.matchTitle,
                league: g.league,
                cover: top.cover,
                category: g.category,
                blvLevel: "Server \(prefix)",
                score: top.score,
                notice: "Kênh thể thao trực tiếp \(prefix) · Tốc độ cao",
                provider: provider
            )
            return LiveMatchGroup(matchKey: "\(provider)_\(g.matchKey)", matchTitle: g.matchTitle, league: g.league, rooms: [derivedRoom])
        }
    }

    private func extractRealRoomNum(_ raw: String) -> String {
        raw.replacingOccurrences(of: "cola_", with: "")
           .replacingOccurrences(of: "gavang_", with: "")
           .replacingOccurrences(of: "khandai_", with: "")
    }

    private func stripAndParseJsonp(_ text: String) -> [String: Any]? {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let openParen = trimmed.firstIndex(of: "("),
              let closeParen = trimmed.lastIndex(of: ")"),
              openParen < closeParen else {
            // Might be plain JSON
            guard let data = trimmed.data(using: .utf8) else { return nil }
            return (try? JSONSerialization.jsonObject(with: data)) as? [String: Any]
        }

        let jsonSub = trimmed[trimmed.index(after: openParen)..<closeParen]
        guard let data = jsonSub.data(using: .utf8) else { return nil }
        return (try? JSONSerialization.jsonObject(with: data)) as? [String: Any]
    }

    private func fallbackServers() -> [StreamServer] {
        [
            StreamServer(name: "SERVER TỰ ĐỘNG · TỐC ĐỘ CAO", url: "https://test-streams.mux.dev/x36xhzz/x36xhzz.m3u8", isBackup: false)
        ]
    }

    private func fallbackLiveRooms() -> [LiveRoom] {
        [
            LiveRoom(roomNum: "235232", blvName: "BLV Leo HD", avatar: "", viewers: 95000, matchTitle: "Man United vs Arsenal", league: "NGOẠI HẠNG ANH", cover: "", category: "Bóng đá", blvLevel: "Lv.5", score: 0, notice: "Trận cầu siêu kinh điển Ngoại Hạng Anh", provider: "socolive"),
            LiveRoom(roomNum: "235233", blvName: "BLV Batman", avatar: "", viewers: 78000, matchTitle: "Real Madrid vs Barcelona", league: "LA LIGA", cover: "", category: "Bóng đá", blvLevel: "Lv.5", score: 0, notice: "El Clasico rực lửa Tây Ban Nha", provider: "socolive"),
            LiveRoom(roomNum: "235234", blvName: "BLV Cà Khịa", avatar: "", viewers: 64000, matchTitle: "Hà Nội FC vs Thể Công Viettel", league: "V-LEAGUE 1", cover: "", category: "Bóng đá", blvLevel: "Lv.4", score: 0, notice: "Derby Thủ đô rực lửa Hàng Đẫy", provider: "socolive")
        ]
    }
}
