//
//  ReadabilityError.swift
//  ReadabilityKit
//
//  Created by Chris Jenkins on 15/02/2026.
//

import Foundation

/// Enumerates known failure modes during loading, parsing, and extraction.
public enum ReadabilityError: Error, Sendable, Equatable {
    case invalidResponse
    case httpStatus(Int)
    case decodingFailed
    case emptyHTML
    case parseFailed
    case noContentCandidatesFound
    case extractedContentTooShort(actualCount: Int, minimumCount: Int)
}
