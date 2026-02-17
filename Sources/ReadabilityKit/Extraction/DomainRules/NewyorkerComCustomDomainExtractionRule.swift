//
//  NewyorkerComCustomDomainExtractionRule.swift
//  ReadabilityKit
//
//  Auto-generated from Tests/ReadabilityKitTests/Custom/www.newyorker.com/index.js
//

import Foundation
import SwiftSoup

struct NewyorkerComCustomDomainExtractionRule: DomainExtractionRule {
    let id = "custom_www_newyorker_com"

    func matches(url: URL) -> Bool {
        CustomDomainRuleSupport.matches(url: url, domain: "www.newyorker.com")
    }

    func preferredContentRoot(in doc: Document) throws -> Element? {
        let selectors: [String] =
        [
            ".article__body",
            "article.article.main-content",
            "main[class^=\"Layout__content\"]",
        ]

        return try CustomDomainRuleSupport.firstMatchingElement(in: doc, selectors: selectors)
    }

    func candidateScoreAdjustments(in doc: Document) throws -> [DomainCandidateAdjustment] {
        let positiveSignals: [(selector: String, delta: Double)] = [
            (selector: ".article__body", delta: 140.0),
            (selector: "article.article.main-content", delta: 140.0),
            (selector: "main[class^=\"Layout__content\"]", delta: 140.0),
            (selector: "h1[class^=\"content-header\"]", delta: 20.0),
            (selector: "h1[class^=\"ArticleHeader__hed\"]", delta: 20.0),
            (selector: "h1[class*=\"ContentHeaderHed\"]", delta: 20.0),
            (selector: "article header div[class^=\"BylinesWrapper\"]", delta: 8.0),
            (selector: "meta[name=\"article:author\"]", delta: 8.0),
        ]

        let negativeSignals: [(selector: String, delta: Double)] = [
            (selector: "header", delta: -70.0),
            (selector: "nav", delta: -70.0),
            (selector: "aside", delta: -55.0),
            (selector: "footer", delta: -80.0),
            (selector: "footer[class^=\"ArticleFooter__footer\"]", delta: -120.0),
            (selector: "aside", delta: -120.0),
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
            "h1[class^=\"content-header\"]",
            "h1[class^=\"ArticleHeader__hed\"]",
            "h1[class*=\"ContentHeaderHed\"]",
            "meta[name=\"og:title\"]",
        ]
        let authorSelectors: [String] =
        [
            "article header div[class^=\"BylinesWrapper\"]",
            "meta[name=\"article:author\"]",
            "div[class^=\"ArticleContributors\"] a[rel=\"author\"]",
            "article header div[class*=\"Byline__multipleContributors\"]",
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
