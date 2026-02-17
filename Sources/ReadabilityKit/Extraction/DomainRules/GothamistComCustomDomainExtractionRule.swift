//
//  GothamistComCustomDomainExtractionRule.swift
//  ReadabilityKit
//
//  Auto-generated from Tests/ReadabilityKitTests/Custom/gothamist.com/index.js
//

import Foundation
import SwiftSoup

struct GothamistComCustomDomainExtractionRule: DomainExtractionRule {
    let id = "custom_gothamist_com"

    func matches(url: URL) -> Bool {
        CustomDomainRuleSupport.matches(url: url, domain: "gothamist.com")
    }

    func preferredContentRoot(in doc: Document) throws -> Element? {
        let selectors: [String] =
        [
            ".article-body",
            ".entry-body",
        ]

        return try CustomDomainRuleSupport.firstMatchingElement(in: doc, selectors: selectors)
    }

    func candidateScoreAdjustments(in doc: Document) throws -> [DomainCandidateAdjustment] {
        let positiveSignals: [(selector: String, delta: Double)] = [
            (selector: ".article-body", delta: 140.0),
            (selector: ".entry-body", delta: 140.0),
            (selector: "h1", delta: 20.0),
            (selector: ".entry-header h1", delta: 20.0),
            (selector: ".article-metadata:nth-child(3) .byline-author", delta: 8.0),
            (selector: ".author", delta: 8.0),
        ]

        let negativeSignals: [(selector: String, delta: Double)] = [
            (selector: "header", delta: -70.0),
            (selector: "nav", delta: -70.0),
            (selector: "aside", delta: -55.0),
            (selector: "footer", delta: -80.0),
            (selector: ".image-none br", delta: -120.0),
            (selector: ".image-left br", delta: -120.0),
            (selector: ".image-right br", delta: -120.0),
            (selector: ".galleryEase", delta: -120.0),
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
            ".entry-header h1",
        ]
        let authorSelectors: [String] =
        [
            ".article-metadata:nth-child(3) .byline-author",
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
