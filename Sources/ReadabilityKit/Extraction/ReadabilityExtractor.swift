//
//  ReadabilityExtractor.swift
//  ReadabilityKit
//
//  Created by Chris Jenkins on 15/02/2026.
//


import Foundation
import OSLog
import SwiftSoup

/// High-level API that loads HTML and extracts cleaned, readable article content.
public struct ReadabilityExtractor: Sendable {
    private struct ExtractionAttempt {
        let removeUnlikelyCandidates: Bool
        let minimumTextLength: Int
    }

    private struct SinglePageExtractionResult {
        let article: Article
        let nextPageURL: URL?
    }

    private struct MetadataResult {
        let title: String
        let byline: String?
        let excerpt: String?
        let jsonLDLeadImageURL: URL?
    }

    private struct JSONLDMetadata {
        let title: String?
        let byline: String?
        let excerpt: String?
        let leadImageURL: URL?
    }

    private let logger = Logger(subsystem: "ReadabilityKit", category: "ReadabilityExtractor")
    private let loader: URLLoading
    private let options: ExtractionOptions
    private let clusteringEngine = ClusteringEngine()
    private let paragraphScorer = ParagraphScorer()
    private let classWeightScorer = ClassWeightScorer()
    private let linkDensityScorer = LinkDensityScorer()
    private let visibilityFilter = VisibilityFilter()
    private let removeScriptsStylesAndUnsafePass = RemoveScriptsStylesAndUnsafePass()
    private let normalizeBreaksPass = NormalizeBreaksPass()
    private let removeHiddenElementsPass = RemoveHiddenElementsPass()
    private let removeUnlikelyCandidatesPass = RemoveUnlikelyCandidatesPass()
    private let removeFormsButtonsEtcPass = RemoveFormsButtonsEtcPass()
    private let removeLikelyJunkBlocksPass = RemoveLikelyJunkBlocksPass()
    private let fixLazyMediaPass = FixLazyMediaPass()
    private let cleanTablesPass = CleanTablesPass()
    private let stripEmptyParagraphsPass = StripEmptyParagraphsPass()
    private let unwrapRedundantSpansAndDivsPass = UnwrapRedundantSpansAndDivsPass()
    private let dedupeHeadersPass = DedupeHeadersPass()
    private let leadImageExtractor = LeadImageExtractor()
    private let nextPageDetector = NextPageDetector()
    private let domainRuleRegistry = DomainRuleRegistry.default

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
        if options.enablePaginationMerge {
            return try await extractWithPagination(from: url)
        }
        let html = try await loader.fetchHTML(url: url)
        return try extractSinglePage(fromHTML: html, url: url).article
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
        try extractSinglePage(fromHTML: html, url: url).article
    }

    private func extractWithPagination(from url: URL) async throws -> Article {
        var visitedURLs = Set<String>()
        var mergedArticles: [Article] = []
        var mergedPageURLs: [URL] = []
        var nextURL: URL? = url
        var firstDetectedNextPageURL: URL?

        while let pageURL = nextURL, mergedArticles.count < options.maxPaginationPages {
            let key = normalizedURLKey(pageURL)
            if visitedURLs.contains(key) { break }
            visitedURLs.insert(key)

            let html = try await loader.fetchHTML(url: pageURL)
            let pageResult = try extractSinglePage(fromHTML: html, url: pageURL)
            let pageArticle = pageResult.article

            if mergedArticles.isEmpty {
                firstDetectedNextPageURL = pageResult.nextPageURL
                mergedArticles.append(pageArticle)
                mergedPageURLs.append(pageURL)
            } else {
                if isLikelyDuplicatePage(pageArticle, comparedWith: mergedArticles) {
                    break
                }
                mergedArticles.append(pageArticle)
                mergedPageURLs.append(pageURL)
            }

            guard let candidateNextURL = pageResult.nextPageURL else {
                nextURL = nil
                continue
            }

            let nextKey = normalizedURLKey(candidateNextURL)
            nextURL = visitedURLs.contains(nextKey) ? nil : candidateNextURL
        }

        guard let firstArticle = mergedArticles.first else {
            throw ReadabilityError.noReadableContent
        }
        let merged = try mergeArticlePages(mergedArticles, primaryURL: url)

        return Article(
            url: merged.url,
            title: merged.title,
            byline: merged.byline,
            excerpt: merged.excerpt,
            contentHTML: merged.contentHTML,
            textContent: merged.textContent,
            leadImageURL: merged.leadImageURL,
            nextPageURL: firstDetectedNextPageURL,
            mergedPageURLs: mergedPageURLs.isEmpty ? [firstArticle.url] : mergedPageURLs
        )
    }

    private func extractSinglePage(fromHTML html: String, url: URL) throws -> SinglePageExtractionResult {
        let trimmed = html.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { throw ReadabilityError.emptyHTML }

        let strictAttempt = ExtractionAttempt(removeUnlikelyCandidates: true, minimumTextLength: 80)
        let relaxedAttempt = ExtractionAttempt(removeUnlikelyCandidates: false, minimumTextLength: 40)

        do {
            let strictResult = try performExtraction(
                fromHTML: trimmed,
                url: url,
                attempt: strictAttempt
            )
            let strictArticle = strictResult.article

            // Progressive relaxation: only retry if strict output looks thin.
            if strictArticle.textContent.count >= 320 {
                return strictResult
            }

            if let relaxedResult = try? performExtraction(
                fromHTML: trimmed,
                url: url,
                attempt: relaxedAttempt
            ) {
                let relaxedArticle = relaxedResult.article
                let strictQuality = articleQualityScore(strictArticle)
                let relaxedQuality = articleQualityScore(relaxedArticle)
                if relaxedQuality > strictQuality * 1.1 {
                    return relaxedResult
                }
            }

            return strictResult
        } catch {
            return try performExtraction(
                fromHTML: trimmed,
                url: url,
                attempt: relaxedAttempt
            )
        }
    }

    private func performExtraction(
        fromHTML html: String,
        url: URL,
        attempt: ExtractionAttempt
    ) throws -> SinglePageExtractionResult {
        let doc = try SwiftSoup.parse(html, url.absoluteString)
        let metadata = try extractMetadata(doc: doc, fallbackURL: url)
        let matchingRules = options.enableDomainRules ? domainRuleRegistry.matchingRules(for: url) : []
        let domainMetadata = try mergedDomainMetadataOverrides(
            rules: matchingRules,
            doc: doc,
            fallbackURL: url
        )

        try removeScriptsStylesAndUnsafePass.apply(to: doc, options: options)
        try normalizeBreaksPass.apply(to: doc, options: options)
        if options.filterHiddenNodes {
            try removeHiddenElementsPass.apply(to: doc, options: options)
        }
        let preferredDomainRoot = (options.domainRuleMode == .preferRules)
            ? try preferredDomainContentRoot(rules: matchingRules, doc: doc)
            : nil
        if attempt.removeUnlikelyCandidates && preferredDomainRoot == nil {
            try removeUnlikelyCandidatesPass.apply(to: doc, options: options)
        }
        guard let body = doc.body() else { throw ReadabilityError.parseFailed }

        let contentRoot: Element
        if let preferredDomainRoot {
            contentRoot = try wrapPreferredContentRoot(
                preferredDomainRoot,
                baseUri: body.getBaseUri()
            )
        } else {
            let candidateAdjustments = try domainCandidateScoreAdjustments(
                rules: matchingRules,
                doc: doc
            )
            let candidates = try collectCandidates(
                in: body,
                candidateAdjustments: candidateAdjustments
            )
            guard let topCandidate = candidates.max(by: { $0.score < $1.score }) else {
                throw ReadabilityError.noReadableContent
            }

            if options.enableClustering {
                contentRoot = try clusteringEngine.mergeBestCluster(
                    candidates: candidates,
                    baseUri: body.getBaseUri(),
                    options: options
                )
            } else {
                contentRoot = try wrapSingleWithSiblingInclusion(
                    best: topCandidate,
                    allCandidates: candidates,
                    baseUri: body.getBaseUri()
                )
            }
        }

        // Fidelity cleaning pipeline
        try removeFormsButtonsEtcPass.apply(to: contentRoot, options: options)
        try removeLikelyJunkBlocksPass.apply(to: contentRoot, options: options)
        try fixLazyMediaPass.apply(to: contentRoot, options: options)
        try cleanTablesPass.apply(to: contentRoot, options: options)
        try stripEmptyParagraphsPass.apply(to: contentRoot, options: options)
        try unwrapRedundantSpansAndDivsPass.apply(to: contentRoot, options: options)
        let resolvedTitle = domainMetadata.title ?? metadata.title
        try dedupeHeadersPass.apply(
            to: contentRoot,
            resolvedTitle: resolvedTitle,
            options: options
        )
        let detectedNextPageURL = try nextPageDetector.detectNextPageURL(
            in: doc,
            contentRoot: contentRoot,
            baseURL: url,
            options: options
        )

        var leadImageURL = try leadImageExtractor.extractLeadImageURL(
            doc: doc,
            contentRoot: contentRoot,
            fallbackURL: url
        )
        if leadImageURL == nil {
            leadImageURL = domainMetadata.leadImageURL ?? metadata.jsonLDLeadImageURL
        }

        #if DEBUG
        logger.debug("Extracting final HTML for \(url.absoluteString, privacy: .public)")
        #endif

        let contentHTML = try contentRoot.outerHtml()
        let textContent = try contentRoot.text()

        #if DEBUG
        logger.debug(
            "Extracted final HTML for \(url.absoluteString, privacy: .public): \(contentHTML, privacy: .public)"
        )
        #endif

        guard textContent.trimmingCharacters(in: .whitespacesAndNewlines).count >= attempt.minimumTextLength else {
            throw ReadabilityError.noReadableContent
        }

        let article = Article(
            url: url,
            title: resolvedTitle,
            byline: domainMetadata.byline ?? metadata.byline,
            excerpt: (
                (domainMetadata.excerpt ?? metadata.excerpt)?.isEmpty == false
                    ? (domainMetadata.excerpt ?? metadata.excerpt)
                    : makeExcerpt(from: textContent)
            ),
            contentHTML: contentHTML,
            textContent: textContent,
            leadImageURL: leadImageURL,
            nextPageURL: detectedNextPageURL,
            mergedPageURLs: [url]
        )

        return SinglePageExtractionResult(article: article, nextPageURL: detectedNextPageURL)
    }

    // MARK: - Metadata

    private func extractMetadata(doc: Document, fallbackURL: URL) throws -> MetadataResult {
        let jsonLDMetadata = try extractJSONLDMetadata(doc: doc, fallbackURL: fallbackURL)
        let ogTitle = try doc.select("meta[property=og:title]").first()?.attr("content")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        let docTitle = try doc.title().trimmingCharacters(in: .whitespacesAndNewlines)
        let h1 = try doc.select("h1").first()?.text()
            .trimmingCharacters(in: .whitespacesAndNewlines)

        let title = [ogTitle, jsonLDMetadata.title, docTitle, h1]
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
            ?? jsonLDMetadata.byline

        let excerpt =
            try doc.select("meta[name=description]").first?.attr("content")
                .trimmingCharacters(in: .whitespacesAndNewlines)
            ?? doc.select("meta[property=og:description]").first?.attr("content")
                .trimmingCharacters(in: .whitespacesAndNewlines)
            ?? jsonLDMetadata.excerpt

        let by = (byline?.isEmpty == true) ? nil : byline
        let ex = (excerpt?.isEmpty == true) ? nil : excerpt
        return MetadataResult(
            title: title,
            byline: by,
            excerpt: ex,
            jsonLDLeadImageURL: jsonLDMetadata.leadImageURL
        )
    }

    private func extractJSONLDMetadata(doc: Document, fallbackURL: URL) throws -> JSONLDMetadata {
        let scripts = try doc.select("script[type=application/ld+json]").array()
        guard !scripts.isEmpty else {
            return JSONLDMetadata(title: nil, byline: nil, excerpt: nil, leadImageURL: nil)
        }

        var bestMetadata = JSONLDMetadata(title: nil, byline: nil, excerpt: nil, leadImageURL: nil)
        var bestScore = -1

        for script in scripts {
            let scriptContent = (try? script.html()) ?? script.data()
            let raw = scriptContent.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !raw.isEmpty, let data = raw.data(using: .utf8) else { continue }
            guard let object = try? JSONSerialization.jsonObject(with: data) else { continue }

            let dictionaries = flattenJSONDictionaries(object)
            for dictionary in dictionaries {
                let candidate = jsonLDMetadataCandidate(from: dictionary, fallbackURL: fallbackURL)
                guard candidate.score > 0 else { continue }
                if candidate.score > bestScore {
                    bestMetadata = candidate.metadata
                    bestScore = candidate.score
                } else if candidate.score == bestScore {
                    bestMetadata = mergeJSONLDMetadata(preferred: bestMetadata, fallback: candidate.metadata)
                }
            }
        }

        return bestMetadata
    }

    private func flattenJSONDictionaries(_ object: Any) -> [[String: Any]] {
        if let dictionary = object as? [String: Any] {
            var out = [dictionary]
            if let graph = dictionary["@graph"] {
                out.append(contentsOf: flattenJSONDictionaries(graph))
            }
            return out
        }
        if let array = object as? [Any] {
            return array.flatMap { flattenJSONDictionaries($0) }
        }
        return []
    }

    private func jsonLDMetadataCandidate(
        from dictionary: [String: Any],
        fallbackURL: URL
    ) -> (metadata: JSONLDMetadata, score: Int) {
        let isArticleType = jsonLDContainsArticleType(dictionary["@type"])
        let title = normalizedJSONValue(dictionary["headline"] ?? dictionary["name"])
        let byline = jsonLDAuthorName(from: dictionary["author"])
        let excerpt = normalizedJSONValue(dictionary["description"])
        let imageURL = jsonLDImageURL(from: dictionary["image"], fallbackURL: fallbackURL)

        var score = 0
        if isArticleType { score += 3 }
        if title != nil { score += 2 }
        if byline != nil { score += 1 }
        if excerpt != nil { score += 1 }
        if imageURL != nil { score += 1 }

        return (
            JSONLDMetadata(title: title, byline: byline, excerpt: excerpt, leadImageURL: imageURL),
            score
        )
    }

    private func mergeJSONLDMetadata(preferred: JSONLDMetadata, fallback: JSONLDMetadata) -> JSONLDMetadata {
        JSONLDMetadata(
            title: preferred.title ?? fallback.title,
            byline: preferred.byline ?? fallback.byline,
            excerpt: preferred.excerpt ?? fallback.excerpt,
            leadImageURL: preferred.leadImageURL ?? fallback.leadImageURL
        )
    }

    private func jsonLDContainsArticleType(_ value: Any?) -> Bool {
        if let type = value as? String {
            return type.lowercased().contains("article")
        }
        if let types = value as? [Any] {
            return types.contains(where: { jsonLDContainsArticleType($0) })
        }
        return false
    }

    private func jsonLDAuthorName(from value: Any?) -> String? {
        if let author = normalizedJSONValue(value) {
            return author
        }
        if let dictionary = value as? [String: Any] {
            return normalizedJSONValue(dictionary["name"] ?? dictionary["@id"])
        }
        if let authors = value as? [Any] {
            for author in authors {
                if let name = jsonLDAuthorName(from: author) {
                    return name
                }
            }
        }
        return nil
    }

    private func jsonLDImageURL(from value: Any?, fallbackURL: URL) -> URL? {
        if let image = normalizedJSONValue(value) {
            return resolveMetadataURL(image, fallbackURL: fallbackURL)
        }
        if let dictionary = value as? [String: Any] {
            if let url = normalizedJSONValue(dictionary["url"] ?? dictionary["@id"]) {
                return resolveMetadataURL(url, fallbackURL: fallbackURL)
            }
        }
        if let images = value as? [Any] {
            for image in images {
                if let resolved = jsonLDImageURL(from: image, fallbackURL: fallbackURL) {
                    return resolved
                }
            }
        }
        return nil
    }

    private func normalizedJSONValue(_ value: Any?) -> String? {
        guard let value else { return nil }
        if let text = value as? String {
            let cleaned = text.trimmingCharacters(in: .whitespacesAndNewlines)
            return cleaned.isEmpty ? nil : cleaned
        }
        if let number = value as? NSNumber {
            return number.stringValue
        }
        return nil
    }

    private func resolveMetadataURL(_ raw: String, fallbackURL: URL) -> URL? {
        let cleaned = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleaned.isEmpty else { return nil }
        if let absolute = URL(string: cleaned), absolute.scheme != nil {
            return absolute
        }
        return URL(string: cleaned, relativeTo: fallbackURL)?.absoluteURL
    }

    private func preferredDomainContentRoot(
        rules: [any DomainExtractionRule],
        doc: Document
    ) throws -> Element? {
        guard !rules.isEmpty else { return nil }
        for rule in rules {
            if let preferred = try rule.preferredContentRoot(in: doc) {
                return preferred
            }
        }
        return nil
    }

    private func domainCandidateScoreAdjustments(
        rules: [any DomainExtractionRule],
        doc: Document
    ) throws -> [DomainCandidateAdjustment] {
        guard !rules.isEmpty else { return [] }
        var out: [DomainCandidateAdjustment] = []
        for rule in rules {
            out.append(contentsOf: try rule.candidateScoreAdjustments(in: doc))
        }
        return out
    }

    private func mergedDomainMetadataOverrides(
        rules: [any DomainExtractionRule],
        doc: Document,
        fallbackURL: URL
    ) throws -> DomainMetadataOverride {
        guard !rules.isEmpty else { return .empty }

        var merged = DomainMetadataOverride.empty
        for rule in rules {
            let override = try rule.metadataOverrides(in: doc, fallbackURL: fallbackURL)
            merged = DomainMetadataOverride(
                title: merged.title ?? override.title,
                byline: merged.byline ?? override.byline,
                excerpt: merged.excerpt ?? override.excerpt,
                leadImageURL: merged.leadImageURL ?? override.leadImageURL
            )
        }
        return merged
    }

    // MARK: - Candidate collection (Readability + Density + Propagation)

    private func collectCandidates(
        in body: Element,
        candidateAdjustments: [DomainCandidateAdjustment]
    ) throws -> [ClusteringCandidate] {
        var scoreByPath: [String: Double] = [:]
        var elementByPath: [String: Element] = [:]

        // Document order index
        let all = try body.select("*").array()
        var orderIndexByPath: [String: Int] = [:]
        orderIndexByPath.reserveCapacity(all.count)
        for (i, el) in all.enumerated() {
            let p = domPath(for: el)
            if orderIndexByPath[p] == nil { orderIndexByPath[p] = i }
        }

        // Paragraph-based scoring + propagation to parent/grandparent
        let paragraphs = try body.select("p, pre, td, blockquote").array()
        for p in paragraphs {
            if options.filterHiddenNodes {
                let isVisible = try visibilityFilter.isProbablyVisible(p)
                if !isVisible { continue }
            }
            let paragraphScore = try paragraphScorer.score(p)
            guard paragraphScore > 0 else { continue }

            let parent = p.parent()
            let grand = parent?.parent()

            for (level, node) in [(1.0, parent), (2.0, grand)] {
                guard let node else { continue }
                if options.filterHiddenNodes {
                    let isVisible = try visibilityFilter.isProbablyVisible(node)
                    if !isVisible { continue }
                }

                let nodePath = domPath(for: node)
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
            if options.filterHiddenNodes {
                let isVisible = try visibilityFilter.isProbablyVisible(el)
                if !isVisible { continue }
            }
            let density = try DensityScoring.score(element: el)
            guard density > 0 else { continue }

            let nodePath = domPath(for: el)
            let classWeight = try classWeightScorer.score(el)
            let ld = try linkDensityScorer.score(el)

            let inc = (density * (1.0 - min(0.85, ld))) + classWeight * 0.25
            scoreByPath[nodePath, default: 0] += inc
            elementByPath[nodePath] = el
        }

        for adjustment in candidateAdjustments where adjustment.scoreDelta != 0 {
            if options.filterHiddenNodes {
                let isVisible = try visibilityFilter.isProbablyVisible(adjustment.element)
                if !isVisible { continue }
            }
            let nodePath = domPath(for: adjustment.element)
            scoreByPath[nodePath, default: 0] += adjustment.scoreDelta
            elementByPath[nodePath] = adjustment.element
        }

        try applySiblingCandidateBoost(
            scoreByPath: &scoreByPath,
            elementByPath: &elementByPath
        )

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

    private func wrapSingleWithSiblingInclusion(
        best: ClusteringCandidate,
        allCandidates: [ClusteringCandidate],
        baseUri: String
    ) throws -> Element {
        let wrapper = Element(Tag(options.wrapInArticleTag ? "article" : "div"), baseUri)
        try wrapper.addClass("readableswift-article")
        guard let parent = best.element.parent() else {
            try wrapper.appendChild(best.element.copy() as! Node)
            return wrapper
        }

        let scoreByPath = Dictionary(uniqueKeysWithValues: allCandidates.map { ($0.path, $0.score) })
        let inclusionThreshold = max(10.0, best.score * 0.2)

        for sibling in parent.children().array() {
            if sibling === best.element {
                try wrapper.appendChild(sibling.copy() as! Node)
                continue
            }
            if try shouldIncludeSibling(
                sibling,
                scoreByPath: scoreByPath,
                inclusionThreshold: inclusionThreshold
            ) {
                try wrapper.appendChild(sibling.copy() as! Node)
            }
        }

        return wrapper
    }

    private func wrapPreferredContentRoot(_ root: Element, baseUri: String) throws -> Element {
        let wrapper = Element(Tag(options.wrapInArticleTag ? "article" : "div"), baseUri)
        try wrapper.addClass("readableswift-article")
        try wrapper.appendChild(root.copy() as! Node)
        return wrapper
    }

    private func shouldIncludeSibling(
        _ sibling: Element,
        scoreByPath: [String: Double],
        inclusionThreshold: Double
    ) throws -> Bool {
        if options.filterHiddenNodes {
            let isVisible = try visibilityFilter.isProbablyVisible(sibling)
            if !isVisible { return false }
        }

        let path = domPath(for: sibling)
        if let knownScore = scoreByPath[path], knownScore >= inclusionThreshold {
            return true
        }

        let text = try sibling.text().trimmingCharacters(in: .whitespacesAndNewlines)
        let textLength = text.count
        guard textLength >= 60 else { return false }

        let linkDensity = try linkDensityScorer.score(sibling)
        let classWeight = try classWeightScorer.score(sibling)
        let tag = sibling.tagName().lowercased()

        if tag == "p" && linkDensity < 0.25 && textLength >= 80 {
            return true
        }

        return textLength >= 180 && linkDensity < 0.33 && classWeight > -20
    }

    private func applySiblingCandidateBoost(
        scoreByPath: inout [String: Double],
        elementByPath: inout [String: Element]
    ) throws {
        guard let (topPath, topScore) = scoreByPath.max(by: { $0.value < $1.value }),
              let topElement = elementByPath[topPath],
              let parent = topElement.parent() else {
            return
        }

        let threshold = max(10.0, topScore * 0.2)
        for sibling in parent.children().array() {
            if sibling === topElement { continue }
            guard try shouldIncludeSibling(
                sibling,
                scoreByPath: scoreByPath,
                inclusionThreshold: threshold
            ) else {
                continue
            }

            let path = domPath(for: sibling)
            let textLength = try sibling.text().trimmingCharacters(in: .whitespacesAndNewlines).count
            let linkDensity = try linkDensityScorer.score(sibling)
            let boost = max(5.0, min(topScore * 0.35, Double(textLength) / 30.0))
            let weightedBoost = boost * (1.0 - min(0.7, linkDensity))
            guard weightedBoost > 0 else { continue }

            scoreByPath[path, default: 0] = max(scoreByPath[path] ?? 0, weightedBoost)
            elementByPath[path] = sibling
        }
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

    private func mergeArticlePages(_ pages: [Article], primaryURL: URL) throws -> Article {
        guard let first = pages.first else { throw ReadabilityError.noReadableContent }
        guard pages.count > 1 else { return first }

        let wrapper = Element(Tag(options.wrapInArticleTag ? "article" : "div"), primaryURL.absoluteString)
        try wrapper.addClass("readableswift-article")
        var seenBlocks = Set<String>()

        for (index, page) in pages.enumerated() {
            let fragment = try SwiftSoup.parseBodyFragment(page.contentHTML, primaryURL.absoluteString)
            guard let body = fragment.body() else { continue }
            let sourceRoot = body.children().first() ?? body

            for child in sourceRoot.children().array() {
                let blockText = try child.text().trimmingCharacters(in: .whitespacesAndNewlines)
                if shouldSkipMergedBlockText(blockText, isFirstPage: index == 0, seenBlocks: &seenBlocks) {
                    continue
                }
                try wrapper.appendChild(child.copy() as! Node)
            }
        }

        let mergedHTML = try wrapper.outerHtml()
        let mergedText = try wrapper.text()

        return Article(
            url: primaryURL,
            title: first.title,
            byline: first.byline,
            excerpt: first.excerpt,
            contentHTML: mergedHTML,
            textContent: mergedText,
            leadImageURL: first.leadImageURL,
            nextPageURL: first.nextPageURL,
            mergedPageURLs: pages.map(\.url)
        )
    }

    private func shouldSkipMergedBlockText(
        _ text: String,
        isFirstPage: Bool,
        seenBlocks: inout Set<String>
    ) -> Bool {
        let normalized = text
            .lowercased()
            .replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
        if normalized.isEmpty { return true }
        if normalized.count < 40 { return false }

        let key = normalized
        if seenBlocks.contains(key) {
            return !isFirstPage
        }
        seenBlocks.insert(key)
        return false
    }

    private func isLikelyDuplicatePage(_ candidate: Article, comparedWith existingPages: [Article]) -> Bool {
        let candidateText = normalizedSimilarityText(candidate.textContent)
        guard !candidateText.isEmpty else { return true }

        for existing in existingPages {
            let existingText = normalizedSimilarityText(existing.textContent)
            if existingText.isEmpty { continue }

            if candidateText == existingText {
                return true
            }

            let overlap = tokenJaccard(candidateText, existingText)
            if overlap >= 0.92 {
                return true
            }
        }

        return false
    }

    private func normalizedSimilarityText(_ text: String) -> String {
        text
            .lowercased()
            .replacingOccurrences(of: #"[^\p{L}\p{N}\s]+"#, with: " ", options: .regularExpression)
            .replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func tokenJaccard(_ lhs: String, _ rhs: String) -> Double {
        let left = Set(lhs.split(separator: " ").map(String.init).filter { $0.count >= 2 })
        let right = Set(rhs.split(separator: " ").map(String.init).filter { $0.count >= 2 })
        if left.isEmpty && right.isEmpty { return 1.0 }
        if left.isEmpty || right.isEmpty { return 0.0 }
        let intersection = left.intersection(right).count
        let union = left.union(right).count
        return Double(intersection) / Double(union)
    }

    private func normalizedURLKey(_ url: URL) -> String {
        var components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        components?.fragment = nil
        return components?.string?.lowercased() ?? url.absoluteString.lowercased()
    }

    private func articleQualityScore(_ article: Article) -> Double {
        let textLength = article.textContent.trimmingCharacters(in: .whitespacesAndNewlines).count
        let paragraphCount = article.contentHTML.components(separatedBy: "<p").count - 1
        let linkCount = article.contentHTML.components(separatedBy: "<a").count - 1
        let linkPenalty = min(0.6, Double(linkCount) / Double(max(1, paragraphCount + 1)))
        return Double(textLength) + Double(paragraphCount * 80) - linkPenalty * 250.0
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
