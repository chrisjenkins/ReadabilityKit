//
//  ForwardComCustomDomainExtractionRule.swift
//  ReadabilityKit
//
//  Auto-generated from Tests/ReadabilityKitTests/Custom/forward.com/index.js
//

import Foundation
import SwiftSoup

struct ForwardComCustomDomainExtractionRule: DomainExtractionRule {
    let id = "custom_forward_com"

    func matches(url: URL) -> Bool {
        CustomDomainRuleSupport.matches(url: url, domain: "forward.com")
    }

    func preferredContentRoot(in doc: Document) throws -> Element? {
        let selectors: [String] =
        [
            ".content-container article",
            ".post-item-media-wrap",
            ".post-item p",
        ]

        return try CustomDomainRuleSupport.firstMatchingElement(in: doc, selectors: selectors)
    }

    func candidateScoreAdjustments(in doc: Document) throws -> [DomainCandidateAdjustment] {
        let positiveSignals: [(selector: String, delta: Double)] = [
            (selector: ".content-container article", delta: 140.0),
            (selector: ".post-item-media-wrap", delta: 140.0),
            (selector: ".post-item p", delta: 140.0),
            (selector: "meta[name=\"og:title\"]", delta: 20.0),
            (selector: ".post-author a", delta: 8.0),
            (selector: ".author-name", delta: 8.0),
        ]

        let negativeSignals: [(selector: String, delta: Double)] = [
            (selector: "header", delta: -70.0),
            (selector: "nav", delta: -70.0),
            (selector: "aside", delta: -55.0),
            (selector: "footer", delta: -80.0),
            (selector: ".post-author", delta: -120.0),
            (selector: ".donate-box", delta: -120.0),
            (selector: ".message", delta: -120.0),
            (selector: ".subtitle", delta: -120.0),
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
            "meta[name=\"og:title\"]",
        ]
        let authorSelectors: [String] =
        [
            ".post-author a",
            ".author-name",
            "meta[name=\"sailthru.author\"]",
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
