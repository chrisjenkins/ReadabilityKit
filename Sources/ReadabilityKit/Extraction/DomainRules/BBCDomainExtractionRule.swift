//
//  BBCDomainExtractionRule.swift
//  ReadabilityKit
//
//  Created by Chris Jenkins on 17/02/2026.
//

import Foundation
import SwiftSoup

/// Domain-specific extraction rule for BBC article pages.
///
/// This rule prefers stable BBC article containers, boosts known article blocks, penalizes
/// known chrome/advertisement blocks, and provides BBC-specific metadata fallback signals.
///
/// ## Selector Sources
/// These selectors are derived from the checked-in BBC fixture:
/// `/Users/chrisjenkins/Developer/ReadabilityKit/Tests/ReadabilityKitTests/Resources/bbc.html`
///
/// Fixture origin is the BBC article:
/// `https://www.bbc.com/news/articles/c70ne31d884o`
///
/// The fixture includes the key attributes used here, including:
/// - `article[data-testid="chester-article"]`
/// - `data-component="text-block"`
/// - `data-component="headline-block"`
/// - `data-component="byline-block"`
/// - `data-component="subheadline-block"`
/// - `data-component="links-block"`
/// - `data-component="tag-list-block"`
/// - `data-component="advertisement-block"`
/// - `data-component="ad-slot"`
struct BBCDomainExtractionRule: DomainExtractionRule {
    /// Stable rule identifier.
    let id = "bbc"

    /// Matches BBC hosts served from `bbc.com` and `bbc.co.uk`.
    /// - Parameter url: Source URL.
    func matches(url: URL) -> Bool {
        guard let host = url.host?.lowercased() else { return false }
        return host.contains("bbc.com") || host.contains("bbc.co.uk")
    }

    /// Returns a preferred BBC article root for `preferRules` mode.
    ///
    /// Selector priority:
    /// 1. `article[data-testid=chester-article]` (most specific to current BBC article layout)
    /// 2. `main#main-content article`
    /// 3. `#main-content article`
    ///
    /// Source: BBC fixture listed in the type-level documentation.
    /// - Parameter doc: Parsed source document.
    func preferredContentRoot(in doc: Document) throws -> Element? {
        let selectors = [
            "article[data-testid=chester-article]",
            "main#main-content article",
            "#main-content article",
        ]

        for selector in selectors {
            if let element = try doc.select(selector).first() {
                return element
            }
        }

        return nil
    }

    /// Applies BBC-specific candidate score hints.
    ///
    /// Positive deltas prioritize content blocks. Negative deltas demote ads/navigation/footer.
    ///
    /// Signal rationale:
    /// - `article[data-testid=chester-article]`: strong container boost.
    /// - `data-component=*text/headline/byline/subheadline*`: moderate article-structure boosts.
    /// - `data-component=*links/tag-list*`: mild demotion for non-primary article utilities.
    /// - `data-component=*advertisement/ad-slot*`: strong demotion for monetization blocks.
    /// - `header/nav/footer`: generic structural demotion to reduce chrome.
    ///
    /// Source: BBC fixture listed in the type-level documentation.
    /// - Parameter doc: Parsed source document.
    func candidateScoreAdjustments(in doc: Document) throws -> [DomainCandidateAdjustment] {
        let signals: [(selector: String, delta: Double)] = [
            ("article[data-testid=chester-article]", 220),
            ("[data-component=text-block]", 50),
            ("[data-component=headline-block]", 30),
            ("[data-component=byline-block]", 18),
            ("[data-component=subheadline-block]", 16),
            ("[data-component=links-block]", -28),
            ("[data-component=tag-list-block]", -24),
            ("[data-component=advertisement-block]", -120),
            ("[data-component=ad-slot]", -120),
            ("header", -60),
            ("nav", -70),
            ("footer", -70),
        ]

        var out: [DomainCandidateAdjustment] = []
        out.reserveCapacity(48)

        for signal in signals {
            let elements = try doc.select(signal.selector).array()
            for element in elements {
                out.append(.init(element: element, scoreDelta: signal.delta))
            }
        }

        return out
    }

    /// Returns BBC-specific metadata overrides.
    ///
    /// Uses BBC-specific author signal first:
    /// - `meta[property=cXenseParse:author]`
    /// then falls back to byline contributor blocks:
    /// - `[data-testid=byline-contributors-contributor-0]`
    ///
    /// Description and image use standard Open Graph fields when present.
    ///
    /// Source: BBC fixture listed in the type-level documentation.
    /// - Parameters:
    ///   - doc: Parsed source document.
    ///   - fallbackURL: Canonical URL used to resolve relative image URLs.
    func metadataOverrides(in doc: Document, fallbackURL: URL) throws -> DomainMetadataOverride {
        let byline =
            try doc.select("meta[property=cXenseParse:author]").first()?.attr("content")
                .trimmingCharacters(in: .whitespacesAndNewlines)
            ?? doc.select("[data-testid=byline-contributors-contributor-0]").first?.text()
                .trimmingCharacters(in: .whitespacesAndNewlines)

        let excerpt =
            try doc.select("meta[property=og:description]").first()?.attr("content")
                .trimmingCharacters(in: .whitespacesAndNewlines)
            ?? doc.select("meta[name=description]").first()?.attr("content")
                .trimmingCharacters(in: .whitespacesAndNewlines)

        let leadImageRaw =
            try doc.select("meta[property=og:image]").first()?.attr("content")
                .trimmingCharacters(in: .whitespacesAndNewlines)

        return DomainMetadataOverride(
            title: nil,
            byline: (byline?.isEmpty == true) ? nil : byline,
            excerpt: (excerpt?.isEmpty == true) ? nil : excerpt,
            leadImageURL: resolveURL(leadImageRaw, fallbackURL: fallbackURL)
        )
    }

    /// Resolves an optional raw URL string against the fallback URL.
    private func resolveURL(_ value: String?, fallbackURL: URL) -> URL? {
        guard let value else { return nil }
        let cleaned = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleaned.isEmpty else { return nil }
        if let absolute = URL(string: cleaned), absolute.scheme != nil {
            return absolute
        }
        return URL(string: cleaned, relativeTo: fallbackURL)?.absoluteURL
    }
}
