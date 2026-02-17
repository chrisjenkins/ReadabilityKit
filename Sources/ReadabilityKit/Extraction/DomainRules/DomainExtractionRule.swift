//
//  DomainExtractionRule.swift
//  ReadabilityKit
//
//  Created by Chris Jenkins on 17/02/2026.
//

import Foundation
import SwiftSoup

/// Score delta to apply to a specific DOM element during candidate ranking.
///
/// Domain rules return arrays of this type from ``DomainExtractionRule/candidateScoreAdjustments(in:)``
/// to bias the generic scorer toward known content blocks and away from known chrome.
struct DomainCandidateAdjustment {
    /// Element whose candidate score should be adjusted.
    let element: Element
    /// Positive values boost candidate priority; negative values reduce it.
    let scoreDelta: Double
}

/// Optional metadata values supplied by a domain-specific rule.
///
/// Any non-`nil` fields are used as higher-priority overrides during article assembly.
struct DomainMetadataOverride: Sendable {
    /// Domain-specific title override.
    let title: String?
    /// Domain-specific byline override.
    let byline: String?
    /// Domain-specific excerpt override.
    let excerpt: String?
    /// Domain-specific lead image override.
    let leadImageURL: URL?

    /// Empty metadata override used as a merge baseline.
    static let empty = DomainMetadataOverride(
        title: nil,
        byline: nil,
        excerpt: nil,
        leadImageURL: nil
    )
}

/// Contract for site-specific extraction rules.
///
/// The extractor evaluates matching rules in three stages:
/// 1. Host match via ``matches(url:)``.
/// 2. Optional content-root selection via ``preferredContentRoot(in:)`` when rule mode is `preferRules`.
/// 3. Optional score and metadata overrides via ``candidateScoreAdjustments(in:)`` and
///    ``metadataOverrides(in:fallbackURL:)``.
///
/// Implementers should prefer stable selectors and conservative score deltas so behavior
/// degrades gracefully when site markup changes.
protocol DomainExtractionRule: Sendable {
    /// Stable identifier for logging/debugging.
    var id: String { get }

    /// Returns `true` when this rule should be considered for the provided URL.
    /// - Parameter url: Source page URL.
    func matches(url: URL) -> Bool

    /// Returns a preferred content root when the site has a reliable article container.
    ///
    /// This is only used when extraction is configured with `DomainRuleMode.preferRules`.
    /// - Parameter doc: Parsed source document.
    func preferredContentRoot(in doc: Document) throws -> Element?

    /// Returns candidate score deltas for known content/chrome blocks on a domain.
    /// - Parameter doc: Parsed source document.
    func candidateScoreAdjustments(in doc: Document) throws -> [DomainCandidateAdjustment]

    /// Returns optional metadata overrides derived from domain-specific signals.
    /// - Parameters:
    ///   - doc: Parsed source document.
    ///   - fallbackURL: Canonical URL used for relative URL resolution.
    func metadataOverrides(in doc: Document, fallbackURL: URL) throws -> DomainMetadataOverride
}

extension DomainExtractionRule {
    /// Default implementation that provides no preferred root.
    func preferredContentRoot(in _: Document) throws -> Element? {
        nil
    }

    /// Default implementation that provides no candidate score overrides.
    func candidateScoreAdjustments(in _: Document) throws -> [DomainCandidateAdjustment] {
        []
    }

    /// Default implementation that provides no metadata overrides.
    func metadataOverrides(in _: Document, fallbackURL _: URL) throws -> DomainMetadataOverride {
        .empty
    }
}
