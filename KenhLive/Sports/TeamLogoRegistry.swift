import Foundation
import SwiftUI

/// Kho dữ liệu Logo Đội Bóng Thời Gian Thực (Real-Time Team Logo Registry).
/// Đồng bộ và làm giàu logo các đội bóng từ:
/// 1. API 4 nhà đài thể thao (ColaTV, Gà Vàng 33, Giờ Vàng TV, Socolive)
/// 2. Kho logo chính thức 500x500 PNG sắc nét từ ESPN CDN cho các CLB hàng đầu thế giới
final class TeamLogoRegistry {
    static let shared = TeamLogoRegistry()

    private var registry: [String: String] = [:]
    private let lock = NSLock()

    private init() {
        seedTopClubs()
    }

    func normalize(_ name: String) -> String {
        guard !name.isEmpty else { return "" }
        var n = name.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        // Loại bỏ ngoặc vuông, ngoặc tròn, vs, gạch ngang
        n = n.replacingOccurrences(of: "\\[.*?\\]", with: " ", options: .regularExpression)
        n = n.replacingOccurrences(of: "\\(.*?\\)", with: " ", options: .regularExpression)
        n = n.replacingOccurrences(of: "vs\.?", with: " ", options: .regularExpression)
        n = n.replacingOccurrences(of: "-", with: " ")
        // Chỉ giữ chữ cái tiếng Việt và số
        n = n.replacingOccurrences(of: "[^a-zA-Z0-9\\u00C0-\\u1EF9 ]", with: "", options: .regularExpression)
        return n.trimmingCharacters(in: .whitespaces)
    }

    private func simplify(_ name: String) -> String {
        guard !name.isEmpty else { return "" }
        var n = name.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        let pattern = "\\b(fc|cf|sc|ac|clb|club|u\\d+|united|city|real|sporting|atletico|borussia)\\b"
        n = n.replacingOccurrences(of: pattern, with: " ", options: [.regularExpression, .caseInsensitive])
        n = n.replacingOccurrences(of: "[^a-zA-Z0-9\\u00C0-\\u1EF9 ]", with: "", options: .regularExpression)
        return n.trimmingCharacters(in: .whitespaces)
    }

    func register(teamName: String, logoUrl: String) {
        guard !teamName.isEmpty, !logoUrl.isEmpty else { return }
        lock.lock()
        defer { lock.unlock() }

        let norm = normalize(teamName)
        if !norm.isEmpty {
            registry[norm] = logoUrl
        }
        let simp = simplify(teamName)
        if !simp.isEmpty && registry[simp] == nil {
            registry[simp] = logoUrl
        }
    }

    func findLogo(for teamName: String) -> String? {
        guard !teamName.isEmpty else { return nil }
        lock.lock()
        defer { lock.unlock() }

        let norm = normalize(teamName)
        if let url = registry[norm] { return url }

        let simp = simplify(teamName)
        if let url = registry[simp] { return url }

        // Tìm kiếm đối sánh gần đúng (contains)
        if norm.count >= 4 {
            for (key, url) in registry where key.count >= 4 {
                if norm.contains(key) || key.contains(norm) {
                    return url
                }
            }
        }
        if simp.count >= 4 {
            for (key, url) in registry where key.count >= 4 {
                if simp.contains(key) || key.contains(simp) {
                    return url
                }
            }
        }
        return nil
    }

    func enrich(group: LiveMatchGroup) -> LiveMatchGroup {
        let homeName = group.homeTeamName
        let awayName = group.awayTeamName

        let top = group.topRoom
        let homeLogo = !top.homeLogo.isEmpty ? top.homeLogo : (findLogo(for: homeName) ?? "")
        let awayLogo = !top.awayLogo.isEmpty ? top.awayLogo : (findLogo(for: awayName) ?? "")

        if homeLogo == top.homeLogo && awayLogo == top.awayLogo {
            return group
        }

        // Cập nhật rooms với logo mới
        let updatedRooms = group.rooms.map { r -> LiveRoom in
            var copy = r
            if copy.homeLogo.isEmpty { copy.homeLogo = homeLogo }
            if copy.awayLogo.isEmpty { copy.awayLogo = awayLogo }
            return copy
        }

        return LiveMatchGroup(
            matchKey: group.matchKey,
            matchTitle: group.matchTitle,
            league: group.league,
            rooms: updatedRooms
        )
    }

    private func seedTopClubs() {
        // Kho logo chất lượng cao 500x500 PNG trong suốt từ ESPN CDN
        let clubs: [(String, String)] = [
            // Premier League (Ngoại Hạng Anh)
            ("manchester city", "https://a.espncdn.com/i/teamlogos/soccer/500/382.png"),
            ("man city", "https://a.espncdn.com/i/teamlogos/soccer/500/382.png"),
            ("manchester united", "https://a.espncdn.com/i/teamlogos/soccer/500/360.png"),
            ("man united", "https://a.espncdn.com/i/teamlogos/soccer/500/360.png"),
            ("mu", "https://a.espncdn.com/i/teamlogos/soccer/500/360.png"),
            ("liverpool", "https://a.espncdn.com/i/teamlogos/soccer/500/364.png"),
            ("arsenal", "https://a.espncdn.com/i/teamlogos/soccer/500/359.png"),
            ("chelsea", "https://a.espncdn.com/i/teamlogos/soccer/500/363.png"),
            ("tottenham hotspur", "https://a.espncdn.com/i/teamlogos/soccer/500/367.png"),
            ("tottenham", "https://a.espncdn.com/i/teamlogos/soccer/500/367.png"),
            ("spurs", "https://a.espncdn.com/i/teamlogos/soccer/500/367.png"),
            ("aston villa", "https://a.espncdn.com/i/teamlogos/soccer/500/362.png"),
            ("newcastle united", "https://a.espncdn.com/i/teamlogos/soccer/500/361.png"),
            ("newcastle", "https://a.espncdn.com/i/teamlogos/soccer/500/361.png"),
            ("west ham united", "https://a.espncdn.com/i/teamlogos/soccer/500/371.png"),
            ("west ham", "https://a.espncdn.com/i/teamlogos/soccer/500/371.png"),
            ("brighton", "https://a.espncdn.com/i/teamlogos/soccer/500/331.png"),
            ("everton", "https://a.espncdn.com/i/teamlogos/soccer/500/368.png"),
            ("fulham", "https://a.espncdn.com/i/teamlogos/soccer/500/370.png"),
            ("wolverhampton", "https://a.espncdn.com/i/teamlogos/soccer/500/380.png"),
            ("wolves", "https://a.espncdn.com/i/teamlogos/soccer/500/380.png"),
            ("brentford", "https://a.espncdn.com/i/teamlogos/soccer/500/337.png"),
            ("crystal palace", "https://a.espncdn.com/i/teamlogos/soccer/500/384.png"),
            ("bournemouth", "https://a.espncdn.com/i/teamlogos/soccer/500/349.png"),
            ("nottingham forest", "https://a.espncdn.com/i/teamlogos/soccer/500/393.png"),

            // La Liga (Tây Ban Nha)
            ("real madrid", "https://a.espncdn.com/i/teamlogos/soccer/500/86.png"),
            ("barcelona", "https://a.espncdn.com/i/teamlogos/soccer/500/83.png"),
            ("barca", "https://a.espncdn.com/i/teamlogos/soccer/500/83.png"),
            ("atletico madrid", "https://a.espncdn.com/i/teamlogos/soccer/500/1068.png"),
            ("sevilla", "https://a.espncdn.com/i/teamlogos/soccer/500/243.png"),
            ("real betis", "https://a.espncdn.com/i/teamlogos/soccer/500/244.png"),
            ("real sociedad", "https://a.espncdn.com/i/teamlogos/soccer/500/89.png"),
            ("villarreal", "https://a.espncdn.com/i/teamlogos/soccer/500/102.png"),
            ("athletic bilbao", "https://a.espncdn.com/i/teamlogos/soccer/500/93.png"),
            ("valencia", "https://a.espncdn.com/i/teamlogos/soccer/500/94.png"),
            ("girona", "https://a.espncdn.com/i/teamlogos/soccer/500/9812.png"),

            // Serie A (Ý)
            ("juventus", "https://a.espncdn.com/i/teamlogos/soccer/500/111.png"),
            ("inter milan", "https://a.espncdn.com/i/teamlogos/soccer/500/110.png"),
            ("inter", "https://a.espncdn.com/i/teamlogos/soccer/500/110.png"),
            ("ac milan", "https://a.espncdn.com/i/teamlogos/soccer/500/103.png"),
            ("milan", "https://a.espncdn.com/i/teamlogos/soccer/500/103.png"),
            ("napoli", "https://a.espncdn.com/i/teamlogos/soccer/500/114.png"),
            ("roma", "https://a.espncdn.com/i/teamlogos/soccer/500/104.png"),
            ("as roma", "https://a.espncdn.com/i/teamlogos/soccer/500/104.png"),
            ("lazio", "https://a.espncdn.com/i/teamlogos/soccer/500/112.png"),
            ("atalanta", "https://a.espncdn.com/i/teamlogos/soccer/500/125.png"),
            ("fiorentina", "https://a.espncdn.com/i/teamlogos/soccer/500/109.png"),

            // Bundesliga (Đức)
            ("bayern munich", "https://a.espncdn.com/i/teamlogos/soccer/500/132.png"),
            ("bayern", "https://a.espncdn.com/i/teamlogos/soccer/500/132.png"),
            ("borussia dortmund", "https://a.espncdn.com/i/teamlogos/soccer/500/124.png"),
            ("dortmund", "https://a.espncdn.com/i/teamlogos/soccer/500/124.png"),
            ("bayer leverkusen", "https://a.espncdn.com/i/teamlogos/soccer/500/131.png"),
            ("leverkusen", "https://a.espncdn.com/i/teamlogos/soccer/500/131.png"),
            ("rb leipzig", "https://a.espncdn.com/i/teamlogos/soccer/500/11420.png"),
            ("leipzig", "https://a.espncdn.com/i/teamlogos/soccer/500/11420.png"),
            ("eintracht frankfurt", "https://a.espncdn.com/i/teamlogos/soccer/500/126.png"),
            ("stuttgart", "https://a.espncdn.com/i/teamlogos/soccer/500/134.png"),

            // Ligue 1 & Khác
            ("paris saint-germain", "https://a.espncdn.com/i/teamlogos/soccer/500/160.png"),
            ("psg", "https://a.espncdn.com/i/teamlogos/soccer/500/160.png"),
            ("marseille", "https://a.espncdn.com/i/teamlogos/soccer/500/166.png"),
            ("monaco", "https://a.espncdn.com/i/teamlogos/soccer/500/174.png"),
            ("lyon", "https://a.espncdn.com/i/teamlogos/soccer/500/167.png"),
            ("sporting cp", "https://a.espncdn.com/i/teamlogos/soccer/500/442.png"),
            ("sporting lisbon", "https://a.espncdn.com/i/teamlogos/soccer/500/442.png"),
            ("benfica", "https://a.espncdn.com/i/teamlogos/soccer/500/1929.png"),
            ("porto", "https://a.espncdn.com/i/teamlogos/soccer/500/437.png"),
            ("ajax", "https://a.espncdn.com/i/teamlogos/soccer/500/139.png"),
            ("al nassr", "https://a.espncdn.com/i/teamlogos/soccer/500/7339.png"),
            ("inter miami", "https://a.espncdn.com/i/teamlogos/soccer/500/20232.png")
        ]

        for (name, url) in clubs {
            register(teamName: name, logoUrl: url)
        }
    }
}

/// Huy hiệu khiên thể thao viền bạc sang trọng làm placeholder khi chưa tải kịp logo
struct SportsShieldPlaceholder: View {
    var size: CGFloat = 34

    var body: some View {
        ZStack {
            // Nền gradient obsidian tối giản
            RoundedRectangle(cornerRadius: size * 0.28)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.14, green: 0.16, blue: 0.22),
                            Color(red: 0.08, green: 0.09, blue: 0.13)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: size, height: size)
                .overlay(
                    RoundedRectangle(cornerRadius: size * 0.28)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    Color(red: 0.45, green: 0.50, blue: 0.60),
                                    Color(red: 0.22, green: 0.25, blue: 0.32)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )

            // Biểu tượng khiên / quả bóng thể thao
            Image(systemName: "shield.fill")
                .font(.system(size: size * 0.48, weight: .bold))
                .foregroundColor(Color(red: 0.65, green: 0.70, blue: 0.80).opacity(0.85))
        }
    }
}
