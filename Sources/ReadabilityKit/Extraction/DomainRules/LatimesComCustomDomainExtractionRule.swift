//
//  LatimesComCustomDomainExtractionRule.swift
//  ReadabilityKit
//
//  Auto-generated from Tests/ReadabilityKitTests/Custom/www.latimes.com/index.js
//

import Foundation
import SwiftSoup

struct LatimesComCustomDomainExtractionRule: DomainExtractionRule {
    let id = "custom_www_latimes_com"

    func matches(url: URL) -> Bool {
        CustomDomainRuleSupport.matches(url: url, domain: "www.latimes.com")
    }

    func preferredContentRoot(in doc: Document) throws -> Element? {
        let selectors: [String] =
        [
            ".page-article-body",
            ".trb_ar_main",
        ]

        return try CustomDomainRuleSupport.firstMatchingElement(in: doc, selectors: selectors)
    }

    func candidateScoreAdjustments(in doc: Document) throws -> [DomainCandidateAdjustment] {
        let positiveSignals: [(selector: String, delta: Double)] = [
            (selector: ".page-article-body", delta: 140.0),
            (selector: ".trb_ar_main", delta: 140.0),
            (selector: "h1.headline", delta: 20.0),
            (selector: ".trb_ar_hl", delta: 20.0),
            (selector: "a[data-click=\"standardBylineAuthorName\"]", delta: 8.0),
            (selector: "meta[name=\"author\"]", delta: 8.0),
        ]

        let negativeSignals: [(selector: String, delta: Double)] = [
            (selector: "header", delta: -70.0),
            (selector: "nav", delta: -70.0),
            (selector: "aside", delta: -55.0),
            (selector: "footer", delta: -80.0),
            (selector: ".trb_ar_by", delta: -120.0),
            (selector: ".trb_ar_cr", delta: -120.0),
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
            "h1.headline",
            ".trb_ar_hl",
        ]
        let authorSelectors: [String] =
        [
            "a[data-click=\"standardBylineAuthorName\"]",
            "meta[name=\"author\"]",
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
