//
//  ReutersComCustomDomainExtractionRule.swift
//  ReadabilityKit
//
//  Auto-generated from Tests/ReadabilityKitTests/Custom/www.reuters.com/index.js
//

import Foundation
import SwiftSoup

struct ReutersComCustomDomainExtractionRule: DomainExtractionRule {
    let id = "custom_www_reuters_com"

    func matches(url: URL) -> Bool {
        CustomDomainRuleSupport.matches(url: url, domain: "www.reuters.com")
    }

    func preferredContentRoot(in doc: Document) throws -> Element? {
        let selectors: [String] =
        [
            "div.ArticleBodyWrapper",
            "#article-text",
        ]

        return try CustomDomainRuleSupport.firstMatchingElement(in: doc, selectors: selectors)
    }

    func candidateScoreAdjustments(in doc: Document) throws -> [DomainCandidateAdjustment] {
        let positiveSignals: [(selector: String, delta: Double)] = [
            (selector: "div.ArticleBodyWrapper", delta: 140.0),
            (selector: "#article-text", delta: 140.0),
            (selector: "h1[class*=\"ArticleHeader-headline-\"]", delta: 20.0),
            (selector: "h1.article-headline", delta: 20.0),
            (selector: "meta[name=\"og:article:author\"]", delta: 8.0),
            (selector: ".author", delta: 8.0),
        ]

        let negativeSignals: [(selector: String, delta: Double)] = [
            (selector: "header", delta: -70.0),
            (selector: "nav", delta: -70.0),
            (selector: "aside", delta: -55.0),
            (selector: "footer", delta: -80.0),
            (selector: "div[class^=\"ArticleBody-byline-container-\"]", delta: -120.0),
            (selector: "#article-byline .author", delta: -120.0),
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
            "h1[class*=\"ArticleHeader-headline-\"]",
            "h1.article-headline",
        ]
        let authorSelectors: [String] =
        [
            "meta[name=\"og:article:author\"]",
            ".author",
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
