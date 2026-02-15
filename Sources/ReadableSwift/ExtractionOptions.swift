//
//  ExtractionOptions.swift
//  ReadableSwift
//
//  Created by Chris Jenkins on 15/02/2026.
//


import Foundation

public struct ExtractionOptions: Sendable {
    public var preserveHTML: Bool
    public var keepIframes: Bool
    public var keepVideos: Bool
    public var keepAudio: Bool
    public var wrapInArticleTag: Bool

    public var enableClustering: Bool
    public var clusterTopN: Int
    public var clusterMaxRankGap: Int
    public var clusterMaxDepthDelta: Int
    public var clusterMinTokenJaccard: Double

    public init(
        preserveHTML: Bool = true,
        keepIframes: Bool = false,
        keepVideos: Bool = true,
        keepAudio: Bool = true,
        wrapInArticleTag: Bool = true,
        enableClustering: Bool = true,
        clusterTopN: Int = 12,
        clusterMaxRankGap: Int = 20,
        clusterMaxDepthDelta: Int = 3,
        clusterMinTokenJaccard: Double = 0.18
    ) {
        self.preserveHTML = preserveHTML
        self.keepIframes = keepIframes
        self.keepVideos = keepVideos
        self.keepAudio = keepAudio
        self.wrapInArticleTag = wrapInArticleTag

        self.enableClustering = enableClustering
        self.clusterTopN = clusterTopN
        self.clusterMaxRankGap = clusterMaxRankGap
        self.clusterMaxDepthDelta = clusterMaxDepthDelta
        self.clusterMinTokenJaccard = clusterMinTokenJaccard
    }
}