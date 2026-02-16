//
//  URLLoading.swift
//  ReadabilityKit
//
//  Created by Chris Jenkins on 15/02/2026.
//

import Foundation

/// Defines an asynchronous HTML loading strategy for a URL.
public protocol URLLoading: Sendable {
    /// Loads HTML for the given URL so it can be parsed by `ReadabilityExtractor`.
    /// - Parameter url: The page URL to load.
    /// - Returns: The HTML string that should be parsed for readability extraction.
    /// - Throws: A `ReadabilityError` or transport/runtime error when loading fails.
    func fetchHTML(url: URL) async throws -> String
}
