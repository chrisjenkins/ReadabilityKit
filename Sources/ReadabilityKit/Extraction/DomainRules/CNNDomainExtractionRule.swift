//
//  CNNDomainExtractionRule.swift
//  ReadabilityKit
//
//  Created by Chris Jenkins on 17/02/2026.
//

import Foundation
import SwiftSoup

/// Domain-specific extraction rule for CNN pages.
///
/// ## Selector Sources
/// The selectors in this rule are based on the checked-in CNN fixture:
/// `/Users/chrisjenkins/Developer/ReadabilityKit/Tests/ReadabilityKitTests/Resources/cnn.html`
///
/// URL scope reference used for rule matching:
/// `https://www.cnn.com/2026/02/16/uk/beatrice-eugenie-parents-epstein-scandal-fallout-intl`
///
/// Selectors present in the fixture and used by this rule:
/// - `article[data-component-name=article]`
/// - `.article__main`
/// - `.article__content`
/// - `[data-component-name=paragraph]`
/// - `[data-component-name=headline]`
/// - `[data-component-name=byline]`
/// - `.ad-slot`
/// - `#pageHeader`
///
/// Note: This rule is designed as heuristic support and intentionally includes fallback selectors
/// because publisher markup can change over time.
struct CNNDomainExtractionRule: DomainExtractionRule {
    let id = "cnn"

    func matches(url: URL) -> Bool {
        guard let host = url.host?.lowercased() else { return false }
        return host.contains("cnn.com")
    }

    /// Returns a preferred CNN article root for `preferRules` mode.
    ///
    /// Source: CNN fixture listed in the type-level documentation.
    func preferredContentRoot(in doc: Document) throws -> Element? {
        let selectors = [
            "article[data-component-name=article]",
            ".article__main article",
            "main .article__content article",
            "main article.article",
            ".article__content",
        ]

        for selector in selectors {
            if let element = try doc.select(selector).first() {
                return element
            }
        }

        return nil
    }

    /// Applies CNN-specific candidate score hints.
    ///
    /// Source: CNN fixture listed in the type-level documentation.
    func candidateScoreAdjustments(in doc: Document) throws -> [DomainCandidateAdjustment] {
        let signals: [(selector: String, delta: Double)] = [
            ("article[data-component-name=article]", 240),
            (".article__main", 110),
            (".article__content", 100),
            ("[data-component-name=headline]", 45),
            ("[data-component-name=byline]", 25),
            ("[data-component-name=paragraph]", 45),
            ("[data-component-name=subheader]", 25),
            ("#pageHeader", -120),
            (".header__wrapper-outer", -120),
            ("nav", -70),
            (".ad-slot", -120),
            ("[data-desktop-slot-id]", -120),
            ("footer", -90),
        ]

        var out: [DomainCandidateAdjustment] = []
        out.reserveCapacity(48)

        for signal in signals {
            for element in try doc.select(signal.selector).array() {
                out.append(.init(element: element, scoreDelta: signal.delta))
            }
        }

        return out
    }

    /// Returns CNN-specific metadata overrides.
    ///
    /// Source: CNN fixture listed in the type-level documentation.
    func metadataOverrides(in doc: Document, fallbackURL: URL) throws -> DomainMetadataOverride {
        let byline =
            try doc.select("[data-component-name=byline]").first?.text()
                .trimmingCharacters(in: .whitespacesAndNewlines)
            ?? doc.select("meta[name=author]").first()?.attr("content")
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
