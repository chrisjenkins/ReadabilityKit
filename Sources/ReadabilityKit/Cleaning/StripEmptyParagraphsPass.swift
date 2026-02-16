//
//  StripEmptyParagraphsPass.swift
//  ReadabilityKit
//
//  Created by Chris Jenkins on 16/02/2026.
//

import Foundation
import SwiftSoup

/// Drops paragraph nodes that do not contain readable text.
struct StripEmptyParagraphsPass: ElementCleaningPass {
    func apply(to target: Element, options _: ExtractionOptions) throws {
        for p in try target.select("p").array() {
            let text = try p.text().trimmingCharacters(in: .whitespacesAndNewlines)
            if text.isEmpty { try p.remove() }
        }
    }
}
