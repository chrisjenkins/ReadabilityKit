//
//  ReadabilityExtractor.swift
//  ReadableSwift
//
//  Created by Chris Jenkins on 15/02/2026.
//


import Foundation
import SwiftSoup

public struct ReadabilityExtractor: Sendable {
    private let loader: URLLoading
    private let options: ExtractionOptions

    public init(loader: URLLoading = DefaultURLLoader(), options: ExtractionOptions = .init()) {
        self.loader = loader
        self.options = options
    }

    // MARK: - Public API

    public func extract(from url: URL) async throws -> Article {
        let (data, _) = try await loader.fetch(url: url)

        let html =
            String(data: data, encoding: .utf8)
            ?? String(data: data, encoding: .isoLatin1)

        guard let html, !html.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw ReadableError.decodingFailed
        }

        return try extract(fromHTML: html, url: url)
    }

    public func extract(fromHTML html: String, url: URL) throws -> Article {
        let trimmed = html.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { throw ReadableError.emptyHTML }

        let doc = try SwiftSoup.parse(trimmed, url.absoluteString)

        try Cleaning.removeScriptsStylesAndUnsafe(doc, options: options)
        try Cleaning.normalizeBreaks(doc)
        try Cleaning.removeUnlikelyCandidates(doc)

        let (title, byline, excerpt) = try extractMetadata(doc: doc, fallbackURL: url)
        guard let body = doc.body() else { throw ReadableError.parseFailed }

        let candidates = try collectCandidates(in: body)

        let contentRoot: Element
        if options.enableClustering {
            contentRoot = try Clustering.mergeBestCluster(
                candidates: candidates,
                baseUri: body.getBaseUri(),
                options: options
            )
        } else {
            guard let best = candidates.max(by: { $0.score < $1.score })?.element else {
                throw ReadableError.noReadableContent
            }
            contentRoot = try wrapSingle(best, baseUri: body.getBaseUri())
        }

        // Fidelity cleaning pipeline
        try Cleaning.removeFormsButtonsEtc(contentRoot)
        try Cleaning.removeLikelyJunkBlocks(contentRoot)
        try Cleaning.fixLazyMedia(contentRoot)
        try Cleaning.cleanTables(contentRoot)
        try Cleaning.stripEmptyParagraphs(contentRoot)
        try Cleaning.unwrapRedundantSpansAndDivs(contentRoot)

        let contentHTML = try contentRoot.outerHtml()
        let textContent = try contentRoot.text()

        guard textContent.trimmingCharacters(in: .whitespacesAndNewlines).count >= 80 else {
            throw ReadableError.noReadableContent
        }

        return Article(
            url: url,
            title: title,
            byline: byline,
            excerpt: (excerpt?.isEmpty == false ? excerpt : makeExcerpt(from: textContent)),
            contentHTML: contentHTML,
            textContent: textContent
        )
    }

    // MARK: - Metadata

    private func extractMetadata(doc: Document, fallbackURL: URL) throws -> (String, String?, String?) {
        let ogTitle = try doc.select("meta[property=og:title]").first()?.attr("content")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        let docTitle = try doc.title().trimmingCharacters(in: .whitespacesAndNewlines)
        let h1 = try doc.select("h1").first()?.text()
            .trimmingCharacters(in: .whitespacesAndNewlines)

        let title = [ogTitle, docTitle, h1]
            .compactMap { $0 }
            .first(where: { !$0.isEmpty })
        ?? (fallbackURL.host ?? "Untitled")

        let byline =
            try doc.select("meta[name=author]").first?.attr("content")
                .trimmingCharacters(in: .whitespacesAndNewlines)
            ?? doc.select("[rel=author]").first?.text()
                .trimmingCharacters(in: .whitespacesAndNewlines)
            ?? doc.select(".byline, .author, [class*=author], [id*=author]").first?.text()
                .trimmingCharacters(in: .whitespacesAndNewlines)

        let excerpt =
            try doc.select("meta[name=description]").first?.attr("content")
                .trimmingCharacters(in: .whitespacesAndNewlines)
            ?? doc.select("meta[property=og:description]").first?.attr("content")
                .trimmingCharacters(in: .whitespacesAndNewlines)

        let by = (byline?.isEmpty == true) ? nil : byline
        let ex = (excerpt?.isEmpty == true) ? nil : excerpt
        return (title, by, ex)
    }

    // MARK: - Candidate collection (Readability + Density + Propagation)

    private func collectCandidates(in body: Element) throws -> [Clustering.Candidate] {
        var scoreByPath: [String: Double] = [:]
        var elementByPath: [String: Element] = [:]

        func path(for el: Element) throws -> String {
            var parts: [String] = []
            var current: Element? = el
            while let c = current {
                let tag = c.tagName().lowercased()
                let idx: Int
                if let parent = c.parent() {
                    let siblings = parent.children().array().filter { $0.tagName() == c.tagName() }
                    idx = siblings.firstIndex(where: { $0 === c }) ?? 0
                } else {
                    idx = 0
                }
                parts.append("\(tag)[\(idx)]")
                current = c.parent()
            }
            return parts.reversed().joined(separator: "/")
        }

        // Document order index
        let all = try body.select("*").array()
        var orderIndexByPath: [String: Int] = [:]
        orderIndexByPath.reserveCapacity(all.count)
        for (i, el) in all.enumerated() {
            let p = try path(for: el)
            if orderIndexByPath[p] == nil { orderIndexByPath[p] = i }
        }

        // Paragraph-based scoring + propagation to parent/grandparent
        let paragraphs = try body.select("p, pre, td, blockquote").array()
        for p in paragraphs {
            let paragraphScore = try Scoring.scoreParagraph(p)
            guard paragraphScore > 0 else { continue }

            let parent = p.parent()
            let grand = parent?.parent()

            for (level, node) in [(1.0, parent), (2.0, grand)] {
                guard let node else { continue }

                let nodePath = try path(for: node)
                let classWeight = try Scoring.classWeight(node)
                let ld = try Scoring.linkDensity(node)
                let density = try DensityScoring.score(element: node)

                // Combined score: classic + density
                let combined = paragraphScore * 0.6 + density * 0.4
                let inc = (combined / level) * (1.0 - min(0.85, ld)) + (classWeight / (level == 1.0 ? 2.0 : 4.0))

                scoreByPath[nodePath, default: 0] += inc
                elementByPath[nodePath] = node
            }
        }

        // Container density pass (helps pages with few <p>)
        let containers = try body.select("article, main, section, div").array()
        for el in containers {
            let density = try DensityScoring.score(element: el)
            guard density > 0 else { continue }

            let nodePath = try path(for: el)
            let classWeight = try Scoring.classWeight(el)
            let ld = try Scoring.linkDensity(el)

            let inc = (density * (1.0 - min(0.85, ld))) + classWeight * 0.25
            scoreByPath[nodePath, default: 0] += inc
            elementByPath[nodePath] = el
        }

        var out: [Clustering.Candidate] = []
        out.reserveCapacity(scoreByPath.count)

        for (p, s) in scoreByPath where s > 0 {
            guard let el = elementByPath[p] else { continue }
            let order = orderIndexByPath[p] ?? Int.max
            let depth = DensityScoring.domDepth(of: el)
            let tokens = try Clustering.tokenizeClassAndId(el)
            out.append(.init(path: p, orderIndex: order, depth: depth, score: s, tokens: tokens, element: el))
        }

        return out
    }

    private func wrapSingle(_ best: Element, baseUri: String) throws -> Element {
        let wrapper = Element(Tag(options.wrapInArticleTag ? "article" : "div"), baseUri)
        try wrapper.addClass("readableswift-article")
        try wrapper.appendChild(best.copy() as! Node)
        return wrapper
    }

    private func makeExcerpt(from text: String) -> String {
        let cleaned = text
            .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
        if cleaned.count <= 240 { return cleaned }
        let idx = cleaned.index(cleaned.startIndex, offsetBy: 240)
        return String(cleaned[..<idx]) + "…"
    }
}
