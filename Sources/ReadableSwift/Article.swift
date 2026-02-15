//
//  Article.swift
//  ReadableSwift
//
//  Created by Chris Jenkins on 15/02/2026.
//


import Foundation

public struct Article: Sendable {
    public let url: URL
    public let title: String
    public let byline: String?
    public let excerpt: String?
    public let contentHTML: String
    public let textContent: String

    public init(
        url: URL,
        title: String,
        byline: String?,
        excerpt: String?,
        contentHTML: String,
        textContent: String
    ) {
        self.url = url
        self.title = title
        self.byline = byline
        self.excerpt = excerpt
        self.contentHTML = contentHTML
        self.textContent = textContent
    }
}