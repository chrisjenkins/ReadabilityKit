//
//  DomainRuleRegistry.swift
//  ReadabilityKit
//
//  Created by Chris Jenkins on 17/02/2026.
//

import Foundation

/// Registry of available domain-specific extraction rules.
///
/// The extractor queries this registry for URL-matching rules before candidate selection.
/// Matching rules can provide:
/// - a preferred content root (`preferRules` mode),
/// - candidate score hints (`rulesAsHints` mode),
/// - metadata overrides.
struct DomainRuleRegistry: Sendable {
    /// Built-in rule set used by ``ReadabilityExtractor``.
    static let `default` = DomainRuleRegistry(
        rules: [
            BBCDomainExtractionRule(),
            CNNDomainExtractionRule(),
            GuardianDomainExtractionRule(),
        ]
    )

    /// Ordered rules; earlier rules win for preferred-root selection.
    let rules: [any DomainExtractionRule]

    /// Returns all rules that match the provided source URL.
    /// - Parameter url: Source article URL.
    func matchingRules(for url: URL) -> [any DomainExtractionRule] {
        rules.filter { $0.matches(url: url) }
    }
}
