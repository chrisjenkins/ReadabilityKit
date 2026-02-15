//
//  ReadabilityExtractorTests.swift
//  ReadableSwift
//
//  Created by Chris Jenkins on 15/02/2026.
//


import XCTest
@testable import ReadableSwift

final class ReadabilityExtractorTests: XCTestCase {

    func testExtractFromHTML_basic() throws {
        let html = """
        <html><head>
          <title>Example</title>
          <meta name="author" content="Chris">
          <meta name="description" content="An example article.">
        </head>
        <body>
          <header>Nav <a href="/">Home</a></header>

          <div class="content article-body">
            <h1>Hello World</h1>
            <p>This is a real paragraph with enough text to be considered content, and it has commas, too.</p>
            <p>Another paragraph follows with more narrative text so the extractor has something to score properly.</p>

            <table role="presentation"><tr><td>
              <div>Layout table wrapper</div>
              <p>More article text inside a layout table.</p>
            </td></tr></table>

            <table>
              <caption>Data</caption>
              <tr><th>A</th><th>B</th><th>C</th></tr>
              <tr><td>1</td><td>2</td><td>3</td></tr>
              <tr><td>4</td><td>5</td><td>6</td></tr>
            </table>
          </div>

          <div class="share">Share buttons</div>
          <footer>Footer junk</footer>
        </body></html>
        """

        let extractor = ReadabilityExtractor(options: .init(enableClustering: true))
        let article = try extractor.extract(fromHTML: html, url: URL(string: "https://example.com/post")!)

        XCTAssertTrue(article.title.contains("Example") || article.title.contains("Hello World"))
        XCTAssertEqual(article.byline, "Chris")
        XCTAssertTrue(article.textContent.contains("real paragraph"))
        XCTAssertFalse(article.textContent.lowercased().contains("footer junk"))
        XCTAssertFalse(article.textContent.lowercased().contains("share buttons"))

        // Data table caption should remain
        XCTAssertTrue(article.contentHTML.contains("caption"))
    }
}