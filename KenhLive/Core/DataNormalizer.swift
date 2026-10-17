import Foundation

enum DataNormalizer {
    static let timeZoneVN: TimeZone = TimeZone(identifier: "Asia/Ho_Chi_Minh") ?? TimeZone(secondsFromGMT: 7 * 3600) ?? .current

    private static let spamPattern = try? NSRegularExpression(
        pattern: "(nhóm|nhom|vip|zalo|tele|liên hệ|lien he|trợ lý|tro ly|lộc|loc|code|km|cược|nhà cái|@|\\d{8,})",
        options: [.caseInsensitive]
    )

    private static let noisePatterns: [NSRegularExpression] = [
        "\\[HOT\\]",
        "\\[VIP\\]",
        "\\[FULL\\s*HD\\]",
        "\\[HD\\]",
        "\\(Link\\s*\\d+\\)",
        "\\(Trực\\s*tiếp\\)",
        "Trực\\s*tiếp:?",
        "\\|\\s*BLV.*$",
        "-\\s*BLV.*$",
        "\\(Bình\\s*luận.*\\)"
    ].compactMap { try? NSRegularExpression(pattern: $0, options: .caseInsensitive) }

    static func cleanTitle(_ raw: String) -> String {
        var s = raw
        for p in noisePatterns {
            let range = NSRange(location: 0, length: s.utf16.count)
            s = p.stringByReplacingMatches(in: s, options: [], range: range, withTemplate: "")
        }
        return s.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    static func sanitizeNotice(_ notice: String) -> String {
        let trimmed = notice.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty { return "Bình luận trực tiếp · Chất lượng cao" }
        if let regex = spamPattern {
            let range = NSRange(location: 0, length: trimmed.utf16.count)
            if regex.firstMatch(in: trimmed, options: [], range: range) != nil {
                return "Bình luận trực tiếp · Tiếng Việt HD"
            }
        }
        return trimmed
    }

    static func formatGMT7Date(_ date: Date) -> String {
        let df = DateFormatter()
        df.timeZone = timeZoneVN
        df.locale = Locale(identifier: "vi_VN")
        df.dateFormat = "HH:mm · EEEE, dd/MM"
        return df.string(from: date)
    }

    static func formatGMT7Time(_ date: Date) -> String {
        let df = DateFormatter()
        df.timeZone = timeZoneVN
        df.dateFormat = "HH:mm"
        return df.string(from: date)
    }

    static func formatViewers(_ count: Int) -> String {
        if count >= 1_000_000 {
            return String(format: "%.1fM", Double(count) / 1_000_000.0)
        } else if count >= 1_000 {
            return String(format: "%.1fK", Double(count) / 1_000.0)
        }
        return "\(count)"
    }
}
