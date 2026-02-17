//
//  SiComCustomDomainExtractionRule.swift
//  ReadabilityKit
//
//  Auto-generated from Tests/ReadabilityKitTests/Custom/www.si.com/index.js
//

import Foundation
import SwiftSoup

struct SiComCustomDomainExtractionRule: DomainExtractionRule {
    let id = "custom_www_si_com"

    func matches(url: URL) -> Bool {
        CustomDomainRuleSupport.matches(url: url, domain: "www.si.com")
    }

    func preferredContentRoot(in doc: Document) throws -> Element? {
        let selectors: [String] =
        [
            ".m-detail--body",
            "p",
            ".marquee_large_2x",
            ".component.image",
        ]

        return try CustomDomainRuleSupport.firstMatchingElement(in: doc, selectors: selectors)
    }

    func candidateScoreAdjustments(in doc: Document) throws -> [DomainCandidateAdjustment] {
        let positiveSignals: [(selector: String, delta: Double)] = [
            (selector: ".m-detail--body", delta: 140.0),
            (selector: "p", delta: 140.0),
            (selector: ".marquee_large_2x", delta: 140.0),
            (selector: ".component.image", delta: 140.0),
            (selector: "h1", delta: 20.0),
            (selector: "h1.headline", delta: 20.0),
            (selector: "meta[name=\"author\"]", delta: 8.0),
        ]

        let negativeSignals: [(selector: String, delta: Double)] = [
            (selector: "header", delta: -70.0),
            (selector: "nav", delta: -70.0),
            (selector: "aside", delta: -55.0),
            (selector: "footer", delta: -80.0),
            (selector: ".inline-thumb", delta: -120.0),
            (selector: ".primary-message", delta: -120.0),
            (selector: ".description", delta: -120.0),
            (selector: ".instructions", delta: -120.0),
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
            "h1.headline",
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
