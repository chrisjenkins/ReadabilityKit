import Foundation
import Testing

@testable import ReadabilityKit

@Suite("URLSessionHTMLLoaderTests")
struct URLSessionHTMLLoaderTests {
    @Test("Recognizes Cloudflare challenge responses")
    func fetchHTML_cloudflareChallenge_throwsTypedError() async {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [CloudflareChallengeURLProtocol.self]
        let loader = URLSessionHTMLLoader(session: URLSession(configuration: configuration))
        let url = URL(string: "https://example.com/article")!

        do {
            _ = try await loader.fetchHTML(url: url, userAgent: nil)
            Issue.record("Expected the Cloudflare challenge response to fail")
        } catch let error as ReadabilityError {
            #expect(error == .cloudflareChallenge)
        } catch {
            Issue.record("Unexpected error: \(error)")
        }
    }
}

private final class CloudflareChallengeURLProtocol: URLProtocol {
    override class func canInit(with request: URLRequest) -> Bool {
        request.url?.host == "example.com"
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        request
    }

    override func startLoading() {
        guard let url = request.url,
            let response = HTTPURLResponse(
                url: url,
                statusCode: 403,
                httpVersion: nil,
                headerFields: ["cf-mitigated": "challenge"]
            )
        else {
            client?.urlProtocol(self, didFailWithError: URLError(.badServerResponse))
            return
        }

        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: Data("Challenge page".utf8))
        client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() {}
}
