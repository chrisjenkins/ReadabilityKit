//
//  ObamawhitehouseArchivesGovCustomDomainExtractionRule.swift
//  ReadabilityKit
//
//  Auto-generated from Tests/ReadabilityKitTests/Custom/obamawhitehouse.archives.gov/index.js
//

import Foundation
import SwiftSoup

struct ObamawhitehouseArchivesGovCustomDomainExtractionRule: DomainExtractionRule {
    let id = "custom_obamawhitehouse_archives_gov"

    func matches(url: URL) -> Bool {
        CustomDomainRuleSupport.matches(url: url, domain: "obamawhitehouse.archives.gov")
    }

    func preferredContentRoot(in doc: Document) throws -> Element? {
        let selectors: [String] =
        [
            "div#content-start",
            ".pane-node-field-forall-body",
        ]

        return try CustomDomainRuleSupport.firstMatchingElement(in: doc, selectors: selectors)
    }

    func candidateScoreAdjustments(in doc: Document) throws -> [DomainCandidateAdjustment] {
        let positiveSignals: [(selector: String, delta: Double)] = [
            (selector: "div#content-start", delta: 140.0),
            (selector: ".pane-node-field-forall-body", delta: 140.0),
            (selector: "h1", delta: 20.0),
            (selector: ".pane-node-title", delta: 20.0),
            (selector: ".blog-author-link", delta: 8.0),
            (selector: ".node-person-name-link", delta: 8.0),
        ]

        let negativeSignals: [(selector: String, delta: Double)] = [
            (selector: "header", delta: -70.0),
            (selector: "nav", delta: -70.0),
            (selector: "aside", delta: -55.0),
            (selector: "footer", delta: -80.0),
            (selector: ".pane-node-title", delta: -120.0),
            (selector: ".pane-custom.pane-1", delta: -120.0),
        ]

        return try CustomDomainRuleSupport.candidateScoreAdjustments(
            in: doc,
            positiveSignals: positiveSignals,
            negativeSignals: negativeSignals,
        )
    }

    func metadataOverrides(in doc: Document, fallbackURL: URL) throws -> DomainMetadataOverride {
        let titleSelectors: [String] =
        [
            "h1",
            ".pane-node-title",
        ]
        let authorSelectors: [String] =
        [
            ".blog-author-link",
            ".node-person-name-link",
        ]
        let excerptSelectors: [String] =
        [
        ]
        let leadImageSelectors: [String] =
        [
            "meta[name=\"og:image\"]",
        ]

        return try CustomDomainRuleSupport.metadataOverrides(
            in: doc,
            fallbackURL: fallbackURL,
            titleSelectors: titleSelectors,
            authorSelectors: authorSelectors,
            excerptSelectors: excerptSelectors,
            leadImageSelectors: leadImageSelectors,
        )
    }
}
