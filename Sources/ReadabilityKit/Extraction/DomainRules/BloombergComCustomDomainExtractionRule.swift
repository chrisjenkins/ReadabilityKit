//
//  BloombergComCustomDomainExtractionRule.swift
//  ReadabilityKit
//
//  Auto-generated from Tests/ReadabilityKitTests/Custom/www.bloomberg.com/index.js
//

import Foundation
import SwiftSoup

struct BloombergComCustomDomainExtractionRule: DomainExtractionRule {
    let id = "custom_www_bloomberg_com"

    func matches(url: URL) -> Bool {
        CustomDomainRuleSupport.matches(url: url, domain: "www.bloomberg.com")
    }

    func preferredContentRoot(in doc: Document) throws -> Element? {
        let selectors: [String] =
        [
            ".article-body__content",
            ".body-content",
            "section.copy-block",
            ".body-copy",
        ]

        return try CustomDomainRuleSupport.firstMatchingElement(in: doc, selectors: selectors)
    }

    func candidateScoreAdjustments(in doc: Document) throws -> [DomainCandidateAdjustment] {
        let positiveSignals: [(selector: String, delta: Double)] = [
            (selector: ".article-body__content", delta: 140.0),
            (selector: ".body-content", delta: 140.0),
            (selector: "section.copy-block", delta: 140.0),
            (selector: ".body-copy", delta: 140.0),
            (selector: ".lede-headline", delta: 20.0),
            (selector: "h1.article-title", delta: 20.0),
            (selector: "h1[class^=\"headline\"]", delta: 20.0),
            (selector: "meta[name=\"parsely-author\"]", delta: 8.0),
            (selector: ".byline-details__link", delta: 8.0),
        ]

        let negativeSignals: [(selector: String, delta: Double)] = [
            (selector: "header", delta: -70.0),
            (selector: "nav", delta: -70.0),
            (selector: "aside", delta: -55.0),
            (selector: "footer", delta: -80.0),
            (selector: ".inline-newsletter", delta: -120.0),
            (selector: ".page-ad", delta: -120.0),
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
            ".lede-headline",
            "h1.article-title",
            "h1[class^=\"headline\"]",
            "h1.lede-text-only__hed",
        ]
        let authorSelectors: [String] =
        [
            "meta[name=\"parsely-author\"]",
            ".byline-details__link",
            ".bydek",
            ".author",
            "p[class*=\"author\"]",
        ]
        let excerptSelectors: [String] =
        [
        ]
        let leadImageSelectors: [String] =
        [
            "meta[name=\"og:image\"]",
            "content",
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
