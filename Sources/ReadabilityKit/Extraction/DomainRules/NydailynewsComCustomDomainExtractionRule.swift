//
//  NydailynewsComCustomDomainExtractionRule.swift
//  ReadabilityKit
//
//  Auto-generated from Tests/ReadabilityKitTests/Custom/www.nydailynews.com/index.js
//

import Foundation
import SwiftSoup

struct NydailynewsComCustomDomainExtractionRule: DomainExtractionRule {
    let id = "custom_www_nydailynews_com"

    func matches(url: URL) -> Bool {
        CustomDomainRuleSupport.matches(url: url, domain: "www.nydailynews.com")
    }

    func preferredContentRoot(in doc: Document) throws -> Element? {
        let selectors: [String] =
        [
            "article",
            "article#ra-body",
        ]

        return try CustomDomainRuleSupport.firstMatchingElement(in: doc, selectors: selectors)
    }

    func candidateScoreAdjustments(in doc: Document) throws -> [DomainCandidateAdjustment] {
        let positiveSignals: [(selector: String, delta: Double)] = [
            (selector: "article", delta: 140.0),
            (selector: "article#ra-body", delta: 140.0),
            (selector: "h1.headline", delta: 20.0),
            (selector: "h1#ra-headline", delta: 20.0),
            (selector: ".article_byline span", delta: 8.0),
            (selector: "meta[name=\"parsely-author\"]", delta: 8.0),
        ]

        let negativeSignals: [(selector: String, delta: Double)] = [
            (selector: "header", delta: -70.0),
            (selector: "nav", delta: -70.0),
            (selector: "aside", delta: -55.0),
            (selector: "footer", delta: -80.0),
            (selector: "dl#ra-tags", delta: -120.0),
            (selector: ".ra-related", delta: -120.0),
            (selector: "a.ra-editor", delta: -120.0),
            (selector: "dl#ra-share-bottom", delta: -120.0),
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
            "h1#ra-headline",
        ]
        let authorSelectors: [String] =
        [
            ".article_byline span",
            "meta[name=\"parsely-author\"]",
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
