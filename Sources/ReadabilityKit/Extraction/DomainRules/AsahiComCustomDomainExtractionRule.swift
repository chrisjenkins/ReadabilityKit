//
//  AsahiComCustomDomainExtractionRule.swift
//  ReadabilityKit
//
//  Auto-generated from Tests/ReadabilityKitTests/Custom/www.asahi.com/index.js
//

import Foundation
import SwiftSoup

struct AsahiComCustomDomainExtractionRule: DomainExtractionRule {
    let id = "custom_www_asahi_com"

    func matches(url: URL) -> Bool {
        CustomDomainRuleSupport.matches(url: url, domain: "www.asahi.com")
    }

    func preferredContentRoot(in doc: Document) throws -> Element? {
        let selectors: [String] =
        [
            "main",
        ]

        return try CustomDomainRuleSupport.firstMatchingElement(in: doc, selectors: selectors)
    }

    func candidateScoreAdjustments(in doc: Document) throws -> [DomainCandidateAdjustment] {
        let positiveSignals: [(selector: String, delta: Double)] = [
            (selector: "main", delta: 140.0),
            (selector: "main h1", delta: 20.0),
            (selector: ".ArticleTitle h1", delta: 20.0),
            (selector: "meta[name=\"article:author\"]", delta: 8.0),
        ]

        let negativeSignals: [(selector: String, delta: Double)] = [
            (selector: "header", delta: -70.0),
            (selector: "nav", delta: -70.0),
            (selector: "aside", delta: -55.0),
            (selector: "footer", delta: -80.0),
            (selector: "div.AdMod", delta: -120.0),
            (selector: "div.LoginSelectArea", delta: -120.0),
            (selector: "time", delta: -120.0),
            (selector: "div.notPrint", delta: -120.0),
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
            "main h1",
            ".ArticleTitle h1",
        ]
        let authorSelectors: [String] =
        [
            "meta[name=\"article:author\"]",
        ]
        let excerptSelectors: [String] =
        [
            "meta[name=\"og:description\"]",
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
