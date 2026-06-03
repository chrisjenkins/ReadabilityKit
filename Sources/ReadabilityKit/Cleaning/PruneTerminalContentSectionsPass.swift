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
    private let hardTerminalBoundarySelector = [
        "p.article-copyright",
        ".social",
        ".footer__meta",
        ".extended-scroll",
        ".network-footer",
    ].joined(separator: ", ")
    private let terminalClassTokens = [
        "footer",
        "social",
        "share",
        "comment",
        "related",
        "recommend",
        "popular",
        "newsletter",
        "sidebar",
        "widget",
        "promo",
        "taboola",
        "outbrain",
        "most-popular",
        "extended-scroll",
    ]
    private let terminalTextPhrases = [
        "all rights reserved",
        "may not be published, broadcast, rewritten, or redistributed",
        "privacy policy",
        "terms & conditions",
        "terms of use",
        "follow us on",
        "get the app",
        "sign up for our daily email",
        "more news",
        "more stories",
        "top stories",
        "most popular",
        "recommended stories",
        "related stories",
        "continue reading",
    ]

    func apply(to target: Element, options _: ExtractionOptions) throws {
        try truncateAtHardTerminalBoundary(in: target)
        try truncateAtGenericTerminalBoundary(in: target)
        try removeHardTerminalMatches(in: target)

        let candidates = try target.select("section, div, aside").array()
        for element in candidates.reversed() {
            if try shouldRemove(element) {
                try element.remove()
            }
        }
    }

    private func truncateAtHardTerminalBoundary(in target: Element) throws {
        guard let boundary = try target.select(hardTerminalBoundarySelector).first() else {
            return
        }

        if boundary.tagName().lowercased() == "p",
           ((try? boundary.className()) ?? "").lowercased().split(separator: " ").contains("article-copyright")
        {
            guard let parent = boundary.parent() else {
                try boundary.remove()
                return
            }
            try removeNodeAndFollowingSiblings(startingAt: boundary, within: parent)
            return
        }

        let truncationRoot = truncationContainer(for: boundary, within: target) ?? boundary
        guard let parent = truncationRoot.parent() else {
            try truncationRoot.remove()
            return
        }
        try removeNodeAndFollowingSiblings(startingAt: truncationRoot, within: parent)
    }

    private func removeHardTerminalMatches(in target: Element) throws {
        let matches = try target.select(hardTerminalBoundarySelector).array()
        for match in matches.reversed() {
            guard !containsMeaningfulProse(match) else { continue }
            try match.remove()
        }
    }

    private func truncateAtGenericTerminalBoundary(in target: Element) throws {
        let containers = [target] + (try target.select("article, main, section, div").array())
        for container in containers {
            guard try truncateGenericBoundaryInChildren(of: container) else { continue }
            return
        }
    }

    private func truncateGenericBoundaryInChildren(of container: Element) throws -> Bool {
        var encounteredProse = false

        for child in container.children().array() {
            if isProseBearing(child) {
                encounteredProse = true
                continue
            }

            guard encounteredProse, try isGenericTerminalBoundary(child) else { continue }
            try removeNodeAndFollowingSiblings(startingAt: child, within: container)
            return true
        }

        return false
    }

    private func truncationContainer(for boundary: Element, within target: Element) -> Element? {
        var current: Element? = boundary
        var candidate: Element?

        while let node = current, node !== target {
            candidate = node
            current = node.parent()
        }

        return candidate
    }

    private func removeNodeAndFollowingSiblings(startingAt node: Element, within parent: Element) throws {
        var shouldRemove = false
        for sibling in parent.children().array() {
            if sibling === node {
                shouldRemove = true
            }
            if shouldRemove {
                try sibling.remove()
            }
        }
    }

    private func isProseBearing(_ element: Element) -> Bool {
        if containsMeaningfulProse(element) {
            return true
        }

        let tag = element.tagName().lowercased()
        guard ["p", "blockquote", "pre"].contains(tag) else {
            return false
        }

        let text = ((try? element.text()) ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        return text.count >= 40
    }

    private func containsMeaningfulProse(_ element: Element) -> Bool {
        let proseTags = "p, pre, blockquote"
        guard let proseNodes = try? element.select(proseTags).array(), !proseNodes.isEmpty else {
            return false
        }

        return proseNodes.contains { node in
            let text = ((try? node.text()) ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
            return text.count >= 80
        }
    }

    private func isGenericTerminalBoundary(_ element: Element) throws -> Bool {
        if isExplicitCopyrightBoundary(element) {
            return true
        }

        let normalizedText = normalize(try element.text())
        let idClass = normalize(element.id() + " " + ((try? element.className()) ?? ""))
        let tag = element.tagName().lowercased()
        let hasTerminalToken = terminalClassTokens.contains(where: { idClass.contains($0) })
        let hasTerminalText = terminalTextPhrases.contains(where: { normalizedText.contains($0) })
        let hasFormControls = try element.select("form, input, button").count > 0
        let looksLikeCards = try looksLikeLinkHeavyCards(element)
        let looksLikeAccessory = looksLikeAccessoryModule(element)
        let negativeHeading = hasNegativeHeading(element)

        if ["footer", "nav"].contains(tag) {
            return true
        }

        if hasTerminalToken && (!containsMeaningfulProse(element) || looksLikeCards || hasFormControls) {
            return true
        }

        if hasTerminalText && (!containsMeaningfulProse(element) || looksLikeAccessory || hasFormControls) {
            return true
        }

        if negativeHeading && (looksLikeCards || looksLikeAccessory || hasFormControls) {
            return true
        }

        return false
    }

    private func isExplicitCopyrightBoundary(_ element: Element) -> Bool {
        let classTokens = ((try? element.className()) ?? "")
            .lowercased()
            .split(separator: " ")
        let normalizedText = normalize((try? element.text()) ?? "")

        if element.tagName().lowercased() == "p", classTokens.contains("article-copyright") {
            return true
        }

        return normalizedText.contains("all rights reserved")
            || normalizedText.contains("may not be published, broadcast, rewritten, or redistributed")
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
        if normalizedText.contains("follow us on") { return true }
        if normalizedText.contains("get the app") { return true }
        if normalizedText.contains("privacy policy") { return true }
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
