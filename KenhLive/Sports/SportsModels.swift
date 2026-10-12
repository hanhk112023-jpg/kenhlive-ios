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
        let parts = matchTitle.components(separatedBy: " vs ")
        return parts.first?.trimmingCharacters(in: .whitespaces) ?? matchTitle
    }

    var awayTeamName: String {
        let top = topRoom
        if !top.awayTeam.isEmpty { return top.awayTeam }
        let parts = matchTitle.components(separatedBy: " vs ")
        return parts.count > 1 ? parts[1].trimmingCharacters(in: .whitespaces) : ""
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
