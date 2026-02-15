//
//  ReadableError.swift
//  ReadableSwift
//
//  Created by Chris Jenkins on 15/02/2026.
//


import Foundation

public enum ReadableError: Error, Sendable {
    case invalidResponse
    case httpStatus(Int)
    case decodingFailed
    case emptyHTML
    case parseFailed
    case noReadableContent
}