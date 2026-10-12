import Foundation

struct LiveRoom: Identifiable, Codable, Hashable {
    var id: String { roomNum }
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

    var formattedViewers: String {
        DataNormalizer.formatViewers(viewers)
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
}

struct StreamServer: Identifiable, Hashable {
    var id: String { name + url }
    let name: String
    let url: String
    let isBackup: Bool
}

struct ScheduleItem: Identifiable, Codable, Hashable {
    var id: String { "\(homeName)_\(awayName)_\(matchTime)" }
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
}
