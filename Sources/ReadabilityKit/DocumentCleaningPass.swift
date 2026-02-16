//
//  DocumentCleaningPass.swift
//  ReadabilityKit
//
//  Created by Chris Jenkins on 16/02/2026.
//

import Foundation
import SwiftSoup

/// Defines a cleanup pass that mutates a whole HTML document.
protocol DocumentCleaningPass: CleaningPass where Target == Document {}
