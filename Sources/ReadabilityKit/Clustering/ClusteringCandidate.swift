//
//  ClusteringCandidate.swift
//  ReadabilityKit
//
//  Created by Chris Jenkins on 16/02/2026.
//

import Foundation
import SwiftSoup

/// Captures per-node signals used to rank and cluster readable content blocks.
struct ClusteringCandidate {
    let path: String
    let orderIndex: Int
    let depth: Int
    let score: Double
    let tokens: Set<String>
    let element: Element
}
