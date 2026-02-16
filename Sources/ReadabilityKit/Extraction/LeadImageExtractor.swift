//
//  LeadImageExtractor.swift
//  ReadabilityKit
//
//  Created by Chris Jenkins on 16/02/2026.
//

import Foundation
import SwiftSoup

struct LeadImageExtractor {
    func extractLeadImageURL(doc: Document, contentRoot: Element, fallbackURL: URL) throws -> URL? {
        if let meta = try extractLeadImageFromMetadata(doc: doc, fallbackURL: fallbackURL) {
            return meta
        }

        return try extractLeadImageFromContent(contentRoot: contentRoot, fallbackURL: fallbackURL)
    }

    private func extractLeadImageFromMetadata(doc: Document, fallbackURL: URL) throws -> URL? {
        let baseURL = URL(string: doc.getBaseUri()) ?? fallbackURL
        let candidates = try metaImageCandidates(doc: doc)
        for candidate in candidates {
            guard let resolved = resolveImageURL(candidate.url, baseURL: baseURL) else { continue }
            if let size = candidate.size, !passesImageSizeGate(size: size) { continue }
            if isBlockedImageURL(resolved.absoluteString) { continue }
            return resolved
        }
        return nil
    }

    private func extractLeadImageFromContent(contentRoot: Element, fallbackURL: URL) throws -> URL? {
        let baseURL = URL(string: contentRoot.getBaseUri()) ?? fallbackURL
        let images = try contentRoot.select("img").array()
        guard !images.isEmpty else { return nil }

        var best: (url: URL, score: Int, order: Int)?
        for (index, img) in images.enumerated() {
            guard let candidate = try contentImageCandidate(img: img, baseURL: baseURL) else { continue }
            let score = candidate.score + (index < 3 ? 20 : 0)
            if score < 40 { continue }
            if let best, best.score > score { continue }
            if let best, best.score == score, best.order < index { continue }
            best = (candidate.url, score, index)
        }

        return best?.url
    }

    private struct MetaImageCandidate {
        let url: String
        let size: ImageSize?
    }

    private struct ImageSize {
        let width: Int
        let height: Int
    }

    private struct ContentImageCandidate {
        let url: URL
        let score: Int
    }

    private func metaImageCandidates(doc: Document) throws -> [MetaImageCandidate] {
        let width = Int(try doc.select("meta[property=og:image:width]").first()?.attr("content") ?? "")
        let height = Int(try doc.select("meta[property=og:image:height]").first()?.attr("content") ?? "")
        let size: ImageSize?
        if let width, let height, width > 0, height > 0 {
            size = ImageSize(width: width, height: height)
        } else {
            size = nil
        }

        let selectors = [
            "meta[property=og:image:secure_url]",
            "meta[property=og:image]",
            "meta[name=twitter:image]",
            "meta[name=twitter:image:src]",
            "meta[itemprop=image]",
        ]

        var out: [MetaImageCandidate] = []
        out.reserveCapacity(selectors.count + 1)
        for selector in selectors {
            if let value = try doc.select(selector).first()?.attr("content"), !value.isEmpty {
                out.append(.init(url: value, size: size))
            }
        }

        if let value = try doc.select("link[rel=image_src]").first()?.attr("href"), !value.isEmpty {
            out.append(.init(url: value, size: nil))
        }

        return out
    }

    private func contentImageCandidate(img: Element, baseURL: URL) throws -> ContentImageCandidate? {
        let urlString = try imageSource(from: img)
        guard let urlString, let resolved = resolveImageURL(urlString, baseURL: baseURL) else { return nil }
        if isBlockedImageURL(resolved.absoluteString) { return nil }

        let classes = (try? img.className()) ?? ""
        if containsHiddenClass(classes) { return nil }
        let elementId = img.id()
        let altText = (try? img.attr("alt")) ?? ""
        let haystack = [classes, elementId, altText, resolved.absoluteString].joined(separator: " ").lowercased()
        if containsBlockedKeywords(haystack) { return nil }

        let width = Int(try img.attr("width")) ?? 0
        let height = Int(try img.attr("height")) ?? 0
        if width > 0 || height > 0 {
            if !passesImageSizeGate(size: ImageSize(width: width, height: height)) { return nil }
        }

        var score = 0
        if isInsideFigure(img: img) { score += 25 }
        if containsPositiveKeywords(haystack) { score += 25 }
        if altText.trimmingCharacters(in: .whitespacesAndNewlines).count >= 20 { score += 15 }
        if width > 0 && height > 0 {
            let area = width * height
            if area >= 150_000 { score += 25 }
        }

        return ContentImageCandidate(url: resolved, score: score)
    }

    private func imageSource(from img: Element) throws -> String? {
        let src = try img.attr("src")
        if !src.isEmpty { return src }

        let srcset = try img.attr("srcset")
        if let best = parseBestSrcsetURL(srcset), !best.isEmpty { return best }

        let dataSrc = try img.attr("data-src")
        if !dataSrc.isEmpty { return dataSrc }

        let dataOriginal = try img.attr("data-original")
        if !dataOriginal.isEmpty { return dataOriginal }

        let dataLazy = try img.attr("data-lazy-src")
        if !dataLazy.isEmpty { return dataLazy }

        return nil
    }

    private func parseBestSrcsetURL(_ srcset: String) -> String? {
        let trimmed = srcset.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        let parts = trimmed.split(separator: ",")
        var bestURL: String?
        var bestScore = 0.0

        for part in parts {
            let tokens = part.trimmingCharacters(in: .whitespacesAndNewlines).split(separator: " ")
            guard let url = tokens.first else { continue }
            let descriptor = tokens.dropFirst().first.map(String.init) ?? ""
            let score = srcsetDescriptorScore(descriptor)
            if score >= bestScore {
                bestScore = score
                bestURL = String(url)
            }
        }

        return bestURL
    }

    private func srcsetDescriptorScore(_ descriptor: String) -> Double {
        let cleaned = descriptor.trimmingCharacters(in: .whitespacesAndNewlines)
        if cleaned.hasSuffix("w"), let value = Double(cleaned.dropLast()) {
            return value
        }
        if cleaned.hasSuffix("x"), let value = Double(cleaned.dropLast()) {
            return value * 1000.0
        }
        return 0
    }

    private func resolveImageURL(_ raw: String, baseURL: URL) -> URL? {
        let cleaned = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleaned.isEmpty else { return nil }
        if cleaned.hasPrefix("data:") || cleaned.hasPrefix("about:") || cleaned.hasPrefix("javascript:") {
            return nil
        }
        if let absolute = URL(string: cleaned), absolute.scheme != nil {
            return absolute
        }
        return URL(string: cleaned, relativeTo: baseURL)?.absoluteURL
    }

    private func passesImageSizeGate(size: ImageSize) -> Bool {
        let width = size.width
        let height = size.height
        if width > 0 && height > 0 {
            if width < 200 || height < 200 { return false }
            let ratio = Double(max(width, 1)) / Double(max(height, 1))
            if ratio < 0.5 || ratio > 2.5 { return false }
            if width * height < 40_000 { return false }
        } else if width > 0 {
            if width < 200 { return false }
        } else if height > 0 {
            if height < 200 { return false }
        }
        return true
    }

    private func isBlockedImageURL(_ urlString: String) -> Bool {
        let lower = urlString.lowercased()
        if lower.contains(".svg") { return true }
        if lower.contains("gravatar") { return true }
        return false
    }

    private func containsBlockedKeywords(_ text: String) -> Bool {
        let blocked = [
            "logo",
            "icon",
            "avatar",
            "sprite",
            "badge",
            "emoji",
            "profile",
            "thumbnail",
            "thumb",
            "tracking",
            "pixel",
            "spacer",
            "placeholder",
            "spinner",
            "loader",
            "advert",
            "sponsor",
            "ad-",
        ]

        return blocked.contains(where: { text.contains($0) })
    }

    private func containsPositiveKeywords(_ text: String) -> Bool {
        let positive = [
            "hero",
            "lead",
            "featured",
            "primary",
            "main",
            "article",
            "story",
        ]

        return positive.contains(where: { text.contains($0) })
    }

    private func containsHiddenClass(_ classes: String) -> Bool {
        let lower = classes.lowercased()
        return lower.contains("hide") || lower.contains("hidden")
    }

    private func isInsideFigure(img: Element) -> Bool {
        if let parent = img.parent(), parent.tagName().lowercased() == "figure" { return true }
        return false
    }
}
