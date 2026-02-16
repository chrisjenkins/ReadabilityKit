//
//  CleaningPass.swift
//  ReadabilityKit
//
//  Created by Chris Jenkins on 16/02/2026.
//

import Foundation
import SwiftSoup

/// Defines a reusable cleanup pass interface over a target DOM type.
protocol CleaningPass {
    associatedtype Target
    func apply(to target: Target, options: ExtractionOptions) throws
}
