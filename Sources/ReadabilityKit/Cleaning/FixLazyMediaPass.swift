//
//  FixLazyMediaPass.swift
//  ReadabilityKit
//
//  Created by Chris Jenkins on 16/02/2026.
//

import Foundation
import SwiftSoup

/// Repairs lazy-loaded media attributes and removes obvious tracking pixels.
struct FixLazyMediaPass: ElementCleaningPass {
    func apply(to target: Element, options _: ExtractionOptions) throws {
        for img in try target.select("img").array() {
            let classNames = (try? img.className()) ?? ""
            if containsHiddenClass(classNames) {
                try img.remove()
                continue
            }
            let candidates = ["data-src", "data-original", "data-lazy-src", "data-url", "data-img"]
            if (try img.attr("src")).isEmpty {
                for attr in candidates {
                    let v = try img.attr(attr)
                    if !v.isEmpty {
                        try img.attr("src", v)
                        break
                    }
                }
            }
            if (try img.attr("srcset")).isEmpty {
                let ss = try img.attr("data-srcset")
                if !ss.isEmpty { try img.attr("srcset", ss) }
            }

            let w = Int(try img.attr("width")) ?? 0
            let h = Int(try img.attr("height")) ?? 0
            if w == 1 && h == 1 { try img.remove() }
        }

        for v in try target.select("video").array() {
            if (try v.attr("poster")).isEmpty {
                let p = try v.attr("data-poster")
                if !p.isEmpty { try v.attr("poster", p) }
            }
        }
    }

    private func containsHiddenClass(_ classes: String) -> Bool {
        let lower = classes.lowercased()
        return lower.contains("hide") || lower.contains("hidden")
    }
}
