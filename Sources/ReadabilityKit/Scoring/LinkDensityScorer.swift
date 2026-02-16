//
//  LinkDensityScorer.swift
//  ReadabilityKit
//
//  Created by Chris Jenkins on 16/02/2026.
//

import Foundation
import SwiftSoup

/// Scores an element by the ratio of link text to total text.
struct LinkDensityScorer: ElementScorer {
    func score(_ element: Element) throws -> Double {
        let text = try element.text()
        let textCount = max(1, text.count)
        let linkText = try element.select("a").text().count
        return Double(linkText) / Double(textCount)
    }
}
