//
//  AbcnewsGoComCustomDomainExtractionRule.swift
//  ReadabilityKit
//
//  Auto-generated from Tests/ReadabilityKitTests/Custom/abcnews.go.com/index.js
//

import Foundation
import SwiftSoup

struct AbcnewsGoComCustomDomainExtractionRule: DomainExtractionRule {
    let id = "custom_abcnews_go_com"

    func matches(url: URL) -> Bool {
        CustomDomainRuleSupport.matches(url: url, domain: "abcnews.go.com")
    }

    func preferredContentRoot(in doc: Document) throws -> Element? {
        let selectors: [String] =
        [
            "article",
            ".article-copy",
        ]

        return try CustomDomainRuleSupport.firstMatchingElement(in: doc, selectors: selectors)
    }

    func candidateScoreAdjustments(in doc: Document) throws -> [DomainCandidateAdjustment] {
        let positiveSignals: [(selector: String, delta: Double)] = [
            (selector: "article", delta: 140.0),
            (selector: ".article-copy", delta: 140.0),
            (selector: "div[class*=\"Article_main__body\"] h1", delta: 20.0),
            (selector: ".article-header h1", delta: 20.0),
            (selector: ".ShareByline span:nth-child(2)", delta: 8.0),
            (selector: ".authors", delta: 8.0),
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
            "div[class*=\"Article_main__body\"] h1",
            ".article-header h1",
        ]
        let authorSelectors: [String] =
        [
            ".ShareByline span:nth-child(2)",
            ".authors",
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
