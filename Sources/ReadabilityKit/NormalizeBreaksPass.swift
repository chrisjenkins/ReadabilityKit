//
//  NormalizeBreaksPass.swift
//  ReadabilityKit
//
//  Created by Chris Jenkins on 16/02/2026.
//

import Foundation
import SwiftSoup

/// Normalizes double line breaks into paragraph boundaries for better scoring.
struct NormalizeBreaksPass: DocumentCleaningPass {
    func apply(to target: Document, options _: ExtractionOptions) throws {
        guard let body = target.body() else { return }
        let html = try body.html()
            .replacingOccurrences(of: "<br>\\s*<br>", with: "</p><p>", options: .regularExpression)
            .replacingOccurrences(of: "<br/>\\s*<br/>", with: "</p><p>", options: .regularExpression)
            .replacingOccurrences(of: "<br\\s*/?>\\s*<br\\s*/?>", with: "</p><p>", options: .regularExpression)
        try body.html(html)
    }
}
