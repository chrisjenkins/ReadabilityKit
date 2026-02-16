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
        let idClass = (try element.id() + " " + element.className()).lowercased()
        var weight = 0.0

        let negatives = [
            "comment", "meta", "footer", "foot", "sidebar", "sponsor", "promo", "ad", "ads", "advert", "nav", "share",
            "social", "cookie", "subscribe", "newsletter", "recommend", "related",
        ]
        if negatives.contains(where: { idClass.contains($0) }) { weight -= 25 }

        let positives = ["article", "content", "entry", "main", "page", "post", "text", "body", "story"]
        if positives.contains(where: { idClass.contains($0) }) { weight += 25 }

        return weight
    }
}
