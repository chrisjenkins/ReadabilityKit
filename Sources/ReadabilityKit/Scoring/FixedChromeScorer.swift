//
//  FixedChromeScorer.swift
//  ReadabilityKit
//
//  Penalizes likely fixed/sticky navigation chrome such as top bars and side rails.
//

import Foundation
import SwiftSoup

struct FixedChromeScorer: ElementScorer {
    private let linkDensityScorer: LinkDensityScorer

    init(linkDensityScorer: LinkDensityScorer = .init()) {
        self.linkDensityScorer = linkDensityScorer
    }

    func score(_ element: Element) throws -> Double {
        let style = try element.attr("style").lowercased()
        let id = element.id().lowercased()
        let className = try element.className().lowercased()
        let idClass = "\(id) \(className)"
        let role = try element.attr("role").lowercased()
        let ariaLabel = try element.attr("aria-label").lowercased()

        var penalty = 0.0

        if style.contains("position:fixed") || style.contains("position: fixed")
            || style.contains("position:sticky") || style.contains("position: sticky")
        {
            penalty -= 35
        }

        if containsTopAnchoringSignals(style) {
            penalty -= 20
        }

        if hasSmallChromeLikeHeight(style) {
            penalty -= 15
        }

        if RegexRules.matches(RegexRules.chromeClassOrID, in: idClass) {
            penalty -= 20
        }

        if role == "navigation" || RegexRules.matches(RegexRules.navLikeLabel, in: ariaLabel) {
            penalty -= 20
        }

        let text = try element.text().trimmingCharacters(in: .whitespacesAndNewlines)
        let linkDensity = try linkDensityScorer.score(element)
        if linkDensity > 0.65 && text.count < 280 {
            penalty -= 20
        }

        if penalty == 0 {
            return 0
        }

        // Safeguard for true content blocks that happen to be sticky/fixed.
        if isLikelyContentContainer(element: element, idClass: idClass) {
            penalty = max(penalty, -20)
        }

        return max(-120, min(0, penalty))
    }

    private func containsTopAnchoringSignals(_ style: String) -> Bool {
        style.contains("top:0")
            || style.contains("top: 0")
            || (style.contains("left:0") && style.contains("right:0"))
            || (style.contains("left: 0") && style.contains("right: 0"))
    }

    private func hasSmallChromeLikeHeight(_ style: String) -> Bool {
        guard let regex = try? NSRegularExpression(
            pattern: #"(?:^|;)\s*(?:max-)?height\s*:\s*([0-9]{1,4})px"#,
            options: [.caseInsensitive]
        ) else {
            return false
        }
        let ns = style as NSString
        let range = NSRange(location: 0, length: ns.length)
        guard let match = regex.firstMatch(in: style, options: [], range: range), match.numberOfRanges > 1 else {
            return false
        }
        let heightString = ns.substring(with: match.range(at: 1))
        guard let height = Int(heightString) else { return false }
        return height <= 140
    }

    private func isLikelyContentContainer(element: Element, idClass: String) -> Bool {
        guard RegexRules.matches(RegexRules.contentLike, in: idClass) else {
            return false
        }
        let paragraphCount = (try? element.select("p").count) ?? 0
        return paragraphCount >= 3
    }
}

private enum RegexRules {
    static let chromeClassOrID = try! NSRegularExpression( // swiftlint:disable:this force_try
        pattern: #"(^|[\W_])(sticky|affix|topbar|toolbar|navbar|global-nav|site-header|rail|sidebar|floating)(?=$|[\W_])"#,
        options: [.caseInsensitive]
    )
    static let navLikeLabel = try! NSRegularExpression( // swiftlint:disable:this force_try
        pattern: #"(nav|menu)"#,
        options: [.caseInsensitive]
    )
    static let contentLike = try! NSRegularExpression( // swiftlint:disable:this force_try
        pattern: #"(^|[\W_])(article|content|story|post|entry)(?=$|[\W_])"#,
        options: [.caseInsensitive]
    )

    static func matches(_ regex: NSRegularExpression, in text: String) -> Bool {
        guard !text.isEmpty else { return false }
        let range = NSRange(text.startIndex..<text.endIndex, in: text)
        return regex.firstMatch(in: text, options: [], range: range) != nil
    }
}
