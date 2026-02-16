//
//  Article.swift
//  ReadabilityKit
//
//  Created by Chris Jenkins on 15/02/2026.
//

import Foundation

/// Represents the extracted readable article content and metadata for a source URL.
public struct Article: Sendable {
    public let url: URL
    public let title: String
    public let byline: String?
    public let excerpt: String?
    public let contentHTML: String
    public let textContent: String
    public let leadImageURL: URL?

    /// Creates an extracted article value from parsed readability output.
    /// - Parameters:
    ///   - url: Source URL the content came from.
    ///   - title: Resolved article title from metadata/headings.
    ///   - byline: Optional author/byline text.
    ///   - excerpt: Optional summary/description.
    ///   - contentHTML: Cleaned article HTML body.
    ///   - textContent: Plain-text representation of `contentHTML`.
    ///   - leadImageURL: Lead image URL resolved from metadata or content heuristics.
    public init(
        url: URL,
        title: String,
        byline: String?,
        excerpt: String?,
        contentHTML: String,
        textContent: String,
        leadImageURL: URL?
    ) {
        self.url = url
        self.title = title
        self.byline = byline
        self.excerpt = excerpt
        self.contentHTML = contentHTML
        self.textContent = textContent
        self.leadImageURL = leadImageURL
    }
}
