//
//  BBCNewsArticlesDomainExtractionRule.swift
//  ReadabilityKit
//
//  Derived from Tests/ReadabilityKitTests/Resources/bbc-news.html
//

import Foundation
import SwiftSoup

/// Domain-specific extraction rule for modern BBC News article pages.
///
/// Targets the `bbc.co.uk/news/articles/*` and `bbc.com/news/articles/*` layout using
/// `data-block` and `data-testid` signals from the `bbc-news.html` fixture.
struct BBCNewsArticlesDomainExtractionRule: DomainExtractionRule {
    let id = "bbc_news_articles"

    func matches(url: URL) -> Bool {
        guard let host = url.host?.lowercased() else { return false }
        let isBBCHost = host.contains("bbc.co.uk") || host.contains("bbc.com")
        return isBBCHost && url.path.lowercased().contains("/news/articles/")
    }

    func preferredContentRoot(in doc: Document) throws -> Element? {
        let selectors: [String] = [
            "main#main-content article",
            "#main-content article",
            "article",
        ]

        return try CustomDomainRuleSupport.firstMatchingElement(in: doc, selectors: selectors)
    }

    func candidateScoreAdjustments(in doc: Document) throws -> [DomainCandidateAdjustment] {
        let positiveSignals: [(selector: String, delta: Double)] = [
            (selector: "main#main-content article", delta: 240.0),
            (selector: "#main-content article", delta: 220.0),
            (selector: "[data-block=\"text\"]", delta: 65.0),
            (selector: "[data-testid=\"rich-text\"]", delta: 60.0),
            (selector: "[data-block=\"headline\"]", delta: 30.0),
            (selector: "[data-block=\"byline\"]", delta: 18.0),
            (selector: "[data-block=\"image\"]", delta: 16.0),
            (selector: "[data-block=\"metadata\"]", delta: 8.0),
        ]

        let negativeSignals: [(selector: String, delta: Double)] = [
            (selector: "header#header-content", delta: -130.0),
            (selector: "nav[data-testid=\"navigation\"]", delta: -90.0),
            (selector: "[data-component=\"topStories\"]", delta: -120.0),
            (selector: "[data-component=\"features\"]", delta: -120.0),
            (selector: "[data-component=\"mostRead\"]", delta: -120.0),
            (selector: "[data-component=\"elsewhere-loading\"]", delta: -100.0),
            (selector: "[data-testid=\"promo\"]", delta: -75.0),
            (selector: "[data-block=\"links\"]", delta: -24.0),
            (selector: "[data-block=\"topicList\"]", delta: -16.0),
            (selector: "footer#footer-content", delta: -120.0),
            (selector: "aside", delta: -55.0),
            (selector: "nav", delta: -60.0),
            (selector: "footer", delta: -90.0),
        ]

        return try CustomDomainRuleSupport.candidateScoreAdjustments(
            in: doc,
            positiveSignals: positiveSignals,
            negativeSignals: negativeSignals
        )
    }

    func metadataOverrides(in doc: Document, fallbackURL: URL) throws -> DomainMetadataOverride {
        let titleSelectors: [String] = [
            "#main-heading",
            "meta[property=\"og:title\"]",
        ]

        let authorSelectors: [String] = [
            "[data-testid=\"multi-byline\"]",
            "meta[property=\"cXenseParse:author\"]",
        ]

        let excerptSelectors: [String] = [
            "meta[property=\"og:description\"]",
            "meta[name=\"description\"]",
        ]

        let leadImageSelectors: [String] = [
            "[data-testid=\"image\"] img",
            "meta[property=\"og:image\"]",
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
