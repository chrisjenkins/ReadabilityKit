//
//  DecorativeImageCleaningPass.swift
//  ReadabilityKit
//
//  Created by Chris Jenkins on 15/03/2026.
//

import Foundation
import SwiftSoup

/// Removes images that are likely decorative while preserving article media with captions or strong content signals.
struct DecorativeImageCleaningPass: ElementCleaningPass {
    func apply(to target: Element, options: ExtractionOptions) throws {
        guard options.removeDecorativeImages else { return }

        let images = try target.select("img").array()
        guard !images.isEmpty else { return }

        let repeatedSourceCounts = try repeatedImageCounts(images: images)

        for image in images {
            let score = try decorativeScore(
                for: image,
                repeatedSourceCounts: repeatedSourceCounts
            )

            if score >= options.decorativeImageRemovalThreshold {
                try image.remove()
            }
        }
    }

    private func repeatedImageCounts(images: [Element]) throws -> [String: Int] {
        var counts: [String: Int] = [:]
        for image in images {
            guard let source = try normalizedImageSource(for: image) else { continue }
            counts[source, default: 0] += 1
        }
        return counts
    }

    private func decorativeScore(
        for image: Element,
        repeatedSourceCounts: [String: Int]
    ) throws -> Int {
        let dimensions = try imageDimensions(for: image)
        let source = try normalizedImageSource(for: image)
        let altText = try image.attr("alt").trimmingCharacters(in: .whitespacesAndNewlines)
        let role = try image.attr("role").lowercased()
        let classNames = (try? image.className()) ?? ""
        let elementID = image.id()
        let style = try image.attr("style").lowercased()
        let sourceText = source ?? ""
        let haystack = [altText, classNames, elementID, sourceText].joined(separator: " ").lowercased()

        var score = 0

        if let dimensions {
            score += sizePenalty(for: dimensions)
            score += dividerPenalty(for: dimensions)
            score += informationBonus(for: dimensions)
            score += tinyStandaloneIconPenalty(for: image, dimensions: dimensions, haystack: haystack)
        }

        if isObviousSpacerOrDivider(dimensions: dimensions, haystack: haystack, altText: altText) {
            score += 45
        }

        if let source, let repeatCount = repeatedSourceCounts[source] {
            if repeatCount >= 5 {
                score += 35
            } else if repeatCount >= 3 {
                score += 25
            }
        }

        if try isBulletLikeRepeatedListImage(image, source: source, repeatedSourceCounts: repeatedSourceCounts) {
            score += 20
        }

        if try isInsideInteractiveOrNavigationalContext(image) {
            score += 30
        }

        if try hasDecorativeAncestorKeywords(image) {
            score += 25
        }

        if containsDecorativeKeywords(haystack) {
            score += 22
        }

        if altText.isEmpty {
            score += 10
        }

        if role == "presentation" || role == "none" {
            score += 30
        }

        if try image.attr("aria-hidden").lowercased() == "true" {
            score += 30
        }

        if style.contains("display:none") || style.contains("visibility:hidden") {
            score += 40
        }

        if try hasFigureCaption(image) {
            score -= 60
        } else if try isInsideFigure(image) {
            score -= 18
        }

        if try hasNearbyCaption(image) {
            score -= 35
        }

        if altText.count >= 20 {
            score -= 15
        }

        if try isOnlyImageInTextHeavyContainer(image) {
            score -= 15
        }

        return score
    }

    private func sizePenalty(for dimensions: ImageDimensions) -> Int {
        let width = dimensions.width
        let height = dimensions.height
        let maxSide = max(width, height)
        let minSide = min(width, height)
        let area = width * height

        if width == 1 && height == 1 { return 100 }
        if maxSide <= 16 { return 45 }
        if maxSide <= 32 && abs(width - height) <= 8 { return 35 }
        if maxSide <= 48 && abs(width - height) <= 12 { return 25 }
        if minSide <= 24 && area <= 2_500 { return 18 }
        return 0
    }

    private func dividerPenalty(for dimensions: ImageDimensions) -> Int {
        let width = dimensions.width
        let height = dimensions.height
        let minSide = max(1, min(width, height))
        let maxSide = max(width, height)
        let ratio = Double(maxSide) / Double(minSide)

        if minSide <= 6 && maxSide >= 80 { return 40 }
        if minSide <= 12 && ratio >= 8.0 { return 28 }
        return 0
    }

    private func informationBonus(for dimensions: ImageDimensions) -> Int {
        let area = dimensions.width * dimensions.height
        if area >= 150_000 { return -35 }
        if area >= 40_000 { return -20 }
        return 0
    }

    private func tinyStandaloneIconPenalty(
        for image: Element,
        dimensions: ImageDimensions,
        haystack: String
    ) -> Int {
        let maxSide = max(dimensions.width, dimensions.height)
        guard maxSide <= 24 else { return 0 }

        var penalty = 0
        if containsDecorativeKeywords(haystack) {
            penalty += 20
        }

        if let parent = image.parent() {
            let tag = parent.tagName().lowercased()
            if ["article", "div", "section", "p"].contains(tag) {
                penalty += 10
            }
        }

        return penalty
    }

    private func imageDimensions(for image: Element) throws -> ImageDimensions? {
        let width = firstPositiveInt(
            Int(try image.attr("width")),
            extractPixelValue(named: "width", from: try image.attr("style")),
            extractPixelValue(named: "max-width", from: try image.attr("style"))
        )
        let height = firstPositiveInt(
            Int(try image.attr("height")),
            extractPixelValue(named: "height", from: try image.attr("style")),
            extractPixelValue(named: "max-height", from: try image.attr("style"))
        )

        guard let width, let height else { return nil }
        return ImageDimensions(width: width, height: height)
    }

    private func firstPositiveInt(_ values: Int?...) -> Int? {
        for value in values {
            if let value, value > 0 {
                return value
            }
        }
        return nil
    }

    private func extractPixelValue(named property: String, from style: String) -> Int? {
        let lowercasedStyle = style.lowercased()
        let pattern = "\(NSRegularExpression.escapedPattern(for: property))\\s*:\\s*(\\d+)px"
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return nil }
        let range = NSRange(lowercasedStyle.startIndex..<lowercasedStyle.endIndex, in: lowercasedStyle)
        guard
            let match = regex.firstMatch(in: lowercasedStyle, range: range),
            let valueRange = Range(match.range(at: 1), in: lowercasedStyle)
        else {
            return nil
        }

        return Int(lowercasedStyle[valueRange])
    }

    private func normalizedImageSource(for image: Element) throws -> String? {
        let candidates = [
            try image.attr("src"),
            try image.attr("data-src"),
            try image.attr("data-original"),
            try image.attr("data-lazy-src"),
            try image.attr("data-url"),
        ]

        let srcset = try image.attr("srcset")
        let raw = candidates.first(where: { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty })
            ?? parseFirstSrcsetURL(srcset)
        guard let raw else { return nil }

        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        if let components = URLComponents(string: trimmed) {
            var normalized = components
            normalized.query = nil
            normalized.fragment = nil
            return normalized.string?.lowercased() ?? trimmed.lowercased()
        }

        return trimmed.lowercased()
    }

    private func parseFirstSrcsetURL(_ srcset: String) -> String? {
        let firstCandidate = srcset.split(separator: ",").first?.trimmingCharacters(in: .whitespacesAndNewlines)
        return firstCandidate?.split(separator: " ").first.map(String.init)
    }

    private func isBulletLikeRepeatedListImage(
        _ image: Element,
        source: String?,
        repeatedSourceCounts: [String: Int]
    ) throws -> Bool {
        guard let parent = image.parent(), parent.tagName().lowercased() == "li" else { return false }
        guard let source, (repeatedSourceCounts[source] ?? 0) >= 3 else { return false }

        let children = parent.children().array()
        guard let index = children.firstIndex(where: { $0 === image }), index <= 1 else { return false }

        let dimensions = try imageDimensions(for: image)
        if let dimensions, max(dimensions.width, dimensions.height) <= 48 {
            return true
        }

        return containsDecorativeKeywords(source)
    }

    private func isInsideInteractiveOrNavigationalContext(_ image: Element) throws -> Bool {
        var current = image.parent()

        while let element = current {
            let tag = element.tagName().lowercased()
            if ["a", "button", "nav"].contains(tag) { return true }

            let haystack = [
                (try? element.className()) ?? "",
                element.id(),
                try element.attr("role"),
            ].joined(separator: " ").lowercased()

            if containsContextKeywords(haystack) {
                return true
            }

            current = element.parent()
        }

        return false
    }

    private func hasDecorativeAncestorKeywords(_ image: Element) throws -> Bool {
        var current = image.parent()

        while let element = current {
            let haystack = [
                (try? element.className()) ?? "",
                element.id(),
            ].joined(separator: " ").lowercased()

            if containsDecorativeContainerKeywords(haystack) {
                return true
            }

            current = element.parent()
        }

        return false
    }

    private func hasFigureCaption(_ image: Element) throws -> Bool {
        guard let figure = try nearestAncestor(named: "figure", from: image) else { return false }
        return try figure.select("figcaption").first() != nil
    }

    private func isInsideFigure(_ image: Element) throws -> Bool {
        try nearestAncestor(named: "figure", from: image) != nil
    }

    private func hasNearbyCaption(_ image: Element) throws -> Bool {
        if let figure = try nearestAncestor(named: "figure", from: image),
           try containsCaptionLikeText(in: figure, excluding: image, allowDescendantCaptions: true) {
            return true
        }

        if let parent = image.parent(),
           try containsCaptionLikeText(in: parent, excluding: image, allowDescendantCaptions: false) {
            return true
        }

        if let grandparent = image.parent()?.parent(),
           grandparent.tagName().lowercased() != "article",
           grandparent.tagName().lowercased() != "body",
           try containsCaptionLikeText(in: grandparent, excluding: image, allowDescendantCaptions: false) {
            return true
        }

        return false
    }

    private func containsCaptionLikeText(
        in container: Element,
        excluding image: Element,
        allowDescendantCaptions: Bool
    ) throws -> Bool {
        if allowDescendantCaptions,
           let figcaption = try container.select("figcaption").first(),
           try figcaption.text().trimmingCharacters(in: .whitespacesAndNewlines).count >= 12 {
            return true
        }

        let elements = try container.children().select("[class*=caption], [class*=credit], [class*=legend], [id*=caption], [id*=credit]").array()
        for element in elements where element !== image {
            if try element.text().trimmingCharacters(in: .whitespacesAndNewlines).count >= 12 {
                return true
            }
        }

        for sibling in try siblingElements(of: image) {
            let text = try sibling.text().trimmingCharacters(in: .whitespacesAndNewlines)
            let haystack = [
                sibling.tagName().lowercased(),
                (try? sibling.className()) ?? "",
                sibling.id(),
            ].joined(separator: " ").lowercased()

            if text.count >= 12 && containsCaptionKeywords(haystack) {
                return true
            }
        }

        return false
    }

    private func siblingElements(of image: Element) throws -> [Element] {
        guard let parent = image.parent() else { return [] }
        return parent.children().array().filter { $0 !== image }
    }

    private func isOnlyImageInTextHeavyContainer(_ image: Element) throws -> Bool {
        guard let parent = image.parent() else { return false }
        let siblingImageCount = try parent.select("img").size()
        let textCount = try parent.text().trimmingCharacters(in: .whitespacesAndNewlines).count
        return siblingImageCount == 1 && textCount >= 80
    }

    private func nearestAncestor(named tagName: String, from element: Element) throws -> Element? {
        var current = element.parent()
        while let node = current {
            if node.tagName().lowercased() == tagName {
                return node
            }
            current = node.parent()
        }
        return nil
    }

    private func containsDecorativeKeywords(_ text: String) -> Bool {
        let keywords = [
            "icon", "logo", "sprite", "bullet", "share", "social", "nav", "menu",
            "divider", "separator", "rule", "spacer", "pixel", "tracking", "chevron",
            "arrow", "button", "badge", "emoji", "avatar",
        ]
        return keywords.contains(where: { text.contains($0) })
    }

    private func isObviousSpacerOrDivider(
        dimensions: ImageDimensions?,
        haystack: String,
        altText: String
    ) -> Bool {
        if let dimensions {
            let minSide = min(dimensions.width, dimensions.height)
            let maxSide = max(dimensions.width, dimensions.height)
            if dimensions.width == 1 && dimensions.height == 1 {
                return true
            }
            if minSide <= 8 && maxSide >= 80 && altText.isEmpty {
                return true
            }
        }

        return altText.isEmpty && ["spacer", "divider", "separator", "rule", "pixel"].contains(where: { haystack.contains($0) })
    }

    private func containsContextKeywords(_ text: String) -> Bool {
        let keywords = [
            "share", "social", "nav", "menu", "breadcrumb", "pagination",
            "toolbar", "reaction", "actions", "button",
        ]
        return keywords.contains(where: { text.contains($0) })
    }

    private func containsDecorativeContainerKeywords(_ text: String) -> Bool {
        let keywords = [
            "share", "social", "nav", "menu", "related", "promo",
            "sidebar", "breadcrumb", "pagination", "toolbar",
        ]
        return keywords.contains(where: { text.contains($0) })
    }

    private func containsCaptionKeywords(_ text: String) -> Bool {
        let keywords = ["caption", "credit", "legend", "photo", "image", "media"]
        return keywords.contains(where: { text.contains($0) })
    }
}

private struct ImageDimensions {
    let width: Int
    let height: Int
}
