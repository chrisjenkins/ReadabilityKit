//
//  NextPageDetector.swift
//  ReadabilityKit
//
//  Created by Chris Jenkins on 17/02/2026.
//

import Foundation
import SwiftSoup

/// Detects likely next-page URLs for paginated article content.
struct NextPageDetector {
    private let negativeContainerTokens: [String] = [
        "comment", "related", "recommend", "promo", "social", "share", "footer", "header", "nav",
    ]
    private let nextLabelPattern = #"\b(next|continue|more|older|page\s*\d+)\b"#
    private let articleSwitchPattern = #"\b(next\s+(article|story|post)|related)\b"#
    private let paginationURLPattern = #"(\/page\/\d+|\bpage=\d+\b|\bp=\d+\b|[?&](pg|paged)=\d+)"#

    func detectNextPageURL(
        in doc: Document,
        contentRoot: Element,
        baseURL: URL,
        options: ExtractionOptions
    ) throws -> URL? {
        let candidates = try collectCandidates(in: doc, contentRoot: contentRoot, baseURL: baseURL, options: options)
        guard let best = candidates.max(by: { $0.score < $1.score }) else { return nil }
        return best.score >= options.minNextPageConfidence ? best.url : nil
    }

    private func collectCandidates(
        in doc: Document,
        contentRoot: Element,
        baseURL: URL,
        options: ExtractionOptions
    ) throws -> [(url: URL, score: Double)] {
        var scored: [String: Double] = [:]
        var canonical: [String: URL] = [:]

        if let relNext = try doc.select("link[rel=next]").first() {
            let href = try relNext.attr("href")
            if let url = URL(string: href, relativeTo: baseURL)?.absoluteURL {
                let key = normalizedURLKey(url)
                scored[key, default: 0] += 0.9
                canonical[key] = url
            }
        }

        for anchor in try doc.select("a[href]").array() {
            let href = try anchor.attr("href")
            guard let url = URL(string: href, relativeTo: baseURL)?.absoluteURL else { continue }
            let key = normalizedURLKey(url)
            var score = 0.0

            let rel = try anchor.attr("rel").lowercased()
            if rel.contains("next") { score += 0.9 }

            let label = try anchor.text().lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
            if label.range(of: nextLabelPattern, options: .regularExpression) != nil {
                score += 0.45
            }
            if label.range(of: articleSwitchPattern, options: .regularExpression) != nil {
                score -= 0.7
            }

            if url.absoluteString.range(of: paginationURLPattern, options: .regularExpression) != nil {
                score += 0.35
            }

            if url.host?.lowercased() != baseURL.host?.lowercased() {
                score -= 0.8
            }
            if normalizedURLKey(baseURL) == key {
                score -= 1.2
            }

            let parent = anchor.parent()
            let idClass = (parent?.id() ?? "") + " " + (try parent?.className() ?? "")
            let context = idClass.lowercased()
            if negativeContainerTokens.contains(where: { context.contains($0) }) {
                score -= 0.45
            }

            let anchorDensity = try linkDensityAroundAnchor(anchor)
            if anchorDensity > 0.8 {
                score -= 0.35
            }

            if try !isWithinDistanceFromContentRoot(
                anchor: anchor,
                contentRoot: contentRoot,
                maxDistance: options.maxPaginationDistanceFromRoot
            ) {
                score -= 0.35
            }

            if score <= 0 { continue }
            scored[key, default: 0] += score
            canonical[key] = url
        }

        return scored.compactMap { key, score in
            guard let url = canonical[key] else { return nil }
            return (url, score)
        }
    }

    private func isWithinDistanceFromContentRoot(
        anchor: Element,
        contentRoot: Element,
        maxDistance: Int
    ) throws -> Bool {
        let rootPath = domPath(for: contentRoot)
        var allowedPaths = Set([rootPath])
        var current = contentRoot.parent()
        var depth = 0
        while let ancestor = current, depth < maxDistance {
            allowedPaths.insert(domPath(for: ancestor))
            depth += 1
            current = ancestor.parent()
        }

        var node: Element? = anchor
        while let candidate = node {
            if allowedPaths.contains(domPath(for: candidate)) {
                return true
            }
            node = candidate.parent()
        }
        return false
    }

    private func linkDensityAroundAnchor(_ anchor: Element) throws -> Double {
        guard let container = anchor.parent() else { return 1.0 }
        let text = try container.text().trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return 1.0 }
        let linkText = try container.select("a").text().count
        return Double(linkText) / Double(max(1, text.count))
    }

    private func normalizedURLKey(_ url: URL) -> String {
        var comps = URLComponents(url: url, resolvingAgainstBaseURL: false)
        comps?.fragment = nil
        return comps?.string?.lowercased() ?? url.absoluteString.lowercased()
    }

    private func domPath(for element: Element) -> String {
        var parts: [String] = []
        var current: Element? = element
        while let node = current {
            let tag = node.tagName().lowercased()
            let index: Int
            if let parent = node.parent() {
                let siblings = parent.children().array().filter { $0.tagName() == node.tagName() }
                index = siblings.firstIndex(where: { $0 === node }) ?? 0
            } else {
                index = 0
            }
            parts.append("\(tag)[\(index)]")
            current = node.parent()
        }
        return parts.reversed().joined(separator: "/")
    }
}
