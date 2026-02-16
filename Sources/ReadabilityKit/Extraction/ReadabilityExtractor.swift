//
//  ReadabilityExtractor.swift
//  ReadabilityKit
//
//  Created by Chris Jenkins on 15/02/2026.
//


import Foundation
import SwiftSoup

/// High-level API that loads HTML and extracts cleaned, readable article content.
public struct ReadabilityExtractor: Sendable {
    private let loader: URLLoading
    private let options: ExtractionOptions
    private let clusteringEngine = ClusteringEngine()
    private let paragraphScorer = ParagraphScorer()
    private let classWeightScorer = ClassWeightScorer()
    private let linkDensityScorer = LinkDensityScorer()
    private let removeScriptsStylesAndUnsafePass = RemoveScriptsStylesAndUnsafePass()
    private let normalizeBreaksPass = NormalizeBreaksPass()
    private let removeUnlikelyCandidatesPass = RemoveUnlikelyCandidatesPass()
    private let removeFormsButtonsEtcPass = RemoveFormsButtonsEtcPass()
    private let removeLikelyJunkBlocksPass = RemoveLikelyJunkBlocksPass()
    private let fixLazyMediaPass = FixLazyMediaPass()
    private let cleanTablesPass = CleanTablesPass()
    private let stripEmptyParagraphsPass = StripEmptyParagraphsPass()
    private let unwrapRedundantSpansAndDivsPass = UnwrapRedundantSpansAndDivsPass()

    /// Creates an extractor with a pluggable HTML loader and parsing options.
    /// - Parameters:
    ///   - loader: Strategy used to load HTML for URL-based extraction.
    ///   - options: Heuristics and cleanup options that drive parsing behavior.
    public init(loader: URLLoading = URLSessionHTMLLoader(), options: ExtractionOptions = .init()) {
        self.loader = loader
        self.options = options
    }

    // MARK: - Public API

    /// Loads a page URL, parses it, and returns cleaned article content.
    ///
    /// Parsing flow:
    /// 1. Load HTML via the configured `URLLoading` implementation.
    /// 2. Parse and normalize DOM.
    /// 3. Score candidate nodes and select/cluster the best content region.
    /// 4. Run cleanup passes and return structured article output.
    ///
    /// - Parameter url: The source page URL to extract.
    /// - Returns: An `Article` containing metadata, cleaned HTML, and plain text.
    /// - Throws: `ReadabilityError` when loading/parsing/content selection fails.
    public func extract(from url: URL) async throws -> Article {
        let html = try await loader.fetchHTML(url: url)
        return try extract(fromHTML: html, url: url)
    }

    /// Parses already-available HTML and extracts the most readable article region.
    ///
    /// This method applies normalization, candidate scoring, optional clustering, and
    /// post-selection cleanup to produce high-fidelity article HTML and text output.
    ///
    /// - Parameters:
    ///   - html: Raw HTML to parse.
    ///   - url: Canonical URL used for base URI resolution and metadata fallback.
    /// - Returns: An extracted `Article`.
    /// - Throws: `ReadabilityError` when HTML is empty, parsing fails, or readable content is not found.
    public func extract(fromHTML html: String, url: URL) throws -> Article {
        let trimmed = html.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { throw ReadabilityError.emptyHTML }

        let doc = try SwiftSoup.parse(trimmed, url.absoluteString)

        try removeScriptsStylesAndUnsafePass.apply(to: doc, options: options)
        try normalizeBreaksPass.apply(to: doc, options: options)
        try removeUnlikelyCandidatesPass.apply(to: doc, options: options)

        let (title, byline, excerpt) = try extractMetadata(doc: doc, fallbackURL: url)
        guard let body = doc.body() else { throw ReadabilityError.parseFailed }

        let candidates = try collectCandidates(in: body)

        let contentRoot: Element
        if options.enableClustering {
            contentRoot = try clusteringEngine.mergeBestCluster(
                candidates: candidates,
                baseUri: body.getBaseUri(),
                options: options
            )
        } else {
            guard let best = candidates.max(by: { $0.score < $1.score })?.element else {
                throw ReadabilityError.noReadableContent
            }
            contentRoot = try wrapSingle(best, baseUri: body.getBaseUri())
        }

        // Fidelity cleaning pipeline
        try removeFormsButtonsEtcPass.apply(to: contentRoot, options: options)
        try removeLikelyJunkBlocksPass.apply(to: contentRoot, options: options)
        try fixLazyMediaPass.apply(to: contentRoot, options: options)
        try cleanTablesPass.apply(to: contentRoot, options: options)
        try stripEmptyParagraphsPass.apply(to: contentRoot, options: options)
        try unwrapRedundantSpansAndDivsPass.apply(to: contentRoot, options: options)

        let contentHTML = try contentRoot.outerHtml()
        let textContent = try contentRoot.text()

        guard textContent.trimmingCharacters(in: .whitespacesAndNewlines).count >= 80 else {
            throw ReadabilityError.noReadableContent
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

    private func collectCandidates(in body: Element) throws -> [ClusteringCandidate] {
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
            let paragraphScore = try paragraphScorer.score(p)
            guard paragraphScore > 0 else { continue }

            let parent = p.parent()
            let grand = parent?.parent()

            for (level, node) in [(1.0, parent), (2.0, grand)] {
                guard let node else { continue }

                let nodePath = try path(for: node)
                let classWeight = try classWeightScorer.score(node)
                let ld = try linkDensityScorer.score(node)
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
            let classWeight = try classWeightScorer.score(el)
            let ld = try linkDensityScorer.score(el)

            let inc = (density * (1.0 - min(0.85, ld))) + classWeight * 0.25
            scoreByPath[nodePath, default: 0] += inc
            elementByPath[nodePath] = el
        }

        var out: [ClusteringCandidate] = []
        out.reserveCapacity(scoreByPath.count)

        for (p, s) in scoreByPath where s > 0 {
            guard let el = elementByPath[p] else { continue }
            let order = orderIndexByPath[p] ?? Int.max
            let depth = DensityScoring.domDepth(of: el)
            let tokens = try clusteringEngine.tokenizeClassAndId(el)
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
