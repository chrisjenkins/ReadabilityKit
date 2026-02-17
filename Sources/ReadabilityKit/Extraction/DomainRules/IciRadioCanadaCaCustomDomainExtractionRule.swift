//
//  IciRadioCanadaCaCustomDomainExtractionRule.swift
//  ReadabilityKit
//
//  Auto-generated from Tests/ReadabilityKitTests/Custom/ici.radio-canada.ca/index.js
//

import Foundation
import SwiftSoup

struct IciRadioCanadaCaCustomDomainExtractionRule: DomainExtractionRule {
    let id = "custom_ici_radio_canada_ca"

    func matches(url: URL) -> Bool {
        CustomDomainRuleSupport.matches(url: url, domain: "ici.radio-canada.ca")
    }

    func preferredContentRoot(in doc: Document) throws -> Element? {
        let selectors: [String] =
        [
            "section.document-content-style",
            ".main-multimedia-item",
            ".news-story-content",
        ]

        return try CustomDomainRuleSupport.firstMatchingElement(in: doc, selectors: selectors)
    }

    func candidateScoreAdjustments(in doc: Document) throws -> [DomainCandidateAdjustment] {
        let positiveSignals: [(selector: String, delta: Double)] = [
            (selector: "section.document-content-style", delta: 140.0),
            (selector: ".main-multimedia-item", delta: 140.0),
            (selector: ".news-story-content", delta: 140.0),
            (selector: "h1", delta: 20.0),
            (selector: "meta[name=\"dc.creator\"]", delta: 8.0),
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
            "h1",
        ]
        let authorSelectors: [String] =
        [
            "meta[name=\"dc.creator\"]",
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
