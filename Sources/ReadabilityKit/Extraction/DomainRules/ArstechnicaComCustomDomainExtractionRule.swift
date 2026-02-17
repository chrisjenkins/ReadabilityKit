//
//  ArstechnicaComCustomDomainExtractionRule.swift
//  ReadabilityKit
//
//  Auto-generated from Tests/ReadabilityKitTests/Custom/arstechnica.com/index.js
//

import Foundation
import SwiftSoup

struct ArstechnicaComCustomDomainExtractionRule: DomainExtractionRule {
    let id = "custom_arstechnica_com"

    func matches(url: URL) -> Bool {
        CustomDomainRuleSupport.matches(url: url, domain: "arstechnica.com")
    }

    func preferredContentRoot(in doc: Document) throws -> Element? {
        let selectors: [String] =
        [
            "div[itemprop=\"articleBody\"]",
        ]

        return try CustomDomainRuleSupport.firstMatchingElement(in: doc, selectors: selectors)
    }

    func candidateScoreAdjustments(in doc: Document) throws -> [DomainCandidateAdjustment] {
        let positiveSignals: [(selector: String, delta: Double)] = [
            (selector: "div[itemprop=\"articleBody\"]", delta: 140.0),
            (selector: "title", delta: 20.0),
            (selector: "*[rel=\"author\"] *[itemprop=\"name\"]", delta: 8.0),
        ]

        let negativeSignals: [(selector: String, delta: Double)] = [
            (selector: "header", delta: -70.0),
            (selector: "nav", delta: -70.0),
            (selector: "aside", delta: -55.0),
            (selector: "footer", delta: -80.0),
            (selector: "figcaption .enlarge-link", delta: -120.0),
            (selector: "figcaption .sep", delta: -120.0),
            (selector: "figure.video", delta: -120.0),
            (selector: ".gallery", delta: -120.0),
            (selector: "aside", delta: -120.0),
            (selector: ".sidebar", delta: -120.0),
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
            "title",
        ]
        let authorSelectors: [String] =
        [
            "*[rel=\"author\"] *[itemprop=\"name\"]",
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
