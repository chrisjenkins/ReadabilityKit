//
//  RedditComCustomDomainExtractionRule.swift
//  ReadabilityKit
//
//  Auto-generated from Tests/ReadabilityKitTests/Custom/www.reddit.com/index.js
//

import Foundation
import SwiftSoup

struct RedditComCustomDomainExtractionRule: DomainExtractionRule {
    let id = "custom_www_reddit_com"

    func matches(url: URL) -> Bool {
        CustomDomainRuleSupport.matches(url: url, domain: "www.reddit.com")
    }

    func preferredContentRoot(in doc: Document) throws -> Element? {
        let selectors: [String] =
        [
            "div[data-test-id=\"post-content\"] p",
            "div[data-test-id=\"post-content\"] a[target=\"_blank\"]:not([data-click-id=\"timestamp\"])",
            "div[data-test-id=\"post-content\"] div[data-click-id=\"media\"]",
            "div[data-test-id=\"post-content\"] a",
            "div[data-test-id=\"post-content\"]",
        ]

        return try CustomDomainRuleSupport.firstMatchingElement(in: doc, selectors: selectors)
    }

    func candidateScoreAdjustments(in doc: Document) throws -> [DomainCandidateAdjustment] {
        let positiveSignals: [(selector: String, delta: Double)] = [
            (selector: "div[data-test-id=\"post-content\"] p", delta: 140.0),
            (selector: "div[data-test-id=\"post-content\"] a[target=\"_blank\"]:not([data-click-id=\"timestamp\"])", delta: 140.0),
            (selector: "div[data-test-id=\"post-content\"] div[data-click-id=\"media\"]", delta: 140.0),
            (selector: "div[data-test-id=\"post-content\"] a", delta: 140.0),
            (selector: "div[data-test-id=\"post-content\"]", delta: 140.0),
            (selector: "div[data-test-id=\"post-content\"] h1", delta: 20.0),
            (selector: "div[data-test-id=\"post-content\"] h2", delta: 20.0),
            (selector: "div[data-test-id=\"post-content\"] a[href*=\"user/\"]", delta: 8.0),
        ]

        let negativeSignals: [(selector: String, delta: Double)] = [
            (selector: "header", delta: -70.0),
            (selector: "nav", delta: -70.0),
            (selector: "aside", delta: -55.0),
            (selector: "footer", delta: -80.0),
            (selector: ".icon", delta: -120.0),
            (selector: "span[id^=\"PostAwardBadges\"]", delta: -120.0),
            (selector: "div a[data-test-id=\"comments-page-link-num-comments\"]", delta: -120.0),
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
            "div[data-test-id=\"post-content\"] h1",
            "div[data-test-id=\"post-content\"] h2",
        ]
        let authorSelectors: [String] =
        [
            "div[data-test-id=\"post-content\"] a[href*=\"user/\"]",
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
