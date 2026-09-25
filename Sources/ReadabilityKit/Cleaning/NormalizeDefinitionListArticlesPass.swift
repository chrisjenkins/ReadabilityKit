//
//  NormalizeDefinitionListArticlesPass.swift
//  ReadabilityKit
//

import Foundation
import SwiftSoup

/// Converts single-entry definition lists used as article wrappers into readable blocks.
///
/// Multi-entry lists and short definitions keep their original semantics.
struct NormalizeDefinitionListArticlesPass: ElementCleaningPass {
    func apply(to target: Element, options _: ExtractionOptions) throws {
        for list in try target.select("dl").array() {
            let children = list.children().array()
            guard children.count == 2,
                children[0].tagName().lowercased() == "dt",
                children[1].tagName().lowercased() == "dd"
            else {
                continue
            }

            let term = children[0]
            let description = children[1]
            let text = try description.text().trimmingCharacters(in: .whitespacesAndNewlines)
            let proseBlocks = try description.select("p, blockquote").size()
            let linkedTitle = try term.select("a[href]").size() > 0
            guard text.count >= 40, proseBlocks > 0, linkedTitle || proseBlocks > 1 else {
                continue
            }

            let replacement = Element(Tag("div"), list.getBaseUri())
            let heading = Element(Tag("h2"), list.getBaseUri())
            for child in term.getChildNodes() {
                try heading.appendChild(child.copy() as! Node)
            }
            try replacement.appendChild(heading)
            for child in description.getChildNodes() {
                try replacement.appendChild(child.copy() as! Node)
            }
            try list.replaceWith(replacement)
        }
    }
}
