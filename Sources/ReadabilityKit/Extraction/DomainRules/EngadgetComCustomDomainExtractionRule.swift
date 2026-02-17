//
//  EngadgetComCustomDomainExtractionRule.swift
//  ReadabilityKit
//
//  Auto-generated from Tests/ReadabilityKitTests/Custom/www.engadget.com/index.js
//

import Foundation
import SwiftSoup

struct EngadgetComCustomDomainExtractionRule: DomainExtractionRule {
    let id = "custom_www_engadget_com"

    func matches(url: URL) -> Bool {
        CustomDomainRuleSupport.matches(url: url, domain: "www.engadget.com")
    }

    func preferredContentRoot(in doc: Document) throws -> Element? {
        let selectors: [String] =
        [
            "#page_body figure:not(div.article-text figure)",
            "div.article-text",
        ]

        return try CustomDomainRuleSupport.firstMatchingElement(in: doc, selectors: selectors)
    }

    func candidateScoreAdjustments(in doc: Document) throws -> [DomainCandidateAdjustment] {
        let positiveSignals: [(selector: String, delta: Double)] = [
            (selector: "#page_body figure:not(div.article-text figure)", delta: 140.0),
            (selector: "div.article-text", delta: 140.0),
            (selector: "meta[name=\"og:title\"]", delta: 20.0),
            (selector: "a.th-meta[data-ylk*=\"subsec:author\"]", delta: 8.0),
        ]

        let negativeSignals: [(selector: String, delta: Double)] = [
            (selector: "header", delta: -70.0),
            (selector: "nav", delta: -70.0),
            (selector: "aside", delta: -55.0),
            (selector: "footer", delta: -80.0),
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
            "a.th-meta[data-ylk*=\"subsec:author\"]",
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
