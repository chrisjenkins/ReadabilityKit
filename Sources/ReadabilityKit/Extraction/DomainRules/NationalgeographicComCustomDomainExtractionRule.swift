//
//  NationalgeographicComCustomDomainExtractionRule.swift
//  ReadabilityKit
//
//  Auto-generated from Tests/ReadabilityKitTests/Custom/www.nationalgeographic.com/index.js
//

import Foundation
import SwiftSoup

struct NationalgeographicComCustomDomainExtractionRule: DomainExtractionRule {
    let id = "custom_www_nationalgeographic_com"

    func matches(url: URL) -> Bool {
        CustomDomainRuleSupport.matches(url: url, domain: "www.nationalgeographic.com")
    }

    func preferredContentRoot(in doc: Document) throws -> Element? {
        let selectors: [String] =
        [
            "section.Article__Content",
            ".parsys.content",
            ".__image-lead__",
            ".content",
        ]

        return try CustomDomainRuleSupport.firstMatchingElement(in: doc, selectors: selectors)
    }

    func candidateScoreAdjustments(in doc: Document) throws -> [DomainCandidateAdjustment] {
        let positiveSignals: [(selector: String, delta: Double)] = [
            (selector: "section.Article__Content", delta: 140.0),
            (selector: ".parsys.content", delta: 140.0),
            (selector: ".__image-lead__", delta: 140.0),
            (selector: ".content", delta: 140.0),
            (selector: "h1", delta: 20.0),
            (selector: "h1.main-title", delta: 20.0),
            (selector: ".byline-component__contributors b span", delta: 8.0),
        ]

        let negativeSignals: [(selector: String, delta: Double)] = [
            (selector: "header", delta: -70.0),
            (selector: "nav", delta: -70.0),
            (selector: "aside", delta: -55.0),
            (selector: "footer", delta: -80.0),
            (selector: ".pull-quote.pull-quote--small", delta: -120.0),
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
            "h1",
            "h1.main-title",
        ]
        let authorSelectors: [String] =
        [
            ".byline-component__contributors b span",
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
