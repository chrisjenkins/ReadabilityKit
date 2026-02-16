//
//  ElementCleaningPass.swift
//  ReadabilityKit
//
//  Created by Chris Jenkins on 16/02/2026.
//

import Foundation
import SwiftSoup

/// Defines a cleanup pass that mutates an extracted content root element.
protocol ElementCleaningPass: CleaningPass where Target == Element {}
