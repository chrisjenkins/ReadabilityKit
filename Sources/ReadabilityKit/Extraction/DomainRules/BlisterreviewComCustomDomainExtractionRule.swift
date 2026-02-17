//
//  BlisterreviewComCustomDomainExtractionRule.swift
//  ReadabilityKit
//
//  Auto-generated from Tests/ReadabilityKitTests/Custom/blisterreview.com/index.js
//

import Foundation
import SwiftSoup

struct BlisterreviewComCustomDomainExtractionRule: DomainExtractionRule {
    let id = "custom_blisterreview_com"

    func matches(url: URL) -> Bool {
        CustomDomainRuleSupport.matches(url: url, domain: "blisterreview.com")
    }

    func preferredContentRoot(in doc: Document) throws -> Element? {
        let selectors: [String] =
        [
            ".elementor-section-wrap",
            ".elementor-text-editor > p, .elementor-text-editor > ul > li, .attachment-large, .wp-caption-text",
        ]

        return try CustomDomainRuleSupport.firstMatchingElement(in: doc, selectors: selectors)
    }

    func candidateScoreAdjustments(in doc: Document) throws -> [DomainCandidateAdjustment] {
        let positiveSignals: [(selector: String, delta: Double)] = [
            (selector: ".elementor-section-wrap", delta: 140.0),
            (selector: ".elementor-text-editor > p, .elementor-text-editor > ul > li, .attachment-large, .wp-caption-text", delta: 140.0),
            (selector: "meta[name=\"og:title\"]", delta: 20.0),
            (selector: "h1.entry-title", delta: 20.0),
            (selector: "span.author-name", delta: 8.0),
        ]

        let negativeSignals: [(selector: String, delta: Double)] = [
            (selector: "header", delta: -70.0),
            (selector: "nav", delta: -70.0),
            (selector: "aside", delta: -55.0),
            (selector: "footer", delta: -80.0),
            (selector: ".comments-area", delta: -120.0),
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
            "span.author-name",
        ]
        let excerptSelectors: [String] =
        [
        ]
        let leadImageSelectors: [String] =
        [
            "meta[name=\"og:image\"]",
            "meta[property=\"og:image\"]",
            "content",
            "meta[itemprop=\"image\"]",
            "meta[name=\"twitter:image\"]",
            "img.attachment-large",
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
