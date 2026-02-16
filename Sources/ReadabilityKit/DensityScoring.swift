//
//  DensityScoring.swift
//  ReadabilityKit
//
//  Created by Chris Jenkins on 15/02/2026.
//


import Foundation
import SwiftSoup

enum DensityScoring {

    static func score(element: Element) throws -> Double {
        let textLen = try visibleTextLength(of: element)
        if textLen < 80 { return 0 }

        let depth = domDepth(of: element)
        let linkPenalty = try 1.0 + Scoring.linkDensity(element) * 2.5
        let tagPenalty = structuralTagPenalty(element)

        return Double(textLen) / (Double(depth) * linkPenalty * tagPenalty)
    }

    static func domDepth(of element: Element) -> Int {
        var depth = 0
        var current: Element? = element
        while let parent = current?.parent() {
            depth += 1
            current = parent
        }
        return max(1, depth)
    }

    private static func visibleTextLength(of element: Element) throws -> Int {
        let text = try element.text()
            .replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return text.count
    }

    private static func structuralTagPenalty(_ element: Element) -> Double {
        switch element.tagName().lowercased() {
        case "article", "main", "section": return 1.0
        case "div": return 1.2
        case "td": return 1.5
        case "nav", "aside", "footer", "header": return 3.0
        default: return 1.4
        }
    }
}