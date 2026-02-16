//
//  URLLoading.swift
//  ReadabilityKit
//
//  Created by Chris Jenkins on 15/02/2026.
//


import Foundation

public protocol URLLoading: Sendable {
    func fetch(url: URL) async throws -> (data: Data, response: HTTPURLResponse)
}

public struct DefaultURLLoader: URLLoading {
    private let session: URLSession

    public init(session: URLSession = .shared) {
        self.session = session
    }

    public func fetch(url: URL) async throws -> (data: Data, response: HTTPURLResponse) {
        var request = URLRequest(url: url)
        request.setValue("ReadabilityKit/1.0 (+https://example.invalid)", forHTTPHeaderField: "User-Agent")
        request.setValue("text/html,application/xhtml+xml", forHTTPHeaderField: "Accept")

        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else { throw ReadableError.invalidResponse }
        guard (200..<300).contains(http.statusCode) else { throw ReadableError.httpStatus(http.statusCode) }
        return (data, http)
    }
}