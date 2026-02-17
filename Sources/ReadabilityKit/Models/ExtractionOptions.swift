//
//  ExtractionOptions.swift
//  ReadabilityKit
//
//  Created by Chris Jenkins on 15/02/2026.
//

import Foundation

/// Controls how domain-specific extraction rules influence article extraction.
public enum DomainRuleMode: Sendable {
    /// Domain rules contribute candidate score and metadata hints only.
    case rulesAsHints
    /// Domain rules may provide a preferred content root before generic scoring.
    case preferRules
}

/// Configures extraction heuristics and content-preservation behavior.
public struct ExtractionOptions: Sendable {
    public var preserveHTML: Bool
    public var keepIframes: Bool
    public var keepVideos: Bool
    public var keepAudio: Bool
    public var wrapInArticleTag: Bool
    public var filterHiddenNodes: Bool

    public var enableClustering: Bool
    public var clusterTopN: Int
    public var clusterMaxRankGap: Int
    public var clusterMaxDepthDelta: Int
    public var clusterMinTokenJaccard: Double

    public var enableDomainRules: Bool
    public var domainRuleMode: DomainRuleMode

    /// Creates extraction options that tune parsing, cleaning, and cluster selection.
    /// - Parameters:
    ///   - preserveHTML: Keeps HTML output fidelity when true.
    ///   - keepIframes: Preserves iframe elements during cleanup.
    ///   - keepVideos: Preserves video/source elements during cleanup.
    ///   - keepAudio: Preserves audio/source elements during cleanup.
    ///   - wrapInArticleTag: Wraps final output in `<article>` instead of `<div>` when true.
    ///   - filterHiddenNodes: Removes hidden or aria-hidden DOM regions and skips them during scoring.
    ///   - enableClustering: Enables multi-node clustering instead of single best-node selection.
    ///   - clusterTopN: Maximum top-scoring nodes considered for cluster merge.
    ///   - clusterMaxRankGap: Max document-order distance allowed when clustering nodes.
    ///   - clusterMaxDepthDelta: Max DOM depth difference allowed when clustering nodes.
    ///   - clusterMinTokenJaccard: Minimum class/id token overlap used for compatibility.
    ///   - enableDomainRules: Enables domain-specific extraction rule matching when true.
    ///   - domainRuleMode: Controls whether domain rules are hints only or preferred roots.
    public init(
        preserveHTML: Bool = true,
        keepIframes: Bool = false,
        keepVideos: Bool = true,
        keepAudio: Bool = true,
        wrapInArticleTag: Bool = true,
        filterHiddenNodes: Bool = true,
        enableClustering: Bool = true,
        clusterTopN: Int = 12,
        clusterMaxRankGap: Int = 20,
        clusterMaxDepthDelta: Int = 3,
        clusterMinTokenJaccard: Double = 0.18,
        enableDomainRules: Bool = true,
        domainRuleMode: DomainRuleMode = .rulesAsHints
    ) {
        self.preserveHTML = preserveHTML
        self.keepIframes = keepIframes
        self.keepVideos = keepVideos
        self.keepAudio = keepAudio
        self.wrapInArticleTag = wrapInArticleTag
        self.filterHiddenNodes = filterHiddenNodes

        self.enableClustering = enableClustering
        self.clusterTopN = clusterTopN
        self.clusterMaxRankGap = clusterMaxRankGap
        self.clusterMaxDepthDelta = clusterMaxDepthDelta
        self.clusterMinTokenJaccard = clusterMinTokenJaccard

        self.enableDomainRules = enableDomainRules
        self.domainRuleMode = domainRuleMode
    }
}
