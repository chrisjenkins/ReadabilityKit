//
//  NDTVComCustomDomainExtractionRule.swift
//  ReadabilityKit
//
//  Auto-generated from Tests/ReadabilityKitTests/Custom/www.ndtv.com/index.js
//

import Foundation
import SwiftSoup

struct NDTVComCustomDomainExtractionRule: DomainExtractionRule {
    let id = "custom_www_ndtv_com"

    func matches(url: URL) -> Bool {
        CustomDomainRuleSupport.matches(url: url, domain: "www.ndtv.com")
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
            (selector: "meta[name=\"og:title\"]", delta: 20.0),
            (selector: "h1.entry-title", delta: 20.0),
            (selector: "span[itemprop=\"author\"] span[itemprop=\"name\"]", delta: 8.0),
        ]

        let negativeSignals: [(selector: String, delta: Double)] = [
            (selector: "header", delta: -70.0),
            (selector: "nav", delta: -70.0),
            (selector: "aside", delta: -55.0),
            (selector: "footer", delta: -80.0),
            (selector: ".highlghts_Wdgt", delta: -120.0),
            (selector: ".ins_instory_dv_caption", delta: -120.0),
            (selector: "input", delta: -120.0),
            (selector: "._world-wrapper .mt20", delta: -120.0),
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
            "h1.entry-title",
        ]
        let authorSelectors: [String] =
        [
            "span[itemprop=\"author\"] span[itemprop=\"name\"]",
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
