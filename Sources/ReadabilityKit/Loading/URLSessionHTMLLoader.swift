//
//  URLSessionHTMLLoader.swift
//  ReadabilityKit
//
//  Created by Chris Jenkins on 16/02/2026.
//

import Foundation

/// Loads raw HTML using `URLSession` and validates the HTTP response.
public struct URLSessionHTMLLoader: URLLoading {
    private let session: URLSession

    /// Creates a URL-session-backed HTML loader.
    /// - Parameter session: The `URLSession` used to request page content.
    public init(session: URLSession = .shared) {
        self.session = session
    }

    /// Fetches HTML over HTTP and validates status code and string decoding.
    /// - Parameters:
    ///   - url: The page URL to request.
    ///   - userAgent: An optional custom user agent string to send with the request.
    /// - Returns: Decoded HTML from the response body.
    /// - Throws: `ReadabilityError.invalidResponse`, `ReadabilityError.httpStatus(_:)`,
    ///   `ReadabilityError.decodingFailed`, or `ReadabilityError.emptyHTML`.
    public func fetchHTML(url: URL, userAgent: String?) async throws -> String {
        var request = URLRequest(url: url.strippingTrackingQueryParameters())
        request.setValue(userAgent ?? LoadingRequestDefaults.userAgent, forHTTPHeaderField: "User-Agent")
        request.setValue(LoadingRequestDefaults.acceptHeader, forHTTPHeaderField: "Accept")

        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else { throw ReadabilityError.invalidResponse }
        guard (200..<300).contains(http.statusCode) else { throw ReadabilityError.httpStatus(http.statusCode) }

        let html =
            String(data: data, encoding: .utf8)
            ?? String(data: data, encoding: .isoLatin1)
        guard let html else { throw ReadabilityError.decodingFailed }

        let trimmed = html.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { throw ReadabilityError.emptyHTML }
        return html
    }
}
