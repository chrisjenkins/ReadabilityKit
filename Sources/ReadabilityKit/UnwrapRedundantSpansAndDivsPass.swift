//
//  UnwrapRedundantSpansAndDivsPass.swift
//  ReadabilityKit
//
//  Created by Chris Jenkins on 16/02/2026.
//

import Foundation
import SwiftSoup

/// Unwraps redundant span/div containers that do not contribute semantic structure.
struct UnwrapRedundantSpansAndDivsPass: ElementCleaningPass {
    func apply(to target: Element, options _: ExtractionOptions) throws {
        let unwrapTags: Set<String> = ["span", "div"]
        for el in try target.select("div, span").array() {
            let tag = el.tagName().lowercased()
            guard unwrapTags.contains(tag) else { continue }

            let hasAttributes = !(el.getAttributes()?.asList().isEmpty == true)
            if hasAttributes { continue }

            let hasBlocks = (try el.select("p,ul,ol,li,blockquote,pre,code,figure,table,h1,h2,h3,h4,h5,h6").size()) > 0
            if hasBlocks { continue }

            try el.unwrap()
        }
    }
}
