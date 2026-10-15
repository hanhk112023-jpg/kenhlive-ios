import Foundation

struct LiveRoom: Identifiable, Codable, Hashable {
    var id: String { roomNum + "_" + blvName + "_" + directStreamUrl }
    let roomNum: String
    let blvName: String
    let avatar: String
    let viewers: Int
    let matchTitle: String
    let league: String
    let cover: String
    let category: String
    let blvLevel: String
    let score: Int
    let notice: String
    var provider: String = "socolive"
    var directStreamUrl: String = ""
    var streamReferer: String = ""
    var homeTeam: String = ""
    var awayTeam: String = ""
    var homeLogo: String = ""
    var awayLogo: String = ""

    var formattedViewers: String {
        DataNormalizer.formatViewers(viewers)
    }

    var providerDisplayName: String {
        switch provider.lowercased() {
        case "gavang", "gavang33": return "GÀ VÀNG 33"
        case "colatv", "cola": return "COLATV"
        case "giovang": return "GIỜ VÀNG TV"
        case "khandai": return "GIỜ VÀNG TV"
        default: return "SOCOLIVE"
        }
    }
}

struct LiveMatchGroup: Identifiable, Hashable {
    var id: String { matchKey }
    let matchKey: String
    let matchTitle: String
    let league: String
    let rooms: [LiveRoom]

    var topRoom: LiveRoom {
        rooms.first ?? LiveRoom(roomNum: "", blvName: "BLV", avatar: "", viewers: 0, matchTitle: matchTitle, league: league, cover: "", category: "", blvLevel: "", score: 0, notice: "")
    }

    var totalViewers: Int {
        rooms.reduce(0) { $0 + $1.viewers }
    }

    var homeTeamName: String {
        let top = topRoom
        if !top.homeTeam.isEmpty { return top.homeTeam }
        var title = matchTitle
        if let score = liveScore {
            title = title.replacingOccurrences(of: score, with: "vs")
        }
        title = title.replacingOccurrences(of: "[SẮP ĐÁ]", with: "")
        title = title.replacingOccurrences(of: "[SẮP DIỄN RA]", with: "")
        let parts = title.components(separatedBy: " vs ")
        return parts.first?.trimmingCharacters(in: .whitespaces) ?? matchTitle
    }

    var awayTeamName: String {
        let top = topRoom
        if !top.awayTeam.isEmpty { return top.awayTeam }
        var title = matchTitle
        if let score = liveScore {
            title = title.replacingOccurrences(of: score, with: "vs")
        }
        title = title.replacingOccurrences(of: "[SẮP ĐÁ]", with: "")
        title = title.replacingOccurrences(of: "[SẮP DIỄN RA]", with: "")
        let parts = title.components(separatedBy: " vs ")
        return parts.count > 1 ? parts[1].trimmingCharacters(in: .whitespaces) : ""
    }

    var homeLogoUrl: String {
        let top = topRoom
        return !top.homeLogo.isEmpty ? top.homeLogo : (TeamLogoRegistry.shared.findLogo(for: homeTeamName) ?? "")
    }

    var awayLogoUrl: String {
        let top = topRoom
        return !top.awayLogo.isEmpty ? top.awayLogo : (TeamLogoRegistry.shared.findLogo(for: awayTeamName) ?? "")
    }

    var liveScore: String? {
        let text = matchTitle + " " + topRoom.notice
        let pattern = "\\b(\\d{1,2})\\s*-\\s*(\\d{1,2})\\b"
        if let regex = try? NSRegularExpression(pattern: pattern, options: []) {
            let nsText = text as NSString
            if let match = regex.firstMatch(in: text, options: [], range: NSRange(location: 0, length: nsText.length)) {
                return nsText.substring(with: match.range).replacingOccurrences(of: " ", with: "")
                    .replacingOccurrences(of: "-", with: " - ")
            }
        }
        return nil
    }

    var isScheduled: Bool {
        matchTitle.contains("[SẮP ĐÁ]") || matchTitle.contains("[SẮP DIỄN RA]")
    }

    var provider: String {
        topRoom.provider
    }

    var providerDisplayName: String {
        topRoom.providerDisplayName
    }
}

struct StreamServer: Identifiable, Hashable {
    var id: String { name + url }
    let name: String
    let url: String
    let isBackup: Bool
    var referer: String = ""
}

struct ScheduleItem: Identifiable, Codable, Hashable {
    var id: String { "\(homeName)_\(awayName)_\(matchTime)_\(roomNum)_\(blvName)" }
    let homeName: String
    let awayName: String
    let homeLogo: String
    let awayLogo: String
    let league: String
    let matchTime: String
    let statusText: String
    let homeScore: String
    let awayScore: String
    let hasLive: Bool
    var roomNum: String = ""
    var blvName: String = "BLV Socolive"
}
