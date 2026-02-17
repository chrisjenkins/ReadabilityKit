//
//  MentalflossComCustomDomainExtractionRule.swift
//  ReadabilityKit
//
//  Auto-generated from Tests/ReadabilityKitTests/Custom/www.mentalfloss.com/index.js
//

import Foundation
import SwiftSoup

struct MentalflossComCustomDomainExtractionRule: DomainExtractionRule {
    let id = "custom_www_mentalfloss_com"

    func matches(url: URL) -> Bool {
        CustomDomainRuleSupport.matches(url: url, domain: "www.mentalfloss.com")
    }

    func preferredContentRoot(in doc: Document) throws -> Element? {
        let selectors: [String] =
        [
            "article main",
            "div.field.field-name-body",
        ]

        return try CustomDomainRuleSupport.firstMatchingElement(in: doc, selectors: selectors)
    }

    func candidateScoreAdjustments(in doc: Document) throws -> [DomainCandidateAdjustment] {
        let positiveSignals: [(selector: String, delta: Double)] = [
            (selector: "article main", delta: 140.0),
            (selector: "div.field.field-name-body", delta: 140.0),
            (selector: "meta[name=\"og:title\"]", delta: 20.0),
            (selector: "h1.title", delta: 20.0),
            (selector: ".title-group", delta: 20.0),
            (selector: "a[data-vars-label*=\"authors\"]", delta: 8.0),
            (selector: ".field-name-field-enhanced-authors", delta: 8.0),
        ]

        let negativeSignals: [(selector: String, delta: Double)] = [
            (selector: "header", delta: -70.0),
            (selector: "nav", delta: -70.0),
            (selector: "aside", delta: -55.0),
            (selector: "footer", delta: -80.0),
            (selector: "small", delta: -120.0),
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
            "meta[name=\"og:title\"]",
            "h1.title",
            ".title-group",
            ".inner",
        ]
        let authorSelectors: [String] =
        [
            "a[data-vars-label*=\"authors\"]",
            ".field-name-field-enhanced-authors",
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
