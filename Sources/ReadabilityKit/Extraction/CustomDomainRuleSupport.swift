//
//  CustomDomainRuleSupport.swift
//  ReadabilityKit
//
//  Helpers shared by auto-generated custom domain rules.
//

import Foundation
import SwiftSoup

enum CustomDomainRuleSupport {
    static func matches(url: URL, domain: String) -> Bool {
        guard let host = url.host?.lowercased() else { return false }
        let normalizedHost = host.hasPrefix("www.") ? String(host.dropFirst(4)) : host
        let normalizedDomain = domain.lowercased().hasPrefix("www.")
            ? String(domain.lowercased().dropFirst(4))
            : domain.lowercased()
        return normalizedHost == normalizedDomain || normalizedHost.hasSuffix("." + normalizedDomain)
    }

    static func firstMatchingElement(in doc: Document, selectors: [String]) throws -> Element? {
        for selector in selectors where !selector.isEmpty {
            if let match = try doc.select(selector).first() {
                return match
            }
        }
        return nil
    }

    static func candidateScoreAdjustments(
        in doc: Document,
        positiveSignals: [(selector: String, delta: Double)],
        negativeSignals: [(selector: String, delta: Double)],
    ) throws -> [DomainCandidateAdjustment] {
        var adjustments: [DomainCandidateAdjustment] = []
        adjustments.reserveCapacity(64)

        for signal in positiveSignals {
            for element in try doc.select(signal.selector).array() {
                adjustments.append(.init(element: element, scoreDelta: signal.delta))
            }
        }

        for signal in negativeSignals {
            for element in try doc.select(signal.selector).array() {
                adjustments.append(.init(element: element, scoreDelta: signal.delta))
            }
        }

        return adjustments
    }

    static func metadataOverrides(
        in doc: Document,
        fallbackURL: URL,
        titleSelectors: [String],
        authorSelectors: [String],
        excerptSelectors: [String],
        leadImageSelectors: [String],
    ) throws -> DomainMetadataOverride {
        let title = try firstStringValue(in: doc, selectors: titleSelectors)
        let byline = try firstStringValue(in: doc, selectors: authorSelectors)
        let excerpt = try firstStringValue(in: doc, selectors: excerptSelectors)
        let leadImage = try firstURLValue(in: doc, selectors: leadImageSelectors, fallbackURL: fallbackURL)

        return DomainMetadataOverride(
            title: title,
            byline: byline,
            excerpt: excerpt,
            leadImageURL: leadImage,
        )
    }

    private static func firstStringValue(in doc: Document, selectors: [String]) throws -> String? {
        for selector in selectors where !selector.isEmpty {
            guard let element = try doc.select(selector).first() else { continue }
            let content = (try? element.attr("content"))?.trimmingCharacters(in: .whitespacesAndNewlines)
            let value = (try? element.attr("value"))?.trimmingCharacters(in: .whitespacesAndNewlines)
            let text = (try? element.text())?.trimmingCharacters(in: .whitespacesAndNewlines)
            let candidate = content?.nilIfEmpty ?? value?.nilIfEmpty ?? text?.nilIfEmpty
            if let candidate {
                return candidate
            }
        }
        return nil
    }

    private static func firstURLValue(in doc: Document, selectors: [String], fallbackURL: URL) throws -> URL? {
        for selector in selectors where !selector.isEmpty {
            guard let element = try doc.select(selector).first() else { continue }
            let content = (try? element.attr("content"))?.trimmingCharacters(in: .whitespacesAndNewlines)
            let src = (try? element.attr("src"))?.trimmingCharacters(in: .whitespacesAndNewlines)
            let href = (try? element.attr("href"))?.trimmingCharacters(in: .whitespacesAndNewlines)
            let value = (try? element.attr("value"))?.trimmingCharacters(in: .whitespacesAndNewlines)
            let raw = content?.nilIfEmpty ?? src?.nilIfEmpty ?? href?.nilIfEmpty ?? value?.nilIfEmpty
            guard let raw else { continue }
            if let absolute = URL(string: raw), absolute.scheme != nil {
                return absolute
            }
            if let relative = URL(string: raw, relativeTo: fallbackURL)?.absoluteURL {
                return relative
            }
        }
        return nil
    }
}

private extension String {
    var nilIfEmpty: String? {
        isEmpty ? nil : self
    }
}
