//
//  VisibilityFilter.swift
//  ReadabilityKit
//
//  Created by Chris Jenkins on 17/02/2026.
//

import Foundation
import SwiftSoup

/// Filters nodes that are clearly hidden and should not participate in extraction heuristics.
struct VisibilityFilter {
    func isProbablyVisible(_ element: Element) throws -> Bool {
        if try isDefinitelyHidden(element) { return false }

        var current = element.parent()
        while let ancestor = current {
            if try isDefinitelyHidden(ancestor) { return false }
            current = ancestor.parent()
        }

        return true
    }

    private func isDefinitelyHidden(_ element: Element) throws -> Bool {
        let inputType = try element.attr("type").lowercased()
        if element.tagName().lowercased() == "input" && inputType == "hidden" {
            return true
        }

        if element.hasAttr("hidden") { return true }
        if try element.attr("aria-hidden").lowercased() == "true" { return true }

        let style = try element.attr("style").lowercased()
        if style.isEmpty { return false }

        // Match strict hidden declarations while avoiding over-aggressive style pruning.
        if style.range(of: #"display\s*:\s*none"#, options: .regularExpression) != nil { return true }
        if style.range(of: #"visibility\s*:\s*hidden"#, options: .regularExpression) != nil { return true }

        return false
    }
}
