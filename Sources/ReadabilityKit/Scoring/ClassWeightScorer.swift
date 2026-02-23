//
//  ClassWeightScorer.swift
//  ReadabilityKit
//
//  Created by Chris Jenkins on 16/02/2026.
//

import Foundation
import SwiftSoup

/// Scores an element using positive and negative signals from its class and id attributes.
struct ClassWeightScorer: ElementScorer {
    func score(_ element: Element) throws -> Double {
        let id = element.id()
        let className = try element.className()
        let idClass = id + " " + className
        var weight = 0.0

        if RegexRules.matches(RegexRules.positive, in: id) { weight += 25 }
        if RegexRules.matches(RegexRules.positive, in: className) { weight += 20 }

        if RegexRules.matches(RegexRules.negative, in: id) { weight -= 25 }
        if RegexRules.matches(RegexRules.negative, in: className) { weight -= 20 }

        if RegexRules.matches(RegexRules.unlikelyCandidates, in: idClass),
            !RegexRules.matches(RegexRules.okMaybeCandidate, in: idClass)
        {
            weight -= 30
        }

        return max(-75, min(75, weight))
    }
}

private enum RegexRules {
    // Adapted from Readability-style class/id heuristics with stricter word boundaries.
    private static let boundary = "(^|[\\W_])(%@)(?=$|[\\W_])"

    private static func compile(_ alternatives: String) -> NSRegularExpression {
        let pattern = String(format: boundary, alternatives)
        return try! NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) // swiftlint:disable:this force_try
    }

    static let positive = compile(
        "article|body|content|entry|hentry|main|page|pagination|post|story|text|blog|news|markdown"
    )
    static let negative = compile(
        "comment|combx|contact|footer|footnote|masthead|media|meta|outbrain|promo|related|scroll|shoutbox|sidebar|sponsor|shopping|tags|tool|widget|nav|menu|share|social|subscribe|newsletter|cookie|ad(?![a-z])|advert"
    )
    static let unlikelyCandidates = compile(
        "banner|breadcrumbs|complementary|disqus|extra|header|menu|remark|rss|shopping|sponsor|ad-break|nav"
    )
    static let okMaybeCandidate = compile(
        "article|body|column|content|main|shadow"
    )

    static func matches(_ regex: NSRegularExpression, in text: String) -> Bool {
        guard !text.isEmpty else { return false }
        let range = NSRange(text.startIndex..<text.endIndex, in: text)
        return regex.firstMatch(in: text, options: [], range: range) != nil
    }
}
