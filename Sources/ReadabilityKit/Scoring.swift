//
//  Scoring.swift
//  ReadabilityKit
//
//  Created by Chris Jenkins on 15/02/2026.
//


import Foundation
import SwiftSoup

enum Scoring {

    static func classWeight(_ el: Element) throws -> Double {
        let idClass = (try el.id() + " " + el.className()).lowercased()
        var weight = 0.0

        let negatives = ["comment","meta","footer","foot","sidebar","sponsor","promo","ad","ads","advert","nav","share","social","cookie","subscribe","newsletter","recommend","related"]
        if negatives.contains(where: { idClass.contains($0) }) { weight -= 25 }

        let positives = ["article","content","entry","main","page","post","text","body","story"]
        if positives.contains(where: { idClass.contains($0) }) { weight += 25 }

        return weight
    }

    static func linkDensity(_ el: Element) throws -> Double {
        let text = try el.text()
        let textCount = max(1, text.count)
        let linkText = try el.select("a").text().count
        return Double(linkText) / Double(textCount)
    }

    static func scoreParagraph(_ p: Element) throws -> Double {
        let text = try p.text().trimmingCharacters(in: .whitespacesAndNewlines)
        let len = text.count
        guard len >= 25 else { return 0 }

        var score = 0.0
        score += 1.0
        score += Double(text.filter { $0 == "," }.count)
        score += min(3.0, Double(len) / 100.0)

        let ld = try linkDensity(p)
        score *= (1.0 - min(0.8, ld))

        let tag = p.tagName().lowercased()
        if tag == "p" || tag == "blockquote" || tag == "pre" || tag == "td" {
            score += 2.0
        }

        return score
    }
}