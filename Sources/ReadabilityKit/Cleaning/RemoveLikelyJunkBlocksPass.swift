//
//  RemoveLikelyJunkBlocksPass.swift
//  ReadabilityKit
//
//  Created by Chris Jenkins on 16/02/2026.
//

import Foundation
import SwiftSoup

/// Removes common junk blocks such as sharing widgets, promos, and recommendation sections.
struct RemoveLikelyJunkBlocksPass: ElementCleaningPass {
    func apply(to target: Element, options _: ExtractionOptions) throws {
        let selectors = [
            "[class*=share]", "[id*=share]",
            "[class*=social]", "[id*=social]",
            "[class*=newsletter]", "[id*=newsletter]",
            "[class*=subscribe]", "[id*=subscribe]",
            "[class*=cookie]", "[id*=cookie]",
            "[class*=banner]", "[id*=banner]",
            "[class*=promo]", "[id*=promo]",
            "[class*=related]", "[id*=related]",
            "[class*=recommend]", "[id*=recommend]",
        ]
        for sel in selectors {
            for el in try target.select(sel).array() { try el.remove() }
        }
    }
}
