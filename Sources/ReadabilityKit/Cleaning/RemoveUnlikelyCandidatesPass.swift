//
//  RemoveUnlikelyCandidatesPass.swift
//  ReadabilityKit
//
//  Created by Chris Jenkins on 16/02/2026.
//

import Foundation
import SwiftSoup

/// Removes nodes likely to be chrome/boilerplate while preserving positive content markers.
struct RemoveUnlikelyCandidatesPass: DocumentCleaningPass {
    private let unlikelyPatterns: [String] = [
        "comment", "meta", "footer", "foot", "masthead", "sidebar", "sponsor", "promo",
        "related", "outbrain", "taboola", "ad-", "ads", "advert", "cookie", "subscribe",
        "newsletter", "nav", "share", "social", "breadcrumbs", "recommend",
    ]

    private let positivePatterns: [String] = [
        "article", "content", "entry", "main", "page", "post", "text", "body", "story"
    ]

    func apply(to target: Document, options _: ExtractionOptions) throws {
        for el in try target.select("*").array() {
            let idClass = (try el.id() + " " + el.className()).lowercased()
            if unlikelyPatterns.contains(where: { idClass.contains($0) }) {
                if positivePatterns.contains(where: { idClass.contains($0) }) { continue }
                try el.remove()
            }
        }
    }
}
