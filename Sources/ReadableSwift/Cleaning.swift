//
//  Cleaning.swift
//  ReadableSwift
//
//  Created by Chris Jenkins on 15/02/2026.
//


import Foundation
import SwiftSoup

enum Cleaning {

    static let unlikelyPatterns: [String] = [
        "comment","meta","footer","foot","masthead","sidebar","sponsor","promo",
        "related","outbrain","taboola","ad-","ads","advert","cookie","subscribe",
        "newsletter","nav","share","social","breadcrumbs","recommend"
    ]

    static let positivePatterns: [String] = [
        "article","content","entry","main","page","post","text","body","story"
    ]

    static func removeScriptsStylesAndUnsafe(_ doc: Document, options: ExtractionOptions) throws {
        for sel in ["script","style","noscript"] {
            for el in try doc.select(sel).array() { try el.remove() }
        }
        if !options.keepIframes {
            for el in try doc.select("iframe").array() { try el.remove() }
        }
        if !options.keepVideos {
            for el in try doc.select("video, source").array() { try el.remove() }
        }
        if !options.keepAudio {
            for el in try doc.select("audio, source").array() { try el.remove() }
        }
    }

    static func normalizeBreaks(_ doc: Document) throws {
        guard let body = doc.body() else { return }
        let html = try body.html()
            .replacingOccurrences(of: "<br>\\s*<br>", with: "</p><p>", options: .regularExpression)
            .replacingOccurrences(of: "<br/>\\s*<br/>", with: "</p><p>", options: .regularExpression)
            .replacingOccurrences(of: "<br\\s*/?>\\s*<br\\s*/?>", with: "</p><p>", options: .regularExpression)
        try body.html(html)
    }

    static func removeUnlikelyCandidates(_ doc: Document) throws {
        for el in try doc.select("*").array() {
            let idClass = (try el.id() + " " + el.className()).lowercased()
            if unlikelyPatterns.contains(where: { idClass.contains($0) }) {
                if positivePatterns.contains(where: { idClass.contains($0) }) { continue }
                try el.remove()
            }
        }
    }

    static func removeFormsButtonsEtc(_ element: Element) throws {
        for sel in ["form","button","input","select","textarea","nav","footer","header","aside"] {
            for el in try element.select(sel).array() { try el.remove() }
        }
    }

    static func removeLikelyJunkBlocks(_ element: Element) throws {
        let selectors = [
            "[class*=share]","[id*=share]",
            "[class*=social]","[id*=social]",
            "[class*=newsletter]","[id*=newsletter]",
            "[class*=subscribe]","[id*=subscribe]",
            "[class*=cookie]","[id*=cookie]",
            "[class*=banner]","[id*=banner]",
            "[class*=promo]","[id*=promo]",
            "[class*=related]","[id*=related]",
            "[class*=recommend]","[id*=recommend]"
        ]
        for sel in selectors {
            for el in try element.select(sel).array() { try el.remove() }
        }
    }

    static func stripEmptyParagraphs(_ element: Element) throws {
        for p in try element.select("p").array() {
            let text = try p.text().trimmingCharacters(in: .whitespacesAndNewlines)
            if text.isEmpty { try p.remove() }
        }
    }

    static func fixLazyMedia(_ element: Element) throws {
        // Images
        for img in try element.select("img").array() {
            let candidates = ["data-src","data-original","data-lazy-src","data-url","data-img"]
            if (try img.attr("src")).isEmpty {
                for attr in candidates {
                    let v = try img.attr(attr)
                    if !v.isEmpty { try img.attr("src", v); break }
                }
            }
            if (try img.attr("srcset")).isEmpty {
                let ss = try img.attr("data-srcset")
                if !ss.isEmpty { try img.attr("srcset", ss) }
            }

            let w = Int(try img.attr("width")) ?? 0
            let h = Int(try img.attr("height")) ?? 0
            if w == 1 && h == 1 { try img.remove() }
        }

        // Videos: poster
        for v in try element.select("video").array() {
            if (try v.attr("poster")).isEmpty {
                let p = try v.attr("data-poster")
                if !p.isEmpty { try v.attr("poster", p) }
            }
        }
    }

    static func unwrapRedundantSpansAndDivs(_ element: Element) throws {
        let unwrapTags: Set<String> = ["span","div"]
        for el in try element.select("div, span").array() {
            let tag = el.tagName().lowercased()
            guard unwrapTags.contains(tag) else { continue }

            let hasAttributes = !(el.getAttributes()?.asList().isEmpty == true)
            if hasAttributes { continue }

            let hasBlocks = (try el.select("p,ul,ol,li,blockquote,pre,code,figure,table,h1,h2,h3,h4,h5,h6").size()) > 0
            if hasBlocks { continue }

            try el.unwrap()
        }
    }

    // MARK: - Table/layout kill switch

    static func cleanTables(_ root: Element) throws {
        for table in try root.select("table").array() {
            if try isDataTable(table) { continue }
            try unwrapLayoutTable(table)
        }
    }

    private static func isDataTable(_ table: Element) throws -> Bool {
        if try table.select("th").size() > 0 { return true }
        if try table.select("caption").size() > 0 { return true }

        let role = try table.attr("role").lowercased()
        if role == "grid" || role == "table" { return true }

        let rows = try table.select("tr").array()
        if rows.count >= 3 {
            let columnCounts = try rows.map { try $0.select("td, th").size() }
            if let maxCols = columnCounts.max(), maxCols >= 3 { return true }
        }

        let cells = try table.select("td, th").array()
        guard !cells.isEmpty else { return false }

        let totalText = try cells.reduce(0) { $0 + (try $1.text().count) }
        let avgText = totalText / cells.count
        if avgText > 20 { return true }

        let numericCells = try cells.filter {
            try $0.text().range(of: #"^\s*[\d,.%]+\s*$"#, options: .regularExpression) != nil
        }.count
        if Double(numericCells) / Double(cells.count) > 0.3 { return true }

        return false
    }

    private static func unwrapLayoutTable(_ table: Element) throws {
        let replacement = Element(Tag("div"), table.getBaseUri())
        try replacement.addClass("readableswift-table-unwrapped")

        for row in try table.select("tr").array() {
            for cell in try row.select("td, th").array() {
                let text = try cell.text().trimmingCharacters(in: .whitespacesAndNewlines)
                let hasMedia = (try cell.select("img, picture, figure, video, audio").size()) > 0
                if text.isEmpty && !hasMedia { continue }

                for child in cell.getChildNodes() {
                    try replacement.appendChild(child)
                }
            }
        }

        try table.replaceWith(replacement)
    }
}
