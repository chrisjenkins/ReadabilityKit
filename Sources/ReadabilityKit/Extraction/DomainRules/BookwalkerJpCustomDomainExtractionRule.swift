//
//  BookwalkerJpCustomDomainExtractionRule.swift
//  ReadabilityKit
//
//  Auto-generated from Tests/ReadabilityKitTests/Custom/bookwalker.jp/index.js
//

import Foundation
import SwiftSoup

struct BookwalkerJpCustomDomainExtractionRule: DomainExtractionRule {
    let id = "custom_bookwalker_jp"

    func matches(url: URL) -> Bool {
        CustomDomainRuleSupport.matches(url: url, domain: "bookwalker.jp")
    }

    func preferredContentRoot(in doc: Document) throws -> Element? {
        let selectors: [String] =
        [
            "div.p-main__information",
            "div.main-info",
            "div.main-cover-inner",
        ]

        return try CustomDomainRuleSupport.firstMatchingElement(in: doc, selectors: selectors)
    }

    func candidateScoreAdjustments(in doc: Document) throws -> [DomainCandidateAdjustment] {
        let positiveSignals: [(selector: String, delta: Double)] = [
            (selector: "div.p-main__information", delta: 140.0),
            (selector: "div.main-info", delta: 140.0),
            (selector: "div.main-cover-inner", delta: 140.0),
            (selector: "h1.p-main__title", delta: 20.0),
            (selector: "h1.main-heading", delta: 20.0),
            (selector: "div.p-author__list", delta: 8.0),
            (selector: "div.authors", delta: 8.0),
        ]

        let negativeSignals: [(selector: String, delta: Double)] = [
            (selector: "header", delta: -70.0),
            (selector: "nav", delta: -70.0),
            (selector: "aside", delta: -55.0),
            (selector: "footer", delta: -80.0),
            (selector: "span.label.label--trial", delta: -120.0),
            (selector: "dt.info-head.info-head--coin", delta: -120.0),
            (selector: "dd.info-contents.info-contents--coin", delta: -120.0),
            (selector: "div.info-notice.fn-toggleClass", delta: -120.0),
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
            "h1.p-main__title",
            "h1.main-heading",
        ]
        let authorSelectors: [String] =
        [
            "div.p-author__list",
            "div.authors",
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
