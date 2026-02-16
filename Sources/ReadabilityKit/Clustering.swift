//
//  Clustering.swift
//  ReadabilityKit
//
//  Created by Chris Jenkins on 15/02/2026.
//


import Foundation
import SwiftSoup

enum Clustering {

    struct Candidate {
        let path: String
        let orderIndex: Int
        let depth: Int
        let score: Double
        let tokens: Set<String>
        let element: Element
    }

    static func mergeBestCluster(
        candidates: [Candidate],
        baseUri: String,
        options: ExtractionOptions
    ) throws -> Element {
        let top = candidates
            .sorted { $0.score > $1.score }
            .prefix(max(1, options.clusterTopN))
        let topArr = Array(top)

        let wrapper = Element(Tag(options.wrapInArticleTag ? "article" : "div"), baseUri)
        try wrapper.addClass("readableswift-article")

        if topArr.count == 1 {
            try wrapper.appendChild(topArr[0].element.copy() as! Node)
            return wrapper
        }

        let inDocOrder = topArr.sorted { $0.orderIndex < $1.orderIndex }

        func compatible(_ a: Candidate, _ b: Candidate) -> Bool {
            let rankGap = abs(a.orderIndex - b.orderIndex)
            if rankGap > options.clusterMaxRankGap { return false }

            let depthDelta = abs(a.depth - b.depth)
            if depthDelta > options.clusterMaxDepthDelta { return false }

            let jac = jaccard(a.tokens, b.tokens)
            if jac < options.clusterMinTokenJaccard {
                if b.score > a.score * 0.9 && rankGap <= max(1, options.clusterMaxRankGap / 2) { return true }
                return false
            }
            return true
        }

        var clusters: [[Candidate]] = []
        var current: [Candidate] = [inDocOrder[0]]

        for i in 1..<inDocOrder.count {
            let next = inDocOrder[i]
            let seed = current[0]
            if compatible(seed, next) || compatible(current.last!, next) {
                current.append(next)
            } else {
                clusters.append(current)
                current = [next]
            }
        }
        clusters.append(current)

        func clusterValue(_ c: [Candidate]) -> Double {
            let sum = c.reduce(0.0) { $0 + $1.score }
            let bonus = log(Double(c.count) + 1.0) * 0.25
            return sum + bonus
        }

        guard let bestCluster = clusters.max(by: { clusterValue($0) < clusterValue($1) }) else {
            throw ReadableError.noReadableContent
        }

        let bestSorted = bestCluster.sorted { $0.orderIndex < $1.orderIndex }

        // De-duplicate nested overlaps: skip if already contained by a previously added node
        var addedPaths: [String] = []
        for c in bestSorted {
            if addedPaths.contains(where: { c.path.hasPrefix($0 + "/") }) { continue }
            addedPaths.append(c.path)
            try wrapper.appendChild(c.element.copy() as! Node)
        }

        return wrapper
    }

    static func tokenizeClassAndId(_ el: Element) throws -> Set<String> {
        let id = el.id().lowercased()
        let cls = try el.className().lowercased()
        let raw = (id + " " + cls)

        // Hard negatives: stop comments/disqus from clustering in
        if raw.contains("comment") || raw.contains("disqus") || raw.contains("reply") { return [] }

        let parts = raw
            .split(whereSeparator: { !$0.isLetter && !$0.isNumber && $0 != "-" && $0 != "_" })
            .map { String($0) }

        return Set(parts.filter { $0.count >= 3 && $0 != "nav" && $0 != "footer" && $0 != "header" })
    }

    private static func jaccard(_ a: Set<String>, _ b: Set<String>) -> Double {
        if a.isEmpty && b.isEmpty { return 1.0 }
        if a.isEmpty || b.isEmpty { return 0.0 }
        let inter = a.intersection(b).count
        let union = a.union(b).count
        return Double(inter) / Double(union)
    }
}
