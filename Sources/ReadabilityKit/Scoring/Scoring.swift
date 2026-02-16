//
//  Scoring.swift
//  ReadabilityKit
//
//  Created by Chris Jenkins on 15/02/2026.
//

import Foundation
import SwiftSoup

/// Defines a scoring strategy that produces a numeric signal from a DOM element.
protocol ElementScorer {
    func score(_ element: Element) throws -> Double
}
