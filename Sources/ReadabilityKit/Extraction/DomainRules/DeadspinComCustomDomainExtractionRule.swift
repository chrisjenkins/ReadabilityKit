//
//  DeadspinComCustomDomainExtractionRule.swift
//  ReadabilityKit
//
//  Auto-generated from Tests/ReadabilityKitTests/Custom/deadspin.com/index.js
//

import Foundation
import SwiftSoup

struct DeadspinComCustomDomainExtractionRule: DomainExtractionRule {
    let id = "custom_deadspin_com"

    func matches(url: URL) -> Bool {
        CustomDomainRuleSupport.matches(url: url, domain: "deadspin.com")
    }

    func preferredContentRoot(in doc: Document) throws -> Element? {
        let selectors: [String] =
        [
            ".js_post-content",
            ".post-content",
            ".entry-content",
        ]

        return try CustomDomainRuleSupport.firstMatchingElement(in: doc, selectors: selectors)
    }

    func candidateScoreAdjustments(in doc: Document) throws -> [DomainCandidateAdjustment] {
        let positiveSignals: [(selector: String, delta: Double)] = [
            (selector: ".js_post-content", delta: 140.0),
            (selector: ".post-content", delta: 140.0),
            (selector: ".entry-content", delta: 140.0),
            (selector: "header h1", delta: 20.0),
            (selector: "h1.headline", delta: 20.0),
            (selector: "a[data-ga*=\"Author\"]", delta: 8.0),
            (selector: ".author", delta: 8.0),
        ]

        let negativeSignals: [(selector: String, delta: Double)] = [
            (selector: "header", delta: -70.0),
            (selector: "nav", delta: -70.0),
            (selector: "aside", delta: -55.0),
            (selector: "footer", delta: -80.0),
            (selector: ".magnifier", delta: -120.0),
            (selector: ".lightbox", delta: -120.0),
        ]

        return try CustomDomainRuleSupport.candidateScoreAdjustments(
            in: doc,
            positiveSignals: positiveSignals,
            negativeSignals: negativeSignals,
        )
    }

    func metadataOverrides(in doc: Document, fallbackURL: URL) throws -> DomainMetadataOverride {
        let titleSelectors: [String] =
        [
            "header h1",
            "h1.headline",
        ]
        let authorSelectors: [String] =
        [
            "a[data-ga*=\"Author\"]",
            ".author",
        ]
        let excerptSelectors: [String] =
        [
        ]
        let leadImageSelectors: [String] =
        [
            "meta[name=\"og:image\"]",
        ]

        return try CustomDomainRuleSupport.metadataOverrides(
            in: doc,
            fallbackURL: fallbackURL,
            titleSelectors: titleSelectors,
            authorSelectors: authorSelectors,
            excerptSelectors: excerptSelectors,
            leadImageSelectors: leadImageSelectors,
        )
    }
}
