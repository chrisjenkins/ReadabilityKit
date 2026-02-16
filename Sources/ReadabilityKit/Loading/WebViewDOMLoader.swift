//
//  WebViewDOMLoader.swift
//  ReadabilityKit
//
//  Created by Chris Jenkins on 16/02/2026.
//

#if canImport(WebKit) && !os(watchOS)
import Foundation
import WebKit

/// Loads rendered DOM HTML by navigating a `WKWebView` and evaluating JavaScript.
@MainActor
public struct WebViewDOMLoader: URLLoading {
    /// Creates a web-view-backed HTML loader.
    public init() {}

    /// Loads the URL in `WKWebView` and returns the rendered DOM (`document.documentElement.outerHTML`).
    /// - Parameter url: The page URL to load.
    /// - Returns: The post-load DOM HTML string captured from JavaScript.
    /// - Throws: A navigation error, `ReadabilityError.httpStatus(_:)`,
    ///   `ReadabilityError.decodingFailed`, or `ReadabilityError.emptyHTML`.
    public func fetchHTML(url: URL) async throws -> String {
        let config = WKWebViewConfiguration()
        config.websiteDataStore = .nonPersistent()
        let webView = WKWebView(frame: .zero, configuration: config)
        let delegate = NavigationDelegate()
        webView.navigationDelegate = delegate

        try await delegate.awaitLoad(in: webView, url: url)

        let result = try await webView.evaluateJavaScript("document.documentElement.outerHTML")
        guard let html = result as? String else { throw ReadabilityError.decodingFailed }

        let trimmed = html.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { throw ReadabilityError.emptyHTML }
        return html
    }
}

/// Bridges `WKNavigationDelegate` callbacks into a single async load completion.
@MainActor
private final class NavigationDelegate: NSObject, WKNavigationDelegate {
    private var continuation: CheckedContinuation<Void, Error>?
    private var hasResolved = false

    func awaitLoad(in webView: WKWebView, url: URL) async throws {
        var request = URLRequest(url: url)
        request.setValue("ReadabilityKit/1.0 (+https://example.invalid)", forHTTPHeaderField: "User-Agent")
        request.setValue("text/html,application/xhtml+xml", forHTTPHeaderField: "Accept")

        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            self.continuation = continuation
            self.hasResolved = false
            webView.load(request)
        }
    }

    private func finish(with result: Result<Void, Error>) {
        guard !hasResolved, let continuation else { return }
        hasResolved = true
        self.continuation = nil
        continuation.resume(with: result)
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        finish(with: .success(()))
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        finish(with: .failure(error))
    }

    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        finish(with: .failure(error))
    }

    func webView(
        _ webView: WKWebView,
        decidePolicyFor navigationResponse: WKNavigationResponse,
        decisionHandler: @escaping (WKNavigationResponsePolicy) -> Void
    ) {
        if let http = navigationResponse.response as? HTTPURLResponse,
            !(200..<300).contains(http.statusCode)
        {
            decisionHandler(.cancel)
            finish(with: .failure(ReadabilityError.httpStatus(http.statusCode)))
            return
        }

        decisionHandler(.allow)
    }
}
#endif
