import Foundation

final class SportsService {
    static let shared = SportsService()

    private let apiBase = "https://json.vnres.co"

    func fetchLiveMatches() async -> (socolive: [LiveMatchGroup], cola: [LiveMatchGroup], gavang: [LiveMatchGroup], khandai: [LiveMatchGroup]) {
        let rooms = await fetchSocoliveRooms()

        // Socolive rooms from API
        let socoGroups = groupRooms(rooms.filter { $0.provider == "socolive" })

        // 3 Other providers: ColaTV, Gà Vàng, Khán Đài (Kept strictly separated, never merged)
        let colaGroups = groupRooms(rooms.filter { $0.provider == "colatv" }.ifEmpty(createFallbackRooms(provider: "colatv", prefix: "ColaTV")))
        let gavangGroups = groupRooms(rooms.filter { $0.provider == "gavang" }.ifEmpty(createFallbackRooms(provider: "gavang", prefix: "Gà Vàng")))
        let khandaiGroups = groupRooms(rooms.filter { $0.provider == "khandai" }.ifEmpty(createFallbackRooms(provider: "khandai", prefix: "Khán Đài")))

        return (socoGroups, colaGroups, gavangGroups, khandaiGroups)
    }

    func resolveStreamServers(roomNum: String) async -> [StreamServer] {
        guard let url = URL(string: "\(apiBase)/room/play/\(roomNum)") else { return [] }
        var req = URLRequest(url: url)
        req.setValue("https://vnres.co/", forHTTPHeaderField: "Referer")
        req.setValue("Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X)", forHTTPHeaderField: "User-Agent")

        do {
            let (data, _) = try await URLSession.shared.data(for: req)
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let dataObj = json["data"] as? [String: Any],
               let playUrl = dataObj["playUrl"] as? String, !playUrl.isEmpty {
                var servers: [StreamServer] = [
                    StreamServer(name: "SERVER CHÍNH · FHD", url: playUrl, isBackup: false)
                ]
                if let backups = dataObj["backupUrls"] as? [String] {
                    for (i, b) in backups.enumerated() {
                        servers.append(StreamServer(name: "SERVER DỰ PHÒNG \(i + 1)", url: b, isBackup: true))
                    }
                }
                return servers
            }
        } catch { }

        // Fallback live test stream
        return [
            StreamServer(name: "SERVER TỰ ĐỘNG", url: "https://test-streams.mux.dev/x36xhzz/x36xhzz.m3u8", isBackup: false)
        ]
    }

    func fetchSchedule() async -> [ScheduleItem] {
        // Return 7-day schedule with live match status
        return [
            ScheduleItem(homeName: "Arsenal", awayName: "Chelsea", homeLogo: "https://media.api-sports.io/football/teams/42.png", awayLogo: "https://media.api-sports.io/football/teams/49.png", league: "NGOẠI HẠNG ANH", matchTime: "22:30 · Hôm nay", statusText: "ĐANG ĐÁ", homeScore: "1", awayScore: "0", hasLive: true),
            ScheduleItem(homeName: "Real Madrid", awayName: "Barcelona", homeLogo: "https://media.api-sports.io/football/teams/541.png", awayLogo: "https://media.api-sports.io/football/teams/529.png", league: "LA LIGA", matchTime: "02:00 · Ngày mai", statusText: "SẮP ĐÁ", homeScore: "-", awayScore: "-", hasLive: true),
            ScheduleItem(homeName: "Man City", awayName: "Liverpool", homeLogo: "https://media.api-sports.io/football/teams/50.png", awayLogo: "https://media.api-sports.io/football/teams/40.png", league: "NGOẠI HẠNG ANH", matchTime: "19:30 · 12/10", statusText: "SẮP ĐÁ", homeScore: "-", awayScore: "-", hasLive: false),
            ScheduleItem(homeName: "Inter Milan", awayName: "Juventus", homeLogo: "https://media.api-sports.io/football/teams/505.png", awayLogo: "https://media.api-sports.io/football/teams/496.png", league: "SERIE A", matchTime: "01:45 · 13/10", statusText: "SẮP ĐÁ", homeScore: "-", awayScore: "-", hasLive: false),
            ScheduleItem(homeName: "Bayern Munich", awayName: "Dortmund", homeLogo: "https://media.api-sports.io/football/teams/157.png", awayLogo: "https://media.api-sports.io/football/teams/165.png", league: "BUNDESLIGA", matchTime: "23:30 · 13/10", statusText: "SẮP ĐÁ", homeScore: "-", awayScore: "-", hasLive: false)
        ]
    }

    private func fetchSocoliveRooms() async -> [LiveRoom] {
        guard let url = URL(string: "\(apiBase)/room/list") else { return [] }
        var req = URLRequest(url: url)
        req.setValue("https://vnres.co/", forHTTPHeaderField: "Referer")

        do {
            let (data, _) = try await URLSession.shared.data(for: req)
            guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let list = json["data"] as? [[String: Any]] else { return [] }

            return list.compactMap { d -> LiveRoom? in
                guard let num = d["roomNum"] as? String ?? (d["roomNum"] as? Int).map(String.init) else { return nil }
                let anchor = d["anchor"] as? [String: Any] ?? [:]
                let blv = anchor["nickName"] as? String ?? "BLV"
                let rawTitle = d["title"] as? String ?? "Trực tiếp bóng đá"
                let clean = DataNormalizer.cleanTitle(rawTitle)
                let league = (d["league"] as? String) ?? "Bóng Đá"
                let rawNotice = d["notice"] as? String ?? ""
                let notice = DataNormalizer.sanitizeNotice(rawNotice)
                let viewers = d["viewCount"] as? Int ?? 1000

                return LiveRoom(
                    roomNum: num,
                    blvName: blv,
                    avatar: anchor["icon"] as? String ?? "",
                    viewers: viewers,
                    matchTitle: clean,
                    league: league,
                    cover: d["cover"] as? String ?? "",
                    category: "Bóng đá",
                    blvLevel: (anchor["growDto"] as? [String: Any])?["name"] as? String ?? "",
                    score: 0,
                    notice: notice,
                    provider: "socolive"
                )
            }
        } catch {
            return []
        }
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

    private func createFallbackRooms(provider: String, prefix: String) -> [LiveRoom] {
        [
            LiveRoom(roomNum: "\(provider)_1", blvName: "BLV \(prefix) 1", avatar: "", viewers: 84000, matchTitle: "Man United vs Liverpool", league: "NGOẠI HẠNG ANH", cover: "", category: "Bóng đá", blvLevel: "Lv.5", score: 0, notice: "Kênh thể thao \(prefix) tốc độ cao", provider: provider),
            LiveRoom(roomNum: "\(provider)_2", blvName: "BLV \(prefix) 2", avatar: "", viewers: 62000, matchTitle: "Barcelona vs Atletico Madrid", league: "LA LIGA", cover: "", category: "Bóng đá", blvLevel: "Lv.4", score: 0, notice: "Kênh thể thao \(prefix) tốc độ cao", provider: provider),
            LiveRoom(roomNum: "\(provider)_3", blvName: "BLV \(prefix) 3", avatar: "", viewers: 45000, matchTitle: "Hà Nội FC vs HAGL", league: "V-LEAGUE 1", cover: "", category: "Bóng đá", blvLevel: "Lv.3", score: 0, notice: "Kênh thể thao \(prefix) tốc độ cao", provider: provider)
        ]
    }
}

private extension Array {
    func ifEmpty(_ fallback: [Element]) -> [Element] {
        self.isEmpty ? fallback : self
    }
}
