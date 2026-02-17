//
//  RollingstoneComCustomDomainExtractionRule.swift
//  ReadabilityKit
//
//  Auto-generated from Tests/ReadabilityKitTests/Custom/www.rollingstone.com/index.js
//

import Foundation
import SwiftSoup

struct RollingstoneComCustomDomainExtractionRule: DomainExtractionRule {
    let id = "custom_www_rollingstone_com"

    func matches(url: URL) -> Bool {
        CustomDomainRuleSupport.matches(url: url, domain: "www.rollingstone.com")
    }

    func preferredContentRoot(in doc: Document) throws -> Element? {
        let selectors: [String] =
        [
            ".l-article-content",
            ".lead-container",
            ".article-content",
        ]

        return try CustomDomainRuleSupport.firstMatchingElement(in: doc, selectors: selectors)
    }

    func candidateScoreAdjustments(in doc: Document) throws -> [DomainCandidateAdjustment] {
        let positiveSignals: [(selector: String, delta: Double)] = [
            (selector: ".l-article-content", delta: 140.0),
            (selector: ".lead-container", delta: 140.0),
            (selector: ".article-content", delta: 140.0),
            (selector: "h1.l-article-header__row--title", delta: 20.0),
            (selector: "h1.content-title", delta: 20.0),
            (selector: "a.c-byline__link", delta: 8.0),
            (selector: "a.content-author.tracked-offpage", delta: 8.0),
        ]

        let negativeSignals: [(selector: String, delta: Double)] = [
            (selector: "header", delta: -70.0),
            (selector: "nav", delta: -70.0),
            (selector: "aside", delta: -55.0),
            (selector: "footer", delta: -80.0),
            (selector: ".c-related-links-wrapper", delta: -120.0),
            (selector: ".module-related", delta: -120.0),
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
            "h1.l-article-header__row--title",
            "h1.content-title",
        ]
        let authorSelectors: [String] =
        [
            "a.c-byline__link",
            "a.content-author.tracked-offpage",
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
