//
//  RemoveFormsButtonsEtcPass.swift
//  ReadabilityKit
//
//  Created by Chris Jenkins on 16/02/2026.
//

import Foundation
import SwiftSoup

/// Removes interactive page chrome that should not appear in extracted article output.
struct RemoveFormsButtonsEtcPass: ElementCleaningPass {
    func apply(to target: Element, options _: ExtractionOptions) throws {
        for sel in ["form", "button", "input", "select", "textarea", "nav", "footer", "header", "aside"] {
            for el in try target.select(sel).array() { try el.remove() }
        }
    }
}
