import Foundation
import Testing

@testable import ReadabilityKit

@Suite("Article containers")
struct DaringFireballRegressionTests {
    @Test("Keeps the complete article in a plain div container")
    func article() throws {
        let html = try fixture("daringfireball-article")
        let article = try ReadabilityExtractor().extract(
            fromHTML: html,
            url: URL(string: "https://daringfireball.net/2026/09/ill_wait")!
        )

        #expect(article.textContent.contains("One of my favorite teachers in high school"))
        #expect(article.textContent.contains("It’s not really an analogous situation"))
        #expect(!article.contentHTML.contains("/graphics/logos/"))
    }

    @Test("Keeps linked-post body inside a definition list")
    func linkedPost() throws {
        let html = try fixture("daringfireball-linked")
        let article = try ReadabilityExtractor().extract(
            fromHTML: html,
            url: URL(string: "https://daringfireball.net/linked/2026/09/06/meta-ai-mac-app")!
        )

        #expect(article.textContent.contains("Zac Hall, writing for 9to5Mac"))
        #expect(article.textContent.contains("Passes the Settings window sniff test"))
        #expect(article.textContent.contains("The Mac app is not available"))
        #expect(!article.contentHTML.contains("<dl"))
        #expect(article.contentHTML.contains("<blockquote"))
        #expect(!article.contentHTML.contains("/graphics/logos/"))
    }

    @Test("Leaves multi-entry and short definition lists intact")
    func definitionLists() throws {
        let html = """
        <html><head><title>Terminology</title></head><body><article>
        <p>This article introduces terms before the definitions and provides enough narrative to identify the content.</p>
        <dl><dt>First</dt><dd><p>A short definition.</p></dd></dl>
        <dl><dt>Second</dt><dd><p>A longer definition that discusses a term in prose and continues for more than eighty characters.</p>
        </dd><dt>Third</dt><dd><p>Another definition.</p></dd></dl>
        </article></body></html>
        """
        let article = try ReadabilityExtractor().extract(
            fromHTML: html,
            url: URL(string: "https://example.com/terminology")!
        )

        #expect(article.contentHTML.contains("<dl"))
        #expect(article.textContent.contains("A short definition"))
        #expect(article.textContent.contains("Another definition"))
    }

    @Test("Converts a short linked definition-list article")
    func shortLinkedArticle() throws {
        let html = """
        <html><head><title>Short linked article</title></head><body>
        <dl><dt><a href="https://example.com/story">A linked story</a></dt>
        <dd><p>This short commentary still contains enough prose to form a useful article body for reading.</p></dd>
        </dl></body></html>
        """
        let article = try ReadabilityExtractor().extract(
            fromHTML: html,
            url: URL(string: "https://example.com/short-linked-article")!
        )

        #expect(!article.contentHTML.contains("<dl"))
        #expect(article.textContent.contains("This short commentary"))
    }

    private func fixture(_ name: String) throws -> String {
        let url = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .appendingPathComponent("Resources")
            .appendingPathComponent("\(name).html")
        return try String(contentsOf: url, encoding: .utf8)
    }
}
