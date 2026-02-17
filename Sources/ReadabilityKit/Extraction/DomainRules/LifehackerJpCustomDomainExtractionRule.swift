//
//  LifehackerJpCustomDomainExtractionRule.swift
//  ReadabilityKit
//
//  Auto-generated from Tests/ReadabilityKitTests/Custom/www.lifehacker.jp/index.js
//

import Foundation
import SwiftSoup

struct LifehackerJpCustomDomainExtractionRule: DomainExtractionRule {
    let id = "custom_www_lifehacker_jp"

    func matches(url: URL) -> Bool {
        CustomDomainRuleSupport.matches(url: url, domain: "www.lifehacker.jp")
    }

    func preferredContentRoot(in doc: Document) throws -> Element? {
        let selectors: [String] =
        [
            "div[class^=\"article_pArticle_Body__\"]",
            "div.lh-entryDetail-body",
        ]

        return try CustomDomainRuleSupport.firstMatchingElement(in: doc, selectors: selectors)
    }

    func candidateScoreAdjustments(in doc: Document) throws -> [DomainCandidateAdjustment] {
        let positiveSignals: [(selector: String, delta: Double)] = [
            (selector: "div[class^=\"article_pArticle_Body__\"]", delta: 140.0),
            (selector: "div.lh-entryDetail-body", delta: 140.0),
            (selector: "h1[class^=\"article_pArticle_Title\"]", delta: 20.0),
            (selector: "h1.lh-summary-title", delta: 20.0),
            (selector: "meta[name=\"author\"]", delta: 8.0),
            (selector: "p.lh-entryDetailInner--credit", delta: 8.0),
        ]

        let negativeSignals: [(selector: String, delta: Double)] = [
            (selector: "header", delta: -70.0),
            (selector: "nav", delta: -70.0),
            (selector: "aside", delta: -55.0),
            (selector: "footer", delta: -80.0),
            (selector: "p.lh-entryDetailInner--credit", delta: -120.0),
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
            "h1[class^=\"article_pArticle_Title\"]",
            "h1.lh-summary-title",
        ]
        let authorSelectors: [String] =
        [
            "meta[name=\"author\"]",
            "p.lh-entryDetailInner--credit",
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
