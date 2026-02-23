//
//  ClassWeightScorerTests.swift
//  ReadabilityKit
//

import Testing
import SwiftSoup

@testable import ReadabilityKit

@Suite("ClassWeightScorerTests")
struct ClassWeightScorerTests {
    private let scorer = ClassWeightScorer()

    @Test("Does not penalize ad substring inside adapter")
    func doesNotPenalizeAdapterSubstring() throws {
        let element = try makeElement(id: "", className: "adapter-shell")
        let score = try scorer.score(element)
        #expect(score == 0)
    }

    @Test("Strongly boosts article body classes and id")
    func boostsArticleBodySignals() throws {
        let element = try makeElement(id: "main-article", className: "article-body entry-content")
        let score = try scorer.score(element)
        #expect(score >= 40)
    }

    @Test("Strongly penalizes related sidebar containers")
    func penalizesRelatedSidebar() throws {
        let element = try makeElement(id: "related-stories", className: "sidebar")
        let score = try scorer.score(element)
        #expect(score <= -40)
    }

    @Test("Avoids heavy unlikely penalty when content-like tokens are present")
    func avoidsUnlikelyPenaltyForMaybeCandidate() throws {
        let element = try makeElement(id: "commentary", className: "article-body")
        let score = try scorer.score(element)
        #expect(score >= -10)
    }

    @Test("Strongly penalizes nav share social chrome")
    func penalizesNavShareSocial() throws {
        let element = try makeElement(id: "", className: "top-nav share social")
        let score = try scorer.score(element)
        #expect(score <= -40)
    }

    private func makeElement(id: String, className: String) throws -> Element {
        let html = "<div id=\"\(id)\" class=\"\(className)\"></div>"
        let doc = try SwiftSoup.parse(html)
        return try doc.select("div").first()!
    }
}
