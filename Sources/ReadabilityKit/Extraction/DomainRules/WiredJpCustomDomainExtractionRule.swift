//
//  WiredJpCustomDomainExtractionRule.swift
//  ReadabilityKit
//
//  Auto-generated from Tests/ReadabilityKitTests/Custom/wired.jp/index.js
//

import Foundation
import SwiftSoup

struct WiredJpCustomDomainExtractionRule: DomainExtractionRule {
    let id = "custom_wired_jp"

    func matches(url: URL) -> Bool {
        CustomDomainRuleSupport.matches(url: url, domain: "wired.jp")
    }

    func preferredContentRoot(in doc: Document) throws -> Element? {
        let selectors: [String] =
        [
            "div[data-attribute-verso-pattern=\"article-body\"]",
            "article.article-detail",
        ]

        return try CustomDomainRuleSupport.firstMatchingElement(in: doc, selectors: selectors)
    }

    func candidateScoreAdjustments(in doc: Document) throws -> [DomainCandidateAdjustment] {
        let positiveSignals: [(selector: String, delta: Double)] = [
            (selector: "div[data-attribute-verso-pattern=\"article-body\"]", delta: 140.0),
            (selector: "article.article-detail", delta: 140.0),
            (selector: "h1[data-testid=\"ContentHeaderHed\"]", delta: 20.0),
            (selector: "h1.post-title", delta: 20.0),
            (selector: "meta[name=\"article:author\"]", delta: 8.0),
            (selector: "p[itemprop=\"author\"]", delta: 8.0),
        ]

        let negativeSignals: [(selector: String, delta: Double)] = [
            (selector: "header", delta: -70.0),
            (selector: "nav", delta: -70.0),
            (selector: "aside", delta: -55.0),
            (selector: "footer", delta: -80.0),
            (selector: ".post-category", delta: -120.0),
            (selector: "time", delta: -120.0),
            (selector: "h1.post-title", delta: -120.0),
            (selector: ".social-area-syncer", delta: -120.0),
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
            "h1[data-testid=\"ContentHeaderHed\"]",
            "h1.post-title",
        ]
        let authorSelectors: [String] =
        [
            "meta[name=\"article:author\"]",
            "p[itemprop=\"author\"]",
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
