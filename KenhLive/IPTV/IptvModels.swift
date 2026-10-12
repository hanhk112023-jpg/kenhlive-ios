import Foundation

struct IptvChannel: Identifiable, Codable, Hashable {
    var id: String { channelId }
    let channelId: String
    let name: String
    let group: String
    let logo: String
    let streamUrl: String
    var isLive: Bool = true
    var resolution: String = "FHD"

    var isTv360: Bool {
        streamUrl.hasPrefix("tv360://")
    }
}

struct IptvCategory: Identifiable, Hashable {
    var id: String { name }
    let name: String
    let channels: [IptvChannel]
}
