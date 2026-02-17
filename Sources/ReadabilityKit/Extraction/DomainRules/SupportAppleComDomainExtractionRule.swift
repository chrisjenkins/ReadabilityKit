//
//  SupportAppleComDomainExtractionRule.swift
//  ReadabilityKit
//
//  Derived from Tests/ReadabilityKitTests/Resources/apple.html
//

import Foundation
import SwiftSoup

/// Domain-specific extraction rule for Apple Support guide pages.
///
/// The Apple fixture contains a very large table-of-contents region plus global chrome.
/// This rule strongly boosts the dedicated article section and demotes TOC/navigation/footer
/// blocks so candidate selection converges on the actual guide article body.
struct SupportAppleComDomainExtractionRule: DomainExtractionRule {
    let id = "support_apple_com"

    func matches(url: URL) -> Bool {
        CustomDomainRuleSupport.matches(url: url, domain: "support.apple.com")
    }

    func preferredContentRoot(in doc: Document) throws -> Element? {
        let selectors: [String] = [
            "#article-section-wrapper #article-section .book-content > div",
            "#article-section-wrapper #article-section .book-content",
            "#article-section-wrapper #article-section",
        ]

        return try CustomDomainRuleSupport.firstMatchingElement(in: doc, selectors: selectors)
    }

    func candidateScoreAdjustments(in doc: Document) throws -> [DomainCandidateAdjustment] {
        let positiveSignals: [(selector: String, delta: Double)] = [
            (selector: "#article-section-wrapper #article-section .book-content > div", delta: 260.0),
            (selector: "#article-section-wrapper #article-section .book-content", delta: 220.0),
            (selector: "#article-section-wrapper #article-section", delta: 180.0),
            (selector: "#article-section h1", delta: 24.0),
            (selector: "#article-section .TaskBody", delta: 40.0),
            (selector: "#article-section figure", delta: 12.0),
        ]

        let negativeSignals: [(selector: String, delta: Double)] = [
            (selector: "#toc-section-wrapper", delta: -170.0),
            (selector: "#toc-hidden-content", delta: -190.0),
            (selector: "#globalheader", delta: -160.0),
            (selector: "#article-pagination-wrapper", delta: -80.0),
            (selector: "#helpful-rating-wrapper", delta: -120.0),
            (selector: ".footer-wrapper", delta: -130.0),
            (selector: "footer", delta: -90.0),
            (selector: "nav", delta: -70.0),
            (selector: "aside", delta: -70.0),
        ]

        return try CustomDomainRuleSupport.candidateScoreAdjustments(
            in: doc,
            positiveSignals: positiveSignals,
            negativeSignals: negativeSignals
        )
    }

    func metadataOverrides(in doc: Document, fallbackURL: URL) throws -> DomainMetadataOverride {
        let titleSelectors: [String] = [
            "#article-section h1",
            "meta[property=\"og:title\"]",
        ]

        let excerptSelectors: [String] = [
            "meta[property=\"og:description\"]",
            "meta[name=\"description\"]",
            "#article-section p",
        ]

        let leadImageSelectors: [String] = [
            "#article-section figure img",
            "meta[property=\"og:image\"]",
        ]

        return try CustomDomainRuleSupport.metadataOverrides(
            in: doc,
            fallbackURL: fallbackURL,
            titleSelectors: titleSelectors,
            authorSelectors: [],
            excerptSelectors: excerptSelectors,
            leadImageSelectors: leadImageSelectors
        )
    }
}
