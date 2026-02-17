//
//  RemoveHiddenElementsPass.swift
//  ReadabilityKit
//
//  Created by Chris Jenkins on 17/02/2026.
//

import Foundation
import SwiftSoup

/// Removes hidden and aria-hidden regions to prevent invisible chrome from winning candidate scoring.
struct RemoveHiddenElementsPass: DocumentCleaningPass {
    private let visibilityFilter = VisibilityFilter()

    func apply(to target: Document, options _: ExtractionOptions) throws {
        for element in try target.select("*").array() {
            if element.tagName().lowercased() == "html" || element.tagName().lowercased() == "body" {
                continue
            }
            if try !visibilityFilter.isProbablyVisible(element) {
                try element.remove()
            }
        }
    }
}
