//
//  CleanTablesPass.swift
//  ReadabilityKit
//
//  Created by Chris Jenkins on 16/02/2026.
//

import Foundation
import SwiftSoup

/// Converts layout tables to semantic containers while preserving data tables.
struct CleanTablesPass: ElementCleaningPass {
    func apply(to target: Element, options _: ExtractionOptions) throws {
        for table in try target.select("table").array() {
            if try isDataTable(table) { continue }
            try unwrapLayoutTable(table)
        }
    }

    private func isDataTable(_ table: Element) throws -> Bool {
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

        let numericCells =
            try cells.filter {
                try $0.text().range(of: #"^\s*[\d,.%]+\s*$"#, options: .regularExpression) != nil
            }
            .count
        if Double(numericCells) / Double(cells.count) > 0.3 { return true }

        return false
    }

    private func unwrapLayoutTable(_ table: Element) throws {
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
