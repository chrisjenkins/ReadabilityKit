//
//  ThefederalistpapersOrgCustomDomainExtractionRule.swift
//  ReadabilityKit
//
//  Auto-generated from Tests/ReadabilityKitTests/Custom/thefederalistpapers.org/index.js
//

import Foundation
import SwiftSoup

struct ThefederalistpapersOrgCustomDomainExtractionRule: DomainExtractionRule {
    let id = "custom_thefederalistpapers_org"

    func matches(url: URL) -> Bool {
        CustomDomainRuleSupport.matches(url: url, domain: "thefederalistpapers.org")
    }

    func preferredContentRoot(in doc: Document) throws -> Element? {
        let selectors: [String] =
        [
            ".content",
        ]

        return try CustomDomainRuleSupport.firstMatchingElement(in: doc, selectors: selectors)
    }

    func candidateScoreAdjustments(in doc: Document) throws -> [DomainCandidateAdjustment] {
        let positiveSignals: [(selector: String, delta: Double)] = [
            (selector: ".content", delta: 140.0),
            (selector: "h1.entry-title", delta: 20.0),
            (selector: ".author-meta-title", delta: 8.0),
            (selector: "main span.entry-author-name", delta: 8.0),
        ]

        let negativeSignals: [(selector: String, delta: Double)] = [
            (selector: "header", delta: -70.0),
            (selector: "nav", delta: -70.0),
            (selector: "aside", delta: -55.0),
            (selector: "footer", delta: -80.0),
            (selector: "header", delta: -120.0),
            (selector: ".article-sharing", delta: -120.0),
            (selector: ".after-article", delta: -120.0),
            (selector: ".type-commenting", delta: -120.0),
            (selector: ".more-posts", delta: -120.0),
            (selector: "p[style]", delta: -120.0),
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
            "h1.entry-title",
        ]
        let authorSelectors: [String] =
        [
            ".author-meta-title",
            "main span.entry-author-name",
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
