//
//  NytimesComCustomDomainExtractionRule.swift
//  ReadabilityKit
//
//  Auto-generated from Tests/ReadabilityKitTests/Custom/www.nytimes.com/index.js
//

import Foundation
import SwiftSoup

struct NytimesComCustomDomainExtractionRule: DomainExtractionRule {
    let id = "custom_www_nytimes_com"

    func matches(url: URL) -> Bool {
        CustomDomainRuleSupport.matches(url: url, domain: "www.nytimes.com")
    }

    func preferredContentRoot(in doc: Document) throws -> Element? {
        let selectors: [String] =
        [
            "div.g-blocks",
            "section[name=\"articleBody\"]",
            "article#story",
        ]

        return try CustomDomainRuleSupport.firstMatchingElement(in: doc, selectors: selectors)
    }

    func candidateScoreAdjustments(in doc: Document) throws -> [DomainCandidateAdjustment] {
        let positiveSignals: [(selector: String, delta: Double)] = [
            (selector: "div.g-blocks", delta: 140.0),
            (selector: "section[name=\"articleBody\"]", delta: 140.0),
            (selector: "article#story", delta: 140.0),
            (selector: "h1[data-testid=\"headline\"]", delta: 20.0),
            (selector: "h1.g-headline", delta: 20.0),
            (selector: "h1[itemprop=\"headline\"]", delta: 20.0),
            (selector: "meta[name=\"author\"]", delta: 8.0),
            (selector: ".g-byline", delta: 8.0),
        ]

        let negativeSignals: [(selector: String, delta: Double)] = [
            (selector: "header", delta: -70.0),
            (selector: "nav", delta: -70.0),
            (selector: "aside", delta: -55.0),
            (selector: "footer", delta: -80.0),
            (selector: ".ad", delta: -120.0),
            (selector: "header#story-header", delta: -120.0),
            (selector: ".story-body-1 .lede.video", delta: -120.0),
            (selector: ".visually-hidden", delta: -120.0),
            (selector: "#newsletter-promo", delta: -120.0),
            (selector: ".promo", delta: -120.0),
            (selector: ".comments-button", delta: -120.0),
            (selector: ".hidden", delta: -120.0),
            (selector: ".comments", delta: -120.0),
            (selector: ".supplemental", delta: -120.0),
            (selector: ".nocontent", delta: -120.0),
            (selector: ".story-footer-links", delta: -120.0),
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
            "h1[data-testid=\"headline\"]",
            "h1.g-headline",
            "h1[itemprop=\"headline\"]",
            "h1.headline",
            "h1 .balancedHeadline",
        ]
        let authorSelectors: [String] =
        [
            "meta[name=\"author\"]",
            ".g-byline",
            ".byline",
            "meta[name=\"byl\"]",
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
