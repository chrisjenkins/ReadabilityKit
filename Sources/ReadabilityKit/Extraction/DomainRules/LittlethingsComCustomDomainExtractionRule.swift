//
//  LittlethingsComCustomDomainExtractionRule.swift
//  ReadabilityKit
//
//  Auto-generated from Tests/ReadabilityKitTests/Custom/www.littlethings.com/index.js
//

import Foundation
import SwiftSoup

struct LittlethingsComCustomDomainExtractionRule: DomainExtractionRule {
    let id = "custom_www_littlethings_com"

    func matches(url: URL) -> Bool {
        CustomDomainRuleSupport.matches(url: url, domain: "www.littlethings.com")
    }

    func preferredContentRoot(in doc: Document) throws -> Element? {
        let selectors: [String] =
        [
            "section[class*=\"PostMainArticle\"]",
            ".mainContentIntro",
            ".content-wrapper",
        ]

        return try CustomDomainRuleSupport.firstMatchingElement(in: doc, selectors: selectors)
    }

    func candidateScoreAdjustments(in doc: Document) throws -> [DomainCandidateAdjustment] {
        let positiveSignals: [(selector: String, delta: Double)] = [
            (selector: "section[class*=\"PostMainArticle\"]", delta: 140.0),
            (selector: ".mainContentIntro", delta: 140.0),
            (selector: ".content-wrapper", delta: 140.0),
            (selector: "h1[class*=\"PostHeader\"]", delta: 20.0),
            (selector: "h1.post-title", delta: 20.0),
            (selector: "div[class^=\"PostHeader__ScAuthorNameSection\"]", delta: 8.0),
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
            "h1[class*=\"PostHeader\"]",
            "h1.post-title",
        ]
        let authorSelectors: [String] =
        [
            "div[class^=\"PostHeader__ScAuthorNameSection\"]",
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
