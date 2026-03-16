//
//  PruneTerminalContentSectionsPass.swift
//  ReadabilityKit
//
//  Created by Codex on 16/03/2026.
//

import Foundation
import SwiftSoup

/// Removes non-article sections that are often appended after the main story,
/// such as recommendation modules, "more stories" rails, and comment blocks.
struct PruneTerminalContentSectionsPass: ElementCleaningPass {
    private let negativeHeadingPhrases = [
        "comments",
        "top comments",
        "top rated comments",
        "related stories",
        "related articles",
        "recommended",
        "recommended stories",
        "more stories",
        "other stories",
        "popular stories",
        "latest stories",
        "next article",
        "more from",
    ]

    func apply(to target: Element, options _: ExtractionOptions) throws {
        let candidates = try target.select("section, div, aside").array()
        for element in candidates.reversed() {
            if try shouldRemove(element) {
                try element.remove()
            }
        }
    }

    private func shouldRemove(_ element: Element) throws -> Bool {
        let idClass = (try element.id() + " " + element.className()).lowercased()

        if idClass.contains("comment"), try looksLikeComments(element) {
            return true
        }

        if idClass.contains("related")
            || idClass.contains("recommend")
            || idClass.contains("popular")
            || idClass.contains("sidebar")
        {
            if try looksLikeLinkHeavyCards(element) || hasNegativeHeading(element) {
                return true
            }
        }

        if hasNegativeHeading(element) {
            let looksLikeComments = try looksLikeComments(element)
            let looksLikeCards = try looksLikeLinkHeavyCards(element)
            if looksLikeComments || looksLikeAccessoryModule(element) || looksLikeCards {
                return true
            }
        }

        return false
    }

    private func hasNegativeHeading(_ element: Element) -> Bool {
        guard let heading = try? element.select("h1, h2, h3, h4, h5, h6").first(),
              let text = try? heading.text()
        else {
            return false
        }

        let normalized = normalize(text)
        return negativeHeadingPhrases.contains(where: { normalized.contains($0) })
    }

    private func looksLikeAccessoryModule(_ element: Element) -> Bool {
        let normalizedText = normalize((try? element.text()) ?? "")
        if normalizedText.contains("read full article") { return true }
        if normalizedText.contains("read all comments") { return true }
        if normalizedText.contains("score:") && normalizedText.contains("votes") { return true }
        return false
    }

    private func looksLikeComments(_ element: Element) throws -> Bool {
        let normalizedText = normalize(try element.text())
        let commentMarkers = [
            "read all comments",
            "reply",
            "score:",
            "votes",
            "like",
            "disagree",
        ]
        let markerHits = commentMarkers.reduce(into: 0) { count, marker in
            if normalizedText.contains(marker) { count += 1 }
        }

        let profileLinks = try element.select("a[href*=\"/comment\"], a[href*=\"/comments\"], a[href*=\"/post-\"]").count
        return markerHits >= 2 || profileLinks >= 2
    }

    private func looksLikeLinkHeavyCards(_ element: Element) throws -> Bool {
        let links = try element.select("a[href]").array()
        guard links.count >= 3 else { return false }

        let paragraphs = try element.select("p").count
        let images = try element.select("img").count
        let childBlocks = element.children().count
        let text = try element.text().trimmingCharacters(in: .whitespacesAndNewlines)
        let linkDensity = text.isEmpty ? 1.0 : min(1.0, Double(links.count * 40) / Double(max(text.count, 1)))

        if linkDensity >= 0.35 { return true }
        if images >= 2 && childBlocks >= 2 { return true }
        if paragraphs <= 2 && childBlocks >= 3 { return true }

        return false
    }

    private func normalize(_ text: String) -> String {
        text
            .lowercased()
            .replacingOccurrences(of: "\u{00A0}", with: " ")
            .components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
            .joined(separator: " ")
    }
}
