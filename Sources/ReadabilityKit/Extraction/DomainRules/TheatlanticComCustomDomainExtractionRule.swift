//
//  TheatlanticComCustomDomainExtractionRule.swift
//  ReadabilityKit
//
//  Auto-generated from Tests/ReadabilityKitTests/Custom/www.theatlantic.com/index.js
//

import Foundation
import SwiftSoup

struct TheatlanticComCustomDomainExtractionRule: DomainExtractionRule {
    let id = "custom_www_theatlantic_com"

    func matches(url: URL) -> Bool {
        CustomDomainRuleSupport.matches(url: url, domain: "www.theatlantic.com")
    }

    func preferredContentRoot(in doc: Document) throws -> Element? {
        let selectors: [String] =
        [
            "article",
            ".article-body",
        ]

        return try CustomDomainRuleSupport.firstMatchingElement(in: doc, selectors: selectors)
    }

    func candidateScoreAdjustments(in doc: Document) throws -> [DomainCandidateAdjustment] {
        let positiveSignals: [(selector: String, delta: Double)] = [
            (selector: "article", delta: 140.0),
            (selector: ".article-body", delta: 140.0),
            (selector: "h1", delta: 20.0),
            (selector: ".c-article-header__hed", delta: 20.0),
            (selector: "meta[name=\"author\"]", delta: 8.0),
            (selector: ".c-byline__author", delta: 8.0),
        ]

        let negativeSignals: [(selector: String, delta: Double)] = [
            (selector: "header", delta: -70.0),
            (selector: "nav", delta: -70.0),
            (selector: "aside", delta: -55.0),
            (selector: "footer", delta: -80.0),
            (selector: ".partner-box", delta: -120.0),
            (selector: ".callout", delta: -120.0),
            (selector: ".c-article-writer__image", delta: -120.0),
            (selector: ".c-article-writer__content", delta: -120.0),
            (selector: ".c-letters-cta__text", delta: -120.0),
            (selector: ".c-footer__logo", delta: -120.0),
            (selector: ".c-recirculation-link", delta: -120.0),
            (selector: ".twitter-tweet", delta: -120.0),
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
            "h1",
            ".c-article-header__hed",
        ]
        let authorSelectors: [String] =
        [
            "meta[name=\"author\"]",
            ".c-byline__author",
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
