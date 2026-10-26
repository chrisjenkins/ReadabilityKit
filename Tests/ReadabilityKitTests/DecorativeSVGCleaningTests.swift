import Foundation
import Testing

@testable import ReadabilityKit

@Suite("Decorative SVG cleanup")
struct DecorativeSVGCleaningTests {
    @Test(
        "Removes quotation SVG metadata while preserving the quoted paragraphs",
        arguments: ["double quotation mark", "single quotation mark", "quotation mark"],
    )
    func removesQuotationIcon(label: String) throws {
        let article = try extractArticle(content: """
            <blockquote>
              <p><svg viewBox="0 0 22 14" class="dcr-1usi6vc">
                <title>\(label)</title>
                <desc>Opening quote decoration</desc>
                <path d="M0 0h10v14H0z"></path>
              </svg>The speaker described the findings and explained the next steps in detail.</p>
              <p>A second quoted paragraph supplies additional context for readers.</p>
            </blockquote>
            """)

        #expect(article.contentHTML.contains("<blockquote"))
        #expect(article.textContent.contains("The speaker described the findings"))
        #expect(article.textContent.contains("A second quoted paragraph"))
        #expect(!article.contentHTML.contains("<svg"))
        #expect(!article.contentHTML.contains(label))
        #expect(!article.textContent.contains(label))
        #expect(!article.textContent.contains("Opening quote decoration"))
    }

    @Test("Preserves informative SVGs and literal references to quotation marks")
    func preservesInformativeSVG() throws {
        let article = try extractArticle(content: """
            <figure>
              <svg viewBox="0 0 640 360" role="img">
                <title>Quarterly revenue</title>
                <desc>Revenue increased during the reporting period.</desc>
                <text x="10" y="20">Revenue increased by 20 percent</text>
              </svg>
              <figcaption>The chart compares revenue across the reporting period.</figcaption>
            </figure>
            <blockquote>
              <figure>
                <svg viewBox="0 0 200 120">
                  <title>double quotation mark</title>
                  <text x="10" y="20">Unicode U+0022</text>
                </svg>
                <figcaption>An illustration of the punctuation character discussed in the passage.</figcaption>
              </figure>
              <p>The term double quotation mark names a punctuation character.</p>
            </blockquote>
            """)

        #expect(article.contentHTML.contains("<svg"))
        #expect(article.contentHTML.contains("Quarterly revenue"))
        #expect(article.contentHTML.contains("Revenue increased during the reporting period."))
        #expect(article.textContent.contains("Revenue increased by 20 percent"))
        #expect(article.contentHTML.contains("Unicode U+0022"))
        #expect(article.textContent.contains("The term double quotation mark"))
    }

    @Test("Respects the decorative image cleanup option", arguments: [true, false])
    func respectsCleanupOption(removeDecorativeImages: Bool) throws {
        let article = try extractArticle(
            content: """
                <blockquote><p><svg viewBox="0 0 22 14">
                  <title>double quotation mark</title>
                  <path d="M0 0h10v14H0z"></path>
                </svg>The quoted passage explains what the report found and why it matters.</p></blockquote>
                """,
            options: .init(removeDecorativeImages: removeDecorativeImages),
        )

        #expect(article.contentHTML.contains("<svg") == !removeDecorativeImages)
        #expect(article.textContent.contains("double quotation mark") == !removeDecorativeImages)
        #expect(article.textContent.contains("The quoted passage explains"))
    }

    @Test(
        "Removes SVGs explicitly marked as decorative",
        arguments: ["role=\"presentation\"", "role=\"none\"", "aria-hidden=\"true\""],
    )
    func removesExplicitlyDecorativeSVG(attributes: String) throws {
        let article = try extractArticle(
            content: """
                <p><svg \(attributes) viewBox="0 0 24 24">
                  <title>Decorative symbol</title>
                  <path d="M0 0h24v24H0z"></path>
                </svg>The article continues after the decorative symbol with additional context.</p>
                """,
            options: .init(filterHiddenNodes: false),
        )

        #expect(!article.contentHTML.contains("<svg"))
        #expect(!article.textContent.contains("Decorative symbol"))
        #expect(article.textContent.contains("The article continues"))
    }

    private func extractArticle(content: String, options: ExtractionOptions = .init()) throws -> Article {
        let html = """
            <html>
              <head><title>Article with SVG content</title></head>
              <body><article>
                <p>This opening paragraph introduces the report and provides enough narrative context for article extraction.</p>
                \(content)
                <p>The final paragraph provides further analysis and keeps the full report together as readable article content.</p>
              </article></body>
            </html>
            """

        return try ReadabilityExtractor(options: options).extract(
            fromHTML: html,
            url: URL(string: "https://example.com/story")!,
        )
    }
}
