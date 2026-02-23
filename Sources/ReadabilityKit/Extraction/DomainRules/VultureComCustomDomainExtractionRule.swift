//
//  VultureComCustomDomainExtractionRule.swift
//  ReadabilityKit
//
//  Derived from /Users/chrisjenkins/Developer/ReadabilityKit/Mercury/fixtures/www.vulture.com.html
//

import Foundation
import SwiftSoup

/// Domain-specific extraction rule for Vulture article pages.
struct VultureComCustomDomainExtractionRule: DomainExtractionRule {
    let id = "custom_vulture_com"

    func matches(url: URL) -> Bool {
        CustomDomainRuleSupport.matches(url: url, domain: "vulture.com")
    }

    func preferredContentRoot(in doc: Document) throws -> Element? {
        let selectors: [String] = [
            "article.article.inline",
            "article.article",
            ".article-content.inline[itemprop=\"articleBody\"]",
            ".article-content[itemprop=\"articleBody\"]",
        ]

        return try CustomDomainRuleSupport.firstMatchingElement(in: doc, selectors: selectors)
    }

    func candidateScoreAdjustments(in doc: Document) throws -> [DomainCandidateAdjustment] {
        let positiveSignals: [(selector: String, delta: Double)] = [
            (selector: "article.article.inline", delta: 180.0),
            (selector: "article.article", delta: 160.0),
            (selector: ".article-content.inline[itemprop=\"articleBody\"]", delta: 140.0),
            (selector: ".article-content[itemprop=\"articleBody\"]", delta: 140.0),
            (selector: "section.body", delta: 90.0),
            (selector: "h1.headline-primary", delta: 24.0),
            (selector: ".primary-bylines", delta: 10.0),
            (selector: ".article-author", delta: 10.0),
        ]

        let negativeSignals: [(selector: String, delta: Double)] = [
            (selector: ".global-nav", delta: -120.0),
            (selector: ".article-nav", delta: -95.0),
            (selector: ".latest-news", delta: -110.0),
            (selector: ".comments-link_article-nav", delta: -60.0),
            (selector: "#comments", delta: -70.0),
            (selector: "footer", delta: -90.0),
            (selector: "nav", delta: -70.0),
            (selector: "aside", delta: -60.0),
        ]

        return try CustomDomainRuleSupport.candidateScoreAdjustments(
            in: doc,
            positiveSignals: positiveSignals,
            negativeSignals: negativeSignals
        )
    }

    func metadataOverrides(in doc: Document, fallbackURL: URL) throws -> DomainMetadataOverride {
        let titleSelectors: [String] = [
            "h1.headline-primary",
            "meta[name=\"og:title\"]",
        ]

        let authorSelectors: [String] = [
            ".article-author",
            ".primary-bylines",
            "meta[name=\"author\"]",
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
