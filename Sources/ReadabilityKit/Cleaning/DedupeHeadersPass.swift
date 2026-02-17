//
//  DedupeHeadersPass.swift
//  ReadabilityKit
//
//  Created by Chris Jenkins on 17/02/2026.
//

import Foundation
import SwiftSoup

/// Removes title-duplicate and preamble header nodes that commonly survive content extraction.
struct DedupeHeadersPass {
    private let preambleNoiseTokens: Set<String> = [
        "advertisement", "advertiser", "ad", "sponsored", "live", "updates", "update", "by", "author",
        "published", "posted", "updated", "minutes", "minute", "hours", "hour", "ago", "read",
    ]

    func apply(
        to contentRoot: Element,
        resolvedTitle: String,
        options: ExtractionOptions
    ) throws {
        guard options.dedupeTitleHeaders || options.dropPreambleHeadersBeforeFirstParagraph else {
            return
        }

        let normalizedTitle = normalizeForComparison(resolvedTitle)
        let titleTokens = tokenize(normalizedTitle)
        let firstParagraph = try contentRoot.select("p").first()
        let orderIndexByPath = try makeOrderIndexMap(contentRoot: contentRoot)
        let firstParagraphOrder = firstParagraph.map { orderIndexByPath[domPath(for: $0)] ?? Int.max } ?? Int.max

        for header in try contentRoot.select("h1, h2, h3").array() {
            let normalizedHeader = normalizeForComparison(try header.text())
            if normalizedHeader.isEmpty {
                try header.remove()
                continue
            }

            if options.dedupeTitleHeaders && shouldRemoveAsTitleDuplicate(
                normalizedHeader: normalizedHeader,
                normalizedTitle: normalizedTitle,
                titleTokens: titleTokens
            ) {
                try header.remove()
                continue
            }

            if options.dropPreambleHeadersBeforeFirstParagraph {
                let shouldRemovePreamble = try shouldRemoveAsPreambleHeader(
                    header: header,
                    normalizedHeader: normalizedHeader,
                    firstParagraphOrder: firstParagraphOrder,
                    orderIndexByPath: orderIndexByPath
                )
                if shouldRemovePreamble {
                    try header.remove()
                }
            }
        }
    }

    private func shouldRemoveAsTitleDuplicate(
        normalizedHeader: String,
        normalizedTitle: String,
        titleTokens: Set<String>
    ) -> Bool {
        guard !normalizedTitle.isEmpty else { return false }

        if normalizedHeader == normalizedTitle { return true }
        if normalizedHeader.contains(normalizedTitle) || normalizedTitle.contains(normalizedHeader) {
            return normalizedHeader.count >= 24 || normalizedTitle.count >= 24
        }

        let headerTokens = tokenize(normalizedHeader)
        guard !headerTokens.isEmpty else { return false }
        let overlap = tokenJaccard(headerTokens, titleTokens)
        return overlap >= 0.85
    }

    private func shouldRemoveAsPreambleHeader(
        header: Element,
        normalizedHeader: String,
        firstParagraphOrder: Int,
        orderIndexByPath: [String: Int]
    ) throws -> Bool {
        guard firstParagraphOrder != Int.max else { return false }
        let headerOrder = orderIndexByPath[domPath(for: header)] ?? Int.max
        guard headerOrder < firstParagraphOrder else { return false }

        let textLength = normalizedHeader.count
        if textLength <= 2 { return true }
        if textLength > 64 { return false }

        let tokenSet = tokenize(normalizedHeader)
        let noiseHits = tokenSet.intersection(preambleNoiseTokens).count
        if noiseHits >= max(1, tokenSet.count / 2) {
            return true
        }

        if normalizedHeader.range(of: #"\b(updated|published|posted)\b.*\b(ago|am|pm)\b"#, options: .regularExpression) != nil {
            return true
        }

        if normalizedHeader.range(of: #"^\s*by\s+[a-z0-9]"#, options: .regularExpression) != nil {
            return true
        }

        return false
    }

    private func makeOrderIndexMap(contentRoot: Element) throws -> [String: Int] {
        let all = try contentRoot.select("*").array()
        var out: [String: Int] = [:]
        out.reserveCapacity(all.count)
        for (index, element) in all.enumerated() {
            let path = domPath(for: element)
            if out[path] == nil {
                out[path] = index
            }
        }
        return out
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

    private func normalizeForComparison(_ text: String) -> String {
        text
            .lowercased()
            .replacingOccurrences(
                of: #"[^\p{L}\p{N}\s]+"#,
                with: " ",
                options: .regularExpression
            )
            .replacingOccurrences(
                of: #"\s+"#,
                with: " ",
                options: .regularExpression
            )
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func tokenize(_ text: String) -> Set<String> {
        Set(text.split(separator: " ").map(String.init).filter { $0.count >= 2 })
    }

    private func tokenJaccard(_ lhs: Set<String>, _ rhs: Set<String>) -> Double {
        if lhs.isEmpty && rhs.isEmpty { return 1 }
        if lhs.isEmpty || rhs.isEmpty { return 0 }
        let intersection = lhs.intersection(rhs).count
        let union = lhs.union(rhs).count
        return Double(intersection) / Double(union)
    }
}
