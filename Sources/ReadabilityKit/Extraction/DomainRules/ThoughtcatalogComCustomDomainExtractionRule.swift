//
//  ThoughtcatalogComCustomDomainExtractionRule.swift
//  ReadabilityKit
//
//  Auto-generated from Tests/ReadabilityKitTests/Custom/thoughtcatalog.com/index.js
//

import Foundation
import SwiftSoup

struct ThoughtcatalogComCustomDomainExtractionRule: DomainExtractionRule {
    let id = "custom_thoughtcatalog_com"

    func matches(url: URL) -> Bool {
        CustomDomainRuleSupport.matches(url: url, domain: "thoughtcatalog.com")
    }

    func preferredContentRoot(in doc: Document) throws -> Element? {
        let selectors: [String] =
        [
            ".entry.post",
        ]

        return try CustomDomainRuleSupport.firstMatchingElement(in: doc, selectors: selectors)
    }

    func candidateScoreAdjustments(in doc: Document) throws -> [DomainCandidateAdjustment] {
        let positiveSignals: [(selector: String, delta: Double)] = [
            (selector: ".entry.post", delta: 140.0),
            (selector: "h1.title", delta: 20.0),
            (selector: "meta[name=\"og:title\"]", delta: 20.0),
            (selector: "cite a", delta: 8.0),
            (selector: "div.col-xs-12.article_header div.writer-container.writer-container-inline.writer-no-avatar h4.writer-name", delta: 8.0),
        ]

        let negativeSignals: [(selector: String, delta: Double)] = [
            (selector: "header", delta: -70.0),
            (selector: "nav", delta: -70.0),
            (selector: "aside", delta: -55.0),
            (selector: "footer", delta: -80.0),
            (selector: ".tc_mark", delta: -120.0),
            (selector: "figcaption", delta: -120.0),
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
            "h1.title",
            "meta[name=\"og:title\"]",
        ]
        let authorSelectors: [String] =
        [
            "cite a",
            "div.col-xs-12.article_header div.writer-container.writer-container-inline.writer-no-avatar h4.writer-name",
            "h1.writer-name",
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
