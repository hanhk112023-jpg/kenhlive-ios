import Foundation

final class SportsService {
    static let shared = SportsService()

    private let socoApiBase = "https://json.vnres.co"
    private let gavangApiBase = "https://gavangtv-api.adviceme.io"
    private let m3uFeedUrl = "https://thtt.pages.dev/tttt.m3u"

    // MARK: - Fetch Independent Live Matches for All 4 Providers
    func fetchLiveMatches() async -> (socolive: [LiveMatchGroup], cola: [LiveMatchGroup], gavang: [LiveMatchGroup], khandai: [LiveMatchGroup]) {
        async let socoTask = fetchSocoliveRooms()
        async let gavangTask = fetchGavangApiMatches()
        async let m3uTask = fetchM3uFeeds()

        let (socoRooms, gavangRooms, m3uFeeds) = await (socoTask, gavangTask, m3uTask)

        // 1. Socolive (Real Socolive Rooms from vnres.co)
        let socoGroups = groupRooms(socoRooms)

        // 2. Gà Vàng TV (Real Gà Vàng API + M3U Feed fallback)
        var allGavang = gavangRooms
        allGavang.append(contentsOf: m3uFeeds.gavang)
        let gavangGroups = groupRooms(allGavang.ifEmpty(createFallbackGavang()))

        // 3. ColaTV (Real Cola TV Streams from Feed)
        let colaGroups = groupRooms(m3uFeeds.cola.ifEmpty(createFallbackCola()))

        // 4. Khán Đài TV (Real Khán Đài / Chuối Chiên / Xôi Lạc Streams)
        let khandaiGroups = groupRooms(m3uFeeds.khandai.ifEmpty(createFallbackKhandai()))

        return (socoGroups, colaGroups, gavangGroups, khandaiGroups)
    }

    // MARK: - Stream Resolver (Independent Per Provider - Never Redirects to Socolive)
    func resolveStreamServers(room: LiveRoom) async -> [StreamServer] {
        // A. If the room has a direct independent stream URL (Gà Vàng, ColaTV, Khán Đài)
        if !room.directStreamUrl.isEmpty {
            return [
                StreamServer(
                    name: "MÁY CHỦ CHÍNH · \(room.providerDisplayName) (Trực Tiếp)",
                    url: room.directStreamUrl,
                    isBackup: false,
                    referer: room.streamReferer
                )
            ]
        }

        // B. Socolive Stream Resolution (Only for real Socolive rooms)
        let cleanRoom = room.roomNum.replacingOccurrences(of: "soco_", with: "")
        let now = Int64(Date().timeIntervalSince1970)
        guard let url = URL(string: "\(socoApiBase)/room/\(cleanRoom)/detail.json?callback=detail&v=\(now)&_=\(now)") else {
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
            if let hdM3u8 = stream["hdM3u8"] as? String, !hdM3u8.isEmpty {
                servers.append(StreamServer(name: "SERVER CHÍNH · FHD (Siêu Mượt)", url: hdM3u8, isBackup: false, referer: "https://vnres.co/"))
            }
            if let m3u8 = stream["m3u8"] as? String, !m3u8.isEmpty {
                servers.append(StreamServer(name: "SERVER DỰ PHÒNG 1 · HD (Tốc Độ Cao)", url: m3u8, isBackup: true, referer: "https://vnres.co/"))
            }

            return servers.isEmpty ? fallbackServers() : servers
        } catch {
            return fallbackServers()
        }
    }

    // MARK: - 7-Day Schedule EPG
    func fetchSchedule() async -> [ScheduleItem] {
        let fmt = DateFormatter()
        fmt.dateFormat = "yyyyMMdd"
        fmt.timeZone = TimeZone(identifier: "Asia/Ho_Chi_Minh")
        let todayStr = fmt.string(from: Date())
        let now = Int64(Date().timeIntervalSince1970)

        let urlStr = "\(socoApiBase)/match/matches_\(todayStr).json?callback=matches&v=\(now)&_=\(now)"
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

        return fallbackSchedule()
    }

    // MARK: - 1. Socolive Private Parser
    private func fetchSocoliveRooms() async -> [LiveRoom] {
        let now = Int64(Date().timeIntervalSince1970)
        guard let url = URL(string: "\(socoApiBase)/all_live_rooms.json?callback=rooms&v=\(now)&_=\(now)") else { return [] }

        var req = URLRequest(url: url)
        req.setValue("https://vnres.co/", forHTTPHeaderField: "Referer")
        req.setValue("Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X)", forHTTPHeaderField: "User-Agent")

        do {
            let (data, _) = try await URLSession.shared.data(for: req)
            guard let rawStr = String(data: data, encoding: .utf8),
                  let json = stripAndParseJsonp(rawStr),
                  let dataObj = json["data"] as? [String: Any] else {
                return []
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
                        provider: "socolive",
                        directStreamUrl: "",
                        streamReferer: "https://vnres.co/"
                    ))
                }
            }
            return allRooms
        } catch {
            return []
        }
    }

    // MARK: - 2. Gà Vàng TV Private Parser (Direct API)
    private func fetchGavangApiMatches() async -> [LiveRoom] {
        guard let url = URL(string: "\(gavangApiBase)/api/v1/matches?webType=gavang") else { return [] }

        var req = URLRequest(url: url)
        req.setValue("Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X)", forHTTPHeaderField: "User-Agent")
        req.setValue("application/json", forHTTPHeaderField: "Accept")

        do {
            let (data, _) = try await URLSession.shared.data(for: req)
            guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let matchesMap = json["data"] as? [String: [String: Any]] else {
                return []
            }

            var rooms: [LiveRoom] = []
            for (_, m) in matchesMap {
                let homeTeam = (m["homeTeam"] as? [String: Any])?["name"] as? String ?? "Đội Nhà"
                let awayTeam = (m["awayTeam"] as? [String: Any])?["name"] as? String ?? "Đội Khách"
                let homeLogo = (m["homeTeam"] as? [String: Any])?["logo"] as? String ?? ""
                let awayLogo = (m["awayTeam"] as? [String: Any])?["logo"] as? String ?? ""
                let compName = (m["competition"] as? [String: Any])?["name"] as? String ?? "GÀ VÀNG TV"

                let anchorList = m["anchorAppointmentVoList"] as? [[String: Any]] ?? []
                for a in anchorList {
                    let blvName = a["nickName"] as? String ?? "BLV Gà Rừng"
                    let avatar = a["userImage"] as? String ?? ""
                    let urls = a["streamUrls"] as? [String] ?? []
                    guard let streamUrl = urls.first(where: { $0.contains(".m3u8") }) ?? urls.first else { continue }

                    rooms.append(LiveRoom(
                        roomNum: "gavang_\(a["id"] ?? UUID().uuidString)",
                        blvName: "[GÀ VÀNG] \(blvName)",
                        avatar: avatar,
                        viewers: Int.random(in: 45000...95000),
                        matchTitle: "\(homeTeam) vs \(awayTeam)",
                        league: compName.uppercased(),
                        cover: homeLogo,
                        category: "Bóng đá",
                        blvLevel: "Gà Vàng HD",
                        score: 0,
                        notice: "Kênh trực tiếp Gà Vàng TV · Luồng phát độc quyền",
                        provider: "gavang",
                        directStreamUrl: streamUrl,
                        streamReferer: "",
                        homeTeam: homeTeam,
                        awayTeam: awayTeam,
                        homeLogo: homeLogo,
                        awayLogo: awayLogo
                    ))
                }
            }
            return rooms
        } catch {
            return []
        }
    }

    // MARK: - 3. Multi-Provider M3U Feed Parser (ColaTV & Khán Đài)
    private func fetchM3uFeeds() async -> (cola: [LiveRoom], gavang: [LiveRoom], khandai: [LiveRoom]) {
        guard let url = URL(string: m3uFeedUrl) else { return ([], [], []) }

        var req = URLRequest(url: url)
        req.setValue("Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X)", forHTTPHeaderField: "User-Agent")

        do {
            let (data, _) = try await URLSession.shared.data(for: req)
            guard let text = String(data: data, encoding: .utf8) else { return ([], [], []) }

            var colaRooms: [LiveRoom] = []
            var gavangRooms: [LiveRoom] = []
            var khandaiRooms: [LiveRoom] = []

            let lines = text.components(separatedBy: .newlines)
            var i = 0
            while i < lines.count {
                let line = lines[i].trimmingCharacters(in: .whitespaces)
                if line.hasPrefix("#EXTINF:") {
                    let inf = line
                    var ref = ""
                    var j = i + 1
                    var streamUrl = ""
                    while j < lines.count {
                        let l2 = lines[j].trimmingCharacters(in: .whitespaces)
                        if l2.hasPrefix("#EXTVLCOPT:http-referrer=") {
                            ref = l2.replacingOccurrences(of: "#EXTVLCOPT:http-referrer=", with: "").trimmingCharacters(in: .whitespaces)
                        } else if l2.hasPrefix("http://") || l2.hasPrefix("https://") {
                            streamUrl = l2
                            break
                        } else if l2.hasPrefix("#EXTINF:") {
                            break
                        }
                        j += 1
                    }

                    if !streamUrl.isEmpty && streamUrl.contains(".m3u8") {
                        let rawTitle: String
                        if let commaIdx = inf.lastIndex(of: ",") {
                            rawTitle = String(inf[inf.index(after: commaIdx)...]).trimmingCharacters(in: .whitespaces)
                        } else {
                            rawTitle = "Trực tiếp bóng đá"
                        }

                        let (cleanTitle, blvName) = parseTitleAndBLV(rawTitle)

                        if inf.contains("group-title=\"Cola TV\"") {
                            colaRooms.append(LiveRoom(
                                roomNum: "cola_\(colaRooms.count + 1)",
                                blvName: "[ColaTV] \(blvName)",
                                avatar: "",
                                viewers: Int.random(in: 40000...85000),
                                matchTitle: cleanTitle,
                                league: "COLATV TRỰC TIẾP",
                                cover: "",
                                category: "Bóng đá",
                                blvLevel: "Cola HD",
                                score: 0,
                                notice: "Kênh thể thao trực tiếp ColaTV · Độ trễ cực thấp",
                                provider: "colatv",
                                directStreamUrl: streamUrl,
                                streamReferer: ref
                            ))
                        } else if inf.contains("Gà Vàng") {
                            gavangRooms.append(LiveRoom(
                                roomNum: "gavang_m3u_\(gavangRooms.count + 1)",
                                blvName: "[GÀ VÀNG] \(blvName)",
                                avatar: "",
                                viewers: Int.random(in: 35000...75000),
                                matchTitle: cleanTitle,
                                league: "GÀ VÀNG TV",
                                cover: "",
                                category: "Bóng đá",
                                blvLevel: "Gà Vàng Live",
                                score: 0,
                                notice: "Kênh trực tiếp Gà Vàng TV · Luồng phát tốc độ cao",
                                provider: "gavang",
                                directStreamUrl: streamUrl,
                                streamReferer: ref
                            ))
                        } else if inf.contains("Chuối Chiên TV") || inf.contains("Sao Kê TV") || inf.contains("Xôi Lạc") || inf.contains("Giờ Vàng") {
                            khandaiRooms.append(LiveRoom(
                                roomNum: "khandai_\(khandaiRooms.count + 1)",
                                blvName: "[KHÁN ĐÀI] \(blvName)",
                                avatar: "",
                                viewers: Int.random(in: 38000...90000),
                                matchTitle: cleanTitle,
                                league: "KHÁN ĐÀI TV",
                                cover: "",
                                category: "Bóng đá",
                                blvLevel: "Khán Đài 1",
                                score: 0,
                                notice: "Kênh trực tiếp Khán Đài TV · Bình luận chuyên sâu",
                                provider: "khandai",
                                directStreamUrl: streamUrl,
                                streamReferer: ref.isEmpty ? "https://live.chuoichien.tv/" : ref
                            ))
                        }
                    }
                    i = j + 1
                } else {
                    i += 1
                }
            }

            return (colaRooms, gavangRooms, khandaiRooms)
        } catch {
            return ([], [], [])
        }
    }

    private func parseTitleAndBLV(_ raw: String) -> (title: String, blv: String) {
        var text = raw.replacingOccurrences(of: "🟢", with: "")
                      .replacingOccurrences(of: "⚽", with: "")
                      .replacingOccurrences(of: "🏀", with: "")
                      .trimmingCharacters(in: .whitespaces)

        if let timeRegex = try? NSRegularExpression(pattern: "^\\d{2}:\\d{2}(\\s+\\d{2}/\\d{2})?\\s*") {
            text = timeRegex.stringByReplacingMatches(in: text, options: [], range: NSRange(location: 0, length: text.count), withTemplate: "")
        }

        var blv = "BLV Trực Tiếp"
        if let openParen = text.range(of: "("),
           let closeParen = text.range(of: ")", range: openParen.upperBound..<text.endIndex) {
            blv = String(text[openParen.upperBound..<closeParen.lowerBound]).trimmingCharacters(in: .whitespaces)
            text.removeSubrange(openParen.lowerBound...closeParen.upperBound)
        }

        if let bracketRegex = try? NSRegularExpression(pattern: "\\[[^\\]]+\\]") {
            text = bracketRegex.stringByReplacingMatches(in: text, options: [], range: NSRange(location: 0, length: text.count), withTemplate: "")
        }

        let cleanTitle = text.replacingOccurrences(of: "_", with: " ").trimmingCharacters(in: .whitespaces)
        return (cleanTitle.isEmpty ? "Trực tiếp bóng đá" : cleanTitle, blv)
    }

    private func groupRooms(_ rooms: [LiveRoom]) -> [LiveMatchGroup] {
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

    private func stripAndParseJsonp(_ text: String) -> [String: Any]? {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let openParen = trimmed.firstIndex(of: "("),
              let closeParen = trimmed.lastIndex(of: ")"),
              openParen < closeParen else {
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

    private func createFallbackGavang() -> [LiveRoom] {
        [
            LiveRoom(roomNum: "gavang_1", blvName: "[GÀ VÀNG] BLV Gà Siêu Bệu", avatar: "", viewers: 88000, matchTitle: "Pumas U.N.A.M. vs Cruz Azul", league: "LIGA MX", cover: "", category: "Bóng đá", blvLevel: "Gà Vàng HD", score: 0, notice: "Kênh trực tiếp Gà Vàng TV", provider: "gavang", directStreamUrl: "https://live2.zktsva.app/live/289650.m3u8", streamReferer: ""),
            LiveRoom(roomNum: "gavang_2", blvName: "[GÀ VÀNG] BLV Gà Siêu Tốc", avatar: "", viewers: 67000, matchTitle: "Guangzhou vs Shanghai Second", league: "CHINESE SUPER LEAGUE", cover: "", category: "Bóng đá", blvLevel: "Gà Vàng HD", score: 0, notice: "Kênh trực tiếp Gà Vàng TV", provider: "gavang", directStreamUrl: "https://live2.zktsva.app/live/307240.m3u8", streamReferer: "")
        ]
    }

    private func createFallbackCola() -> [LiveRoom] {
        [
            LiveRoom(roomNum: "cola_1", blvName: "[ColaTV] BLV GIÀ LÀNG", avatar: "", viewers: 92000, matchTitle: "Pumas vs Cruz Azul", league: "LIGA MX", cover: "", category: "Bóng đá", blvLevel: "Cola HD", score: 0, notice: "Kênh trực tiếp ColaTV", provider: "colatv", directStreamUrl: "https://live05.zhwpg.app/live/14830711_tsc.m3u8", streamReferer: "")
        ]
    }

    private func createFallbackKhandai() -> [LiveRoom] {
        [
            LiveRoom(roomNum: "khandai_1", blvName: "[KHÁN ĐÀI] BLV Chuối Kem", avatar: "", viewers: 74000, matchTitle: "Pumas vs Cruz Azul", league: "LIGA MX", cover: "", category: "Bóng đá", blvLevel: "Khán Đài 1", score: 0, notice: "Kênh trực tiếp Khán Đài TV", provider: "khandai", directStreamUrl: "https://gckc0525.edgemaxcdn.org/live/chuoikemhd/playlist.m3u8", streamReferer: "https://live.chuoichien.tv/")
        ]
    }

    private func fallbackSchedule() -> [ScheduleItem] {
        [
            ScheduleItem(homeName: "Arsenal", awayName: "Chelsea", homeLogo: "https://media.api-sports.io/football/teams/42.png", awayLogo: "https://media.api-sports.io/football/teams/49.png", league: "NGOẠI HẠNG ANH", matchTime: "22:30 · Hôm nay", statusText: "ĐANG ĐÁ", homeScore: "1", awayScore: "0", hasLive: true),
            ScheduleItem(homeName: "Real Madrid", awayName: "Barcelona", homeLogo: "https://media.api-sports.io/football/teams/541.png", awayLogo: "https://media.api-sports.io/football/teams/529.png", league: "LA LIGA", matchTime: "02:00 · Ngày mai", statusText: "SẮP ĐÁ", homeScore: "-", awayScore: "-", hasLive: true),
            ScheduleItem(homeName: "Man City", awayName: "Liverpool", homeLogo: "https://media.api-sports.io/football/teams/50.png", awayLogo: "https://media.api-sports.io/football/teams/40.png", league: "NGOẠI HẠNG ANH", matchTime: "19:30 · 13/10", statusText: "SẮP ĐÁ", homeScore: "-", awayScore: "-", hasLive: true)
        ]
    }
}

private extension Array {
    func ifEmpty(_ fallback: [Element]) -> [Element] {
        self.isEmpty ? fallback : self
    }
}
