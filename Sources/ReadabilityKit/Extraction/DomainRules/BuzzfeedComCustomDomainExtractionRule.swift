//
//  BuzzfeedComCustomDomainExtractionRule.swift
//  ReadabilityKit
//
//  Auto-generated from Tests/ReadabilityKitTests/Custom/www.buzzfeed.com/index.js
//

import Foundation
import SwiftSoup

struct BuzzfeedComCustomDomainExtractionRule: DomainExtractionRule {
    let id = "custom_www_buzzfeed_com"

    func matches(url: URL) -> Bool {
        CustomDomainRuleSupport.matches(url: url, domain: "www.buzzfeed.com")
    }

    func preferredContentRoot(in doc: Document) throws -> Element? {
        let selectors: [String] =
        [
            "div[class^=\"featureimage_featureImageWrapper\"]",
            ".js-subbuzz-wrapper",
        ]

        return try CustomDomainRuleSupport.firstMatchingElement(in: doc, selectors: selectors)
    }

    func candidateScoreAdjustments(in doc: Document) throws -> [DomainCandidateAdjustment] {
        let positiveSignals: [(selector: String, delta: Double)] = [
            (selector: "div[class^=\"featureimage_featureImageWrapper\"]", delta: 140.0),
            (selector: ".js-subbuzz-wrapper", delta: 140.0),
            (selector: "h1.embed-headline-title", delta: 20.0),
            (selector: "a[data-action=\"user/username\"]", delta: 8.0),
            (selector: "byline__author", delta: 8.0),
        ]

        let negativeSignals: [(selector: String, delta: Double)] = [
            (selector: "header", delta: -70.0),
            (selector: "nav", delta: -70.0),
            (selector: "aside", delta: -55.0),
            (selector: "footer", delta: -80.0),
            (selector: ".instapaper_ignore", delta: -120.0),
            (selector: ".suplist_list_hide .buzz_superlist_item .buzz_superlist_number_inline", delta: -120.0),
            (selector: ".share-box", delta: -120.0),
            (selector: ".print", delta: -120.0),
            (selector: ".js-inline-share-bar", delta: -120.0),
            (selector: ".js-ad-placement", delta: -120.0),
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
            "h1.embed-headline-title",
        ]
        let authorSelectors: [String] =
        [
            "a[data-action=\"user/username\"]",
            "byline__author",
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
