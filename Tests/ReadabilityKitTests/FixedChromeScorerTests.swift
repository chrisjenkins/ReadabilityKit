//
//  FixedChromeScorerTests.swift
//  ReadabilityKit
//

import Testing
import SwiftSoup
import Foundation

@testable import ReadabilityKit

@Suite("FixedChromeScorerTests")
struct FixedChromeScorerTests {
    private let scorer = FixedChromeScorer()

    @Test("Penalizes fixed top bars")
    func penalizesFixedTopBars() throws {
        let element = try makeElement(
            id: "global-nav",
            className: "site-header navbar",
            style: "position:fixed; top:0; left:0; right:0; height:64px;",
            innerHTML: """
                <a href="/home">Home</a><a href="/news">News</a><a href="/world">World</a><a href="/opinion">Opinion</a>
                """
        )

        let score = try scorer.score(element)
        #expect(score <= -70)
    }

    @Test("Penalizes sticky side rails")
    func penalizesStickySideRails() throws {
        let element = try makeElement(
            id: "right-rail",
            className: "sidebar-rail floating",
            style: "position:sticky; top:20px; max-height:120px;",
            innerHTML: "<a href=\"/1\">One</a><a href=\"/2\">Two</a><a href=\"/3\">Three</a>"
        )

        let score = try scorer.score(element)
        #expect(score <= -50)
    }

    @Test("Caps penalty for likely content containers")
    func capsPenaltyForLikelyContentContainers() throws {
        let element = try makeElement(
            id: "article-content",
            className: "story content",
            style: "position:sticky; top:0; left:0; right:0; height:100px;",
            innerHTML: """
                <p>This paragraph contains enough words to represent real article narrative content in the extraction pipeline.</p>
                <p>A second paragraph keeps the block content-heavy and should trigger the safeguard for likely true content.</p>
                <p>A third paragraph confirms this is not a chrome-only block despite sticky positioning in some layouts.</p>
                """
        )

        let score = try scorer.score(element)
        #expect(score >= -20)
    }

    @Test("Does not penalize normal content blocks")
    func doesNotPenalizeNormalContentBlocks() throws {
        let element = try makeElement(
            id: "main-story",
            className: "article-body content",
            style: "",
            innerHTML: """
                <p>This is standard article content with no sticky or fixed chrome signals.</p>
                <p>It should not receive a fixed-chrome penalty.</p>
                """
        )

        let score = try scorer.score(element)
        #expect(score == 0)
    }

    @Test("Extractor deprioritizes sticky nav over article body")
    func extractorDeprioritizesStickyNav() throws {
        let html = """
            <html>
              <head><title>Sticky Nav Fixture</title></head>
              <body>
                <div id="global-nav" class="site-header nav-bar" style="position:fixed; top:0; left:0; right:0; height:56px;">
                  <a href="/home">Home</a> <a href="/world">World</a> <a href="/markets">Markets</a> <a href="/sports">Sports</a>
                </div>
                <article class="article-body content">
                  <h1>Main Story Headline</h1>
                  <p>This story paragraph includes enough descriptive prose and punctuation to satisfy extraction heuristics.</p>
                  <p>Another paragraph reinforces that this block is the true content root rather than persistent navigation chrome.</p>
                  <p>Final paragraph ensures candidate scoring has sufficient body text to rank this article highest.</p>
                </article>
              </body>
            </html>
            """

        let extractor = ReadabilityExtractor()
        let article = try extractor.extract(fromHTML: html, url: URL(string: "https://example.com/sticky-nav")!)

        #expect(article.textContent.contains("Main Story Headline"))
        #expect(article.textContent.contains("true content root"))
        #expect(!article.textContent.contains("Home World Markets Sports"))
    }

    private func makeElement(
        id: String,
        className: String,
        style: String,
        innerHTML: String
    ) throws -> Element {
        let html = "<div id=\"\(id)\" class=\"\(className)\" style=\"\(style)\">\(innerHTML)</div>"
        let doc = try SwiftSoup.parse(html)
        return try doc.select("div").first()!
    }
}
