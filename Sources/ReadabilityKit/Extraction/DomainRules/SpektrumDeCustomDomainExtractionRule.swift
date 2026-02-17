//
//  SpektrumDeCustomDomainExtractionRule.swift
//  ReadabilityKit
//
//  Auto-generated from Tests/ReadabilityKitTests/Custom/www.spektrum.de/index.js
//

import Foundation
import SwiftSoup

struct SpektrumDeCustomDomainExtractionRule: DomainExtractionRule {
    let id = "custom_www_spektrum_de"

    func matches(url: URL) -> Bool {
        CustomDomainRuleSupport.matches(url: url, domain: "www.spektrum.de")
    }

    func preferredContentRoot(in doc: Document) throws -> Element? {
        let selectors: [String] =
        [
            "article.content",
        ]

        return try CustomDomainRuleSupport.firstMatchingElement(in: doc, selectors: selectors)
    }

    func candidateScoreAdjustments(in doc: Document) throws -> [DomainCandidateAdjustment] {
        let positiveSignals: [(selector: String, delta: Double)] = [
            (selector: "article.content", delta: 140.0),
            (selector: ".content__title", delta: 20.0),
            (selector: ".content__author__info__name", delta: 8.0),
        ]

        let negativeSignals: [(selector: String, delta: Double)] = [
            (selector: "header", delta: -70.0),
            (selector: "nav", delta: -70.0),
            (selector: "aside", delta: -55.0),
            (selector: "footer", delta: -80.0),
            (selector: ".breadcrumbs", delta: -120.0),
            (selector: ".hide-for-print", delta: -120.0),
            (selector: "aside", delta: -120.0),
            (selector: "header h2", delta: -120.0),
            (selector: ".image__article__top", delta: -120.0),
            (selector: ".content__author", delta: -120.0),
            (selector: ".copyright", delta: -120.0),
            (selector: ".callout-box", delta: -120.0),
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
            ".content__title",
        ]
        let authorSelectors: [String] =
        [
            ".content__author__info__name",
        ]
        let excerptSelectors: [String] =
        [
        ]
        let leadImageSelectors: [String] =
        [
            "meta[name=\"og:image\"]",
            "meta[property=\"og:image\"]",
            "content",
            ".image__article__top img",
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
