//
//  PeopleComCustomDomainExtractionRule.swift
//  ReadabilityKit
//
//  Auto-generated from Tests/ReadabilityKitTests/Custom/people.com/index.js
//

import Foundation
import SwiftSoup

struct PeopleComCustomDomainExtractionRule: DomainExtractionRule {
    let id = "custom_people_com"

    func matches(url: URL) -> Bool {
        CustomDomainRuleSupport.matches(url: url, domain: "people.com")
    }

    func preferredContentRoot(in doc: Document) throws -> Element? {
        let selectors: [String] =
        [
            "div[class^=\"loc article-content\"]",
            "div.article-body__inner",
        ]

        return try CustomDomainRuleSupport.firstMatchingElement(in: doc, selectors: selectors)
    }

    func candidateScoreAdjustments(in doc: Document) throws -> [DomainCandidateAdjustment] {
        let positiveSignals: [(selector: String, delta: Double)] = [
            (selector: "div[class^=\"loc article-content\"]", delta: 140.0),
            (selector: "div.article-body__inner", delta: 140.0),
            (selector: ".article-header h1", delta: 20.0),
            (selector: "meta[name=\"og:title\"]", delta: 20.0),
            (selector: "meta[name=\"sailthru.author\"]", delta: 8.0),
            (selector: "a.author.url.fn", delta: 8.0),
        ]

        let negativeSignals: [(selector: String, delta: Double)] = [
            (selector: "header", delta: -70.0),
            (selector: "nav", delta: -70.0),
            (selector: "aside", delta: -55.0),
            (selector: "footer", delta: -80.0),
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
            ".article-header h1",
            "meta[name=\"og:title\"]",
        ]
        let authorSelectors: [String] =
        [
            "meta[name=\"sailthru.author\"]",
            "a.author.url.fn",
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
