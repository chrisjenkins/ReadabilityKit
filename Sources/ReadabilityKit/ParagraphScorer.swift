//
//  ParagraphScorer.swift
//  ReadabilityKit
//
//  Created by Chris Jenkins on 16/02/2026.
//

import Foundation
import SwiftSoup

/// Scores paragraph-like nodes based on text quality and link-density penalties.
struct ParagraphScorer: ElementScorer {
    private let linkDensityScorer: LinkDensityScorer

    init(linkDensityScorer: LinkDensityScorer = .init()) {
        self.linkDensityScorer = linkDensityScorer
    }

    func score(_ element: Element) throws -> Double {
        let text = try element.text().trimmingCharacters(in: .whitespacesAndNewlines)
        let len = text.count
        guard len >= 25 else { return 0 }

        var score = 0.0
        score += 1.0
        score += Double(text.filter { $0 == "," }.count)
        score += min(3.0, Double(len) / 100.0)

        let ld = try linkDensityScorer.score(element)
        score *= (1.0 - min(0.8, ld))

        let tag = element.tagName().lowercased()
        if tag == "p" || tag == "blockquote" || tag == "pre" || tag == "td" {
            score += 2.0
        }

        return score
    }
}
