//
//  URLLoading.swift
//  ReadabilityKit
//
//  Created by Chris Jenkins on 15/02/2026.
//

import Foundation

enum LoadingRequestDefaults {
    static let userAgent = "ReadabilityKit/1.0 (+https://example.invalid)"
    static let acceptHeader = "text/html,application/xhtml+xml"
}

/// Defines an asynchronous HTML loading strategy for a URL.
public protocol URLLoading: Sendable {
    /// Loads HTML for the given URL so it can be parsed by `ReadabilityExtractor`.
    /// - Parameters:
    ///   - url: The page URL to load.
    ///   - userAgent: An optional custom user agent string to send with the request.
    /// - Returns: The HTML string that should be parsed for readability extraction.
    /// - Throws: A `ReadabilityError` or transport/runtime error when loading fails.
    func fetchHTML(url: URL, userAgent: String?) async throws -> String
}

public extension URLLoading {
    /// Loads HTML using the loader's default request headers.
    /// - Parameter url: The page URL to load.
    /// - Returns: The HTML string that should be parsed for readability extraction.
    /// - Throws: A `ReadabilityError` or transport/runtime error when loading fails.
    func fetchHTML(url: URL) async throws -> String {
        try await fetchHTML(url: url, userAgent: nil)
    }
}
