//
//  SandiegouniontribuneComCustomDomainExtractionRule.swift
//  ReadabilityKit
//
//  Derived from /Users/chrisjenkins/Developer/ReadabilityKit/Mercury/fixtures/sandiegouniontribune.com.html
//

import Foundation
import SwiftSoup

/// Domain-specific extraction rule for San Diego Union-Tribune article pages.
struct SandiegouniontribuneComCustomDomainExtractionRule: DomainExtractionRule {
    let id = "custom_sandiegouniontribune_com"

    func matches(url: URL) -> Bool {
        CustomDomainRuleSupport.matches(url: url, domain: "sandiegouniontribune.com")
    }

    func preferredContentRoot(in doc: Document) throws -> Element? {
        let selectors: [String] = [
            "article.ArticlePage-mainContent",
            ".ArticlePage-mainContent",
            ".ArticlePage-storyBody",
        ]

        return try CustomDomainRuleSupport.firstMatchingElement(in: doc, selectors: selectors)
    }

    func candidateScoreAdjustments(in doc: Document) throws -> [DomainCandidateAdjustment] {
        let positiveSignals: [(selector: String, delta: Double)] = [
            (selector: "article.ArticlePage-mainContent", delta: 180.0),
            (selector: ".ArticlePage-mainContent", delta: 160.0),
            (selector: ".ArticlePage-storyBody", delta: 120.0),
            (selector: ".ArticlePage-headline", delta: 24.0),
            (selector: ".ArticlePage-byline", delta: 10.0),
            (selector: ".ArticlePage-authorName", delta: 10.0),
        ]

        let negativeSignals: [(selector: String, delta: Double)] = [
            (selector: "ps-header", delta: -130.0),
            (selector: ".Page-header-wrapper", delta: -130.0),
            (selector: ".Navigation", delta: -80.0),
            (selector: ".ArticlePage-authorInfo", delta: -50.0),
            (selector: ".ListD-header-title", delta: -40.0),
            (selector: "footer", delta: -90.0),
            (selector: "nav", delta: -70.0),
            (selector: "aside", delta: -55.0),
        ]

        return try CustomDomainRuleSupport.candidateScoreAdjustments(
            in: doc,
            positiveSignals: positiveSignals,
            negativeSignals: negativeSignals
        )
    }

    func metadataOverrides(in doc: Document, fallbackURL: URL) throws -> DomainMetadataOverride {
        let titleSelectors: [String] = [
            ".ArticlePage-headline",
            "meta[name=\"og:title\"]",
        ]

        let authorSelectors: [String] = [
            ".ArticlePage-authorName",
            ".ArticlePage-byline",
            "meta[name=\"article:author\"]",
        ]

        let excerptSelectors: [String] = [
            "meta[name=\"og:description\"]",
            "meta[name=\"description\"]",
        ]

        let leadImageSelectors: [String] = [
            "meta[name=\"og:image\"]",
            "meta[name=\"twitter:image\"]",
        ]

        return try CustomDomainRuleSupport.metadataOverrides(
            in: doc,
            fallbackURL: fallbackURL,
            titleSelectors: titleSelectors,
            authorSelectors: authorSelectors,
            excerptSelectors: excerptSelectors,
            leadImageSelectors: leadImageSelectors
        )
    }
}
