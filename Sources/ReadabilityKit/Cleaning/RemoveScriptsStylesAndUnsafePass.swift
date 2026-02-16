//
//  RemoveScriptsStylesAndUnsafePass.swift
//  ReadabilityKit
//
//  Created by Chris Jenkins on 16/02/2026.
//

import Foundation
import SwiftSoup

/// Removes unsafe or unwanted media/script tags according to extraction options.
struct RemoveScriptsStylesAndUnsafePass: DocumentCleaningPass {
    func apply(to target: Document, options: ExtractionOptions) throws {
        for sel in ["script", "style", "noscript"] {
            for el in try target.select(sel).array() { try el.remove() }
        }
        if !options.keepIframes {
            for el in try target.select("iframe").array() { try el.remove() }
        }
        if !options.keepVideos {
            for el in try target.select("video, source").array() { try el.remove() }
        }
        if !options.keepAudio {
            for el in try target.select("audio, source").array() { try el.remove() }
        }
    }
}
