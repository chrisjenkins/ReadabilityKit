//
//  EonlineComCustomDomainExtractionRule.swift
//  ReadabilityKit
//
//  Auto-generated from Tests/ReadabilityKitTests/Custom/www.eonline.com/index.js
//

import Foundation
import SwiftSoup

struct EonlineComCustomDomainExtractionRule: DomainExtractionRule {
    let id = "custom_www_eonline_com"

    func matches(url: URL) -> Bool {
        CustomDomainRuleSupport.matches(url: url, domain: "www.eonline.com")
    }

    func preferredContentRoot(in doc: Document) throws -> Element? {
        let selectors: [String] =
        [
            ".article-detail__main-content section",
            ".post-content section, .post-content div.post-content__image",
        ]

        return try CustomDomainRuleSupport.firstMatchingElement(in: doc, selectors: selectors)
    }

    func candidateScoreAdjustments(in doc: Document) throws -> [DomainCandidateAdjustment] {
        let positiveSignals: [(selector: String, delta: Double)] = [
            (selector: ".article-detail__main-content section", delta: 140.0),
            (selector: ".post-content section, .post-content div.post-content__image", delta: 140.0),
            (selector: "h1.article-detail__title", delta: 20.0),
            (selector: "h1.article__title", delta: 20.0),
            (selector: ".article-detail__meta__author", delta: 8.0),
            (selector: ".entry-meta__author a", delta: 8.0),
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
            "h1.article-detail__title",
            "h1.article__title",
        ]
        let authorSelectors: [String] =
        [
            ".article-detail__meta__author",
            ".entry-meta__author a",
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
