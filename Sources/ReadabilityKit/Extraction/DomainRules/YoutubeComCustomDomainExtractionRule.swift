//
//  YoutubeComCustomDomainExtractionRule.swift
//  ReadabilityKit
//
//  Auto-generated from Tests/ReadabilityKitTests/Custom/www.youtube.com/index.js
//

import Foundation
import SwiftSoup

struct YoutubeComCustomDomainExtractionRule: DomainExtractionRule {
    let id = "custom_www_youtube_com"

    func matches(url: URL) -> Bool {
        CustomDomainRuleSupport.matches(url: url, domain: "www.youtube.com")
    }

    func preferredContentRoot(in doc: Document) throws -> Element? {
        let selectors: [String] =
        [
            "#player-container-outer",
            "ytd-expandable-video-description-body-renderer #description",
            "#player-api",
            "#description",
        ]

        return try CustomDomainRuleSupport.firstMatchingElement(in: doc, selectors: selectors)
    }

    func candidateScoreAdjustments(in doc: Document) throws -> [DomainCandidateAdjustment] {
        let positiveSignals: [(selector: String, delta: Double)] = [
            (selector: "#player-container-outer", delta: 140.0),
            (selector: "ytd-expandable-video-description-body-renderer #description", delta: 140.0),
            (selector: "#player-api", delta: 140.0),
            (selector: "#description", delta: 140.0),
            (selector: "meta[name=\"title\"]", delta: 20.0),
            (selector: ".watch-title", delta: 20.0),
            (selector: "h1.watch-title-container", delta: 20.0),
            (selector: "link[itemprop=\"name\"]", delta: 8.0),
            (selector: "content", delta: 8.0),
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
            "meta[name=\"title\"]",
            ".watch-title",
            "h1.watch-title-container",
        ]
        let authorSelectors: [String] =
        [
            "link[itemprop=\"name\"]",
            "content",
            ".yt-user-info",
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
