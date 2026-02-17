//
//  GuardianDomainExtractionRule.swift
//  ReadabilityKit
//
//  Created by Chris Jenkins on 17/02/2026.
//

import Foundation
import SwiftSoup

/// Domain-specific extraction rule for The Guardian pages.
///
/// ## Selector Sources
/// The selectors in this rule are based on the checked-in Guardian fixture:
/// `/Users/chrisjenkins/Developer/ReadabilityKit/Tests/ReadabilityKitTests/Resources/theguardian.html`
///
/// URL scope reference used for rule matching:
/// `https://www.theguardian.com/science/2026/feb/16/psychedelic-drug-dmt-treat-depression-trial-shows`
///
/// Selectors present in the fixture and used by this rule:
/// - `#maincontent article`
/// - `div[data-gu-name=body]`
/// - `div[data-gu-name=headline]`
/// - `div[data-gu-name=standfirst]`
/// - `div[data-gu-name=byline]`
/// - `[data-component=header]`
/// - `[data-component=sub-nav]`
/// - `[data-component=footer]`
///
/// Note: This rule is designed as heuristic support and intentionally includes fallback selectors
/// because publisher markup can change over time.
struct GuardianDomainExtractionRule: DomainExtractionRule {
    let id = "guardian"

    func matches(url: URL) -> Bool {
        guard let host = url.host?.lowercased() else { return false }
        return host.contains("theguardian.com")
    }

    /// Returns a preferred Guardian article root for `preferRules` mode.
    ///
    /// Source: Guardian fixture listed in the type-level documentation.
    func preferredContentRoot(in doc: Document) throws -> Element? {
        let selectors = [
            "#maincontent article",
            "main#maincontent article",
            "article",
            "div[data-gu-name=body]",
        ]

        for selector in selectors {
            if let element = try doc.select(selector).first() {
                return element
            }
        }

        return nil
    }

    /// Applies Guardian-specific candidate score hints.
    ///
    /// Source: Guardian fixture listed in the type-level documentation.
    func candidateScoreAdjustments(in doc: Document) throws -> [DomainCandidateAdjustment] {
        let signals: [(selector: String, delta: Double)] = [
            ("#maincontent article", 240),
            ("article", 200),
            ("[data-gu-name=body]", 120),
            ("[data-gu-name=headline]", 45),
            ("[data-gu-name=standfirst]", 35),
            ("[data-gu-name=byline]", 20),
            ("[data-component=header]", -120),
            ("[data-component=sub-nav]", -90),
            ("[data-component=footer]", -130),
            ("aside[data-ad-slot=true]", -140),
            (".ad-slot", -120),
            ("nav", -50),
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

    /// Returns Guardian-specific metadata overrides.
    ///
    /// Source: Guardian fixture listed in the type-level documentation.
    func metadataOverrides(in doc: Document, fallbackURL: URL) throws -> DomainMetadataOverride {
        let title =
            try doc.select("[data-gu-name=headline]").first()?.text()
                .trimmingCharacters(in: .whitespacesAndNewlines)

        let byline =
            try doc.select("[data-gu-name=byline]").first()?.text()
                .trimmingCharacters(in: .whitespacesAndNewlines)
            ?? doc.select("meta[name=twitter:creator]").first()?.attr("content")
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .replacingOccurrences(of: "@", with: "")

        let excerpt =
            try doc.select("meta[property=og:description]").first()?.attr("content")
                .trimmingCharacters(in: .whitespacesAndNewlines)
            ?? doc.select("meta[name=description]").first()?.attr("content")
                .trimmingCharacters(in: .whitespacesAndNewlines)
            ?? doc.select("[data-gu-name=standfirst]").first?.text()
                .trimmingCharacters(in: .whitespacesAndNewlines)

        let leadImageRaw =
            try doc.select("meta[property=og:image]").first()?.attr("content")
                .trimmingCharacters(in: .whitespacesAndNewlines)

        return DomainMetadataOverride(
            title: (title?.isEmpty == true) ? nil : title,
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
