//
//  TakagiHiromitsuJpCustomDomainExtractionRule.swift
//  ReadabilityKit
//
//  Auto-generated from Tests/ReadabilityKitTests/Custom/takagi-hiromitsu.jp/index.js
//

import Foundation
import SwiftSoup

struct TakagiHiromitsuJpCustomDomainExtractionRule: DomainExtractionRule {
    let id = "custom_takagi_hiromitsu_jp"

    func matches(url: URL) -> Bool {
        CustomDomainRuleSupport.matches(url: url, domain: "takagi-hiromitsu.jp")
    }

    func preferredContentRoot(in doc: Document) throws -> Element? {
        let selectors: [String] =
        [
            "div.body",
        ]

        return try CustomDomainRuleSupport.firstMatchingElement(in: doc, selectors: selectors)
    }

    func candidateScoreAdjustments(in doc: Document) throws -> [DomainCandidateAdjustment] {
        let positiveSignals: [(selector: String, delta: Double)] = [
            (selector: "div.body", delta: 140.0),
            (selector: "h3", delta: 20.0),
            (selector: "meta[name=\"author\"]", delta: 8.0),
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
            "h3",
        ]
        let authorSelectors: [String] =
        [
            "meta[name=\"author\"]",
        ]
        let excerptSelectors: [String] =
        [
        ]
        let leadImageSelectors: [String] =
        [
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
