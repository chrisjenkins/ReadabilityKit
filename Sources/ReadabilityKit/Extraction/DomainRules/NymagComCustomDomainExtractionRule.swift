//
//  NymagComCustomDomainExtractionRule.swift
//  ReadabilityKit
//
//  Auto-generated from Tests/ReadabilityKitTests/Custom/nymag.com/index.js
//

import Foundation
import SwiftSoup

struct NymagComCustomDomainExtractionRule: DomainExtractionRule {
    let id = "custom_nymag_com"

    func matches(url: URL) -> Bool {
        CustomDomainRuleSupport.matches(url: url, domain: "nymag.com")
    }

    func preferredContentRoot(in doc: Document) throws -> Element? {
        let selectors: [String] =
        [
            "div.article-content",
            "section.body",
            "article.article",
        ]

        return try CustomDomainRuleSupport.firstMatchingElement(in: doc, selectors: selectors)
    }

    func candidateScoreAdjustments(in doc: Document) throws -> [DomainCandidateAdjustment] {
        let positiveSignals: [(selector: String, delta: Double)] = [
            (selector: "div.article-content", delta: 140.0),
            (selector: "section.body", delta: 140.0),
            (selector: "article.article", delta: 140.0),
            (selector: "h1.lede-feature-title", delta: 20.0),
            (selector: "h1.headline-primary", delta: 20.0),
            (selector: "h1", delta: 20.0),
            (selector: ".by-authors", delta: 8.0),
            (selector: ".lede-feature-author", delta: 8.0),
        ]

        let negativeSignals: [(selector: String, delta: Double)] = [
            (selector: "header", delta: -70.0),
            (selector: "nav", delta: -70.0),
            (selector: "aside", delta: -55.0),
            (selector: "footer", delta: -80.0),
            (selector: ".ad", delta: -120.0),
            (selector: ".single-related-story", delta: -120.0),
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
            "h1.lede-feature-title",
            "h1.headline-primary",
            "h1",
        ]
        let authorSelectors: [String] =
        [
            ".by-authors",
            ".lede-feature-author",
        ]
        let excerptSelectors: [String] =
        [
        ]
        let leadImageSelectors: [String] =
        [
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
