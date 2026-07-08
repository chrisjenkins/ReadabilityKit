//
//  URLTrackingParameterSanitizer.swift
//  ReadabilityKit
//
//  Created by Chris Jenkins on 08/07/2026.
//

import Foundation

enum URLTrackingParameterSanitizer {
    private static let trackedParameterNames: Set<String> = [
        "fbclid",
        "gclid",
        "dclid",
        "gbraid",
        "wbraid",
        "mc_cid",
        "mc_eid",
        "mkt_tok",
        "igshid",
        "s_cid",
        "vero_conv",
        "vero_id",
        "yclid",
    ]

    private static let trackedParameterPrefixes = [
        "utm_",
        "at_",
    ]

    static func sanitized(_ url: URL) -> URL {
        guard var components = URLComponents(url: url, resolvingAgainstBaseURL: false),
            let queryItems = components.percentEncodedQueryItems,
            !queryItems.isEmpty
        else {
            return url
        }

        let filteredItems = queryItems.filter { item in
            !isTrackingParameter(named: item.name)
        }

        guard filteredItems.count != queryItems.count else { return url }
        components.percentEncodedQueryItems = filteredItems.isEmpty ? nil : filteredItems
        return components.url ?? url
    }

    private static func isTrackingParameter(named name: String) -> Bool {
        let normalized = name.lowercased()
        if trackedParameterNames.contains(normalized) {
            return true
        }

        return trackedParameterPrefixes.contains(where: normalized.hasPrefix)
    }
}

extension URL {
    func strippingTrackingQueryParameters() -> URL {
        URLTrackingParameterSanitizer.sanitized(self)
    }
}
