//
//  ApartmenttherapyComCustomDomainExtractionRule.swift
//  ReadabilityKit
//
//  Auto-generated from Tests/ReadabilityKitTests/Custom/www.apartmenttherapy.com/index.js
//

import Foundation
import SwiftSoup

struct ApartmenttherapyComCustomDomainExtractionRule: DomainExtractionRule {
    let id = "custom_www_apartmenttherapy_com"

    func matches(url: URL) -> Bool {
        CustomDomainRuleSupport.matches(url: url, domain: "www.apartmenttherapy.com")
    }

    func preferredContentRoot(in doc: Document) throws -> Element? {
        let selectors: [String] =
        [
            "div.post__content",
        ]

        return try CustomDomainRuleSupport.firstMatchingElement(in: doc, selectors: selectors)
    }

    func candidateScoreAdjustments(in doc: Document) throws -> [DomainCandidateAdjustment] {
        let positiveSignals: [(selector: String, delta: Double)] = [
            (selector: "div.post__content", delta: 140.0),
            (selector: "h1.headline", delta: 20.0),
            (selector: ".PostByline__name", delta: 8.0),
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
            "h1.headline",
        ]
        let authorSelectors: [String] =
        [
            ".PostByline__name",
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
