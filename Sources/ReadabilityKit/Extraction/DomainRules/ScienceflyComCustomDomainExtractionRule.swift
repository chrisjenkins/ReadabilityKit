//
//  ScienceflyComCustomDomainExtractionRule.swift
//  ReadabilityKit
//
//  Auto-generated from Tests/ReadabilityKitTests/Custom/sciencefly.com/index.js
//

import Foundation
import SwiftSoup

struct ScienceflyComCustomDomainExtractionRule: DomainExtractionRule {
    let id = "custom_sciencefly_com"

    func matches(url: URL) -> Bool {
        CustomDomainRuleSupport.matches(url: url, domain: "sciencefly.com")
    }

    func preferredContentRoot(in doc: Document) throws -> Element? {
        let selectors: [String] =
        [
            "div.theiaPostSlider_slides",
        ]

        return try CustomDomainRuleSupport.firstMatchingElement(in: doc, selectors: selectors)
    }

    func candidateScoreAdjustments(in doc: Document) throws -> [DomainCandidateAdjustment] {
        let positiveSignals: [(selector: String, delta: Double)] = [
            (selector: "div.theiaPostSlider_slides", delta: 140.0),
            (selector: ".entry-title", delta: 20.0),
            (selector: ".cb-entry-title", delta: 20.0),
            (selector: ".cb-single-title", delta: 20.0),
            (selector: "div.cb-author", delta: 8.0),
            (selector: "div.cb-author-title", delta: 8.0),
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
            ".entry-title",
            ".cb-entry-title",
            ".cb-single-title",
        ]
        let authorSelectors: [String] =
        [
            "div.cb-author",
            "div.cb-author-title",
        ]
        let excerptSelectors: [String] =
        [
        ]
        let leadImageSelectors: [String] =
        [
            "div.theiaPostSlider_slides img",
            "src",
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
