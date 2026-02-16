//
//  ReadabilityExtractorTests.swift
//  ReadabilityKit
//
//  Created by Chris Jenkins on 15/02/2026.
//

import Foundation
import Testing

@testable import ReadabilityKit

@Suite("ReadabilityExtractorTests")
struct ReadabilityExtractorTests {

    @Test("Extracts basic article content and drops obvious chrome")
    func extractFromHTML_basic() throws {
        let html = """
            <html><head>
              <title>Example</title>
              <meta name="author" content="Chris">
              <meta name="description" content="An example article.">
            </head>
            <body>
              <header>Nav <a href="/">Home</a></header>

              <div class="content article-body">
                <h1>Hello World</h1>
                <p>This is a real paragraph with enough text to be considered content, and it has commas, too.</p>
                <p>Another paragraph follows with more narrative text so the extractor has something to score properly.</p>

                <table role="presentation"><tr><td>
                  <div>Layout table wrapper</div>
                  <p>More article text inside a layout table.</p>
                </td></tr></table>

                <table>
                  <caption>Data</caption>
                  <tr><th>A</th><th>B</th><th>C</th></tr>
                  <tr><td>1</td><td>2</td><td>3</td></tr>
                  <tr><td>4</td><td>5</td><td>6</td></tr>
                </table>
              </div>

              <div class="share">Share buttons</div>
              <footer>Footer junk</footer>
            </body></html>
            """

        let extractor = ReadabilityExtractor(options: .init(enableClustering: true))
        let article = try extractor.extract(fromHTML: html, url: URL(string: "https://example.com/post")!)

        #expect(article.title.contains("Example") || article.title.contains("Hello World"))
        #expect(article.byline == "Chris")
        #expect(article.textContent.contains("real paragraph"))
        #expect(!article.textContent.lowercased().contains("footer junk"))
        #expect(!article.textContent.lowercased().contains("share buttons"))

        // Data table caption should remain
        #expect(article.contentHTML.contains("caption"))
    }

    @Test("Parses news-style pages and removes related/comments/footer regions")
    func extractFromHTML_newsSiteLayout_removesChromeAndKeepsStory() throws {
        let html = """
            <html>
              <head>
                <title>World Desk - Storm Update</title>
                <meta property="og:title" content="Storm Update: Coastal Cities Prepare">
                <meta name="author" content="Jamie Reporter">
                <meta name="description" content="A longform update from the coast.">
              </head>
              <body>
                <header class="site-header">
                  <nav>
                    <a href="/">Home</a>
                    <a href="/world">World</a>
                    <a href="/opinion">Opinion</a>
                  </nav>
                </header>

                <main>
                  <aside class="sidebar related">
                    <h2>Related Stories</h2>
                    <ul>
                      <li><a href="/1">One</a></li>
                      <li><a href="/2">Two</a></li>
                    </ul>
                  </aside>

                  <article id="main-article" class="article-content story-body">
                    <h1>Storm Update: Coastal Cities Prepare</h1>
                    <p>Emergency officials are preparing shelters, coordinating transport, and issuing staged alerts as winds strengthen along the coastline.</p>
                    <p>Residents in lower elevations have been advised to secure property, gather essentials, and plan routes inland before conditions worsen overnight.</p>
                    <p>Regional agencies say utility crews and medical teams are pre-positioned to restore services quickly after peak impact passes the area.</p>
                  </article>

                  <section class="comments">
                    <h2>Comments</h2>
                    <p>first!</p>
                  </section>
                </main>

                <footer class="site-footer">Copyright and legal links</footer>
              </body>
            </html>
            """

        let extractor = ReadabilityExtractor(options: .init(enableClustering: true))
        let article = try extractor.extract(fromHTML: html, url: URL(string: "https://news.example.com/world/storm")!)

        #expect(article.title.contains("Storm Update"))
        #expect(article.byline == "Jamie Reporter")
        #expect(article.excerpt == "A longform update from the coast.")
        #expect(article.textContent.contains("Emergency officials are preparing shelters"))
        #expect(article.textContent.contains("Residents in lower elevations"))
        #expect(!article.textContent.lowercased().contains("related stories"))
        #expect(!article.textContent.lowercased().contains("copyright and legal links"))
        #expect(!article.textContent.lowercased().contains("comments"))
    }

    @Test("Repairs lazy media, unwraps layout tables, and removes newsletter blocks")
    func extractFromHTML_blogWithLazyMediaAndLayoutTable_repairsMediaAndDropsNewsletter() throws {
        let html = """
            <html>
              <head>
                <title>Engineering Blog</title>
                <meta name="author" content="Taylor Dev">
              </head>
              <body>
                <div class="page">
                  <div class="newsletter-banner">
                    <p>Subscribe to our newsletter now.</p>
                  </div>

                  <div class="post-content article">
                    <h1>How We Scaled Processing</h1>
                    <p>Our team redesigned ingestion pipelines, reduced lock contention, and introduced bounded queues to stabilize throughput under spikes.</p>
                    <p>After tuning task priorities and splitting work into deterministic stages, error rates fell and latency percentiles narrowed significantly.</p>

                    <img data-src="https://cdn.example.com/image-hero.jpg" alt="hero">
                    <img src="https://cdn.example.com/tracker.gif" width="1" height="1" alt="tracker">

                    <table role="presentation">
                      <tr>
                        <td>
                          <div>Wrapped in layout table</div>
                          <p>The migration also simplified deployment rollback and improved observability for on-call engineers.</p>
                        </td>
                      </tr>
                    </table>
                  </div>
                </div>
              </body>
            </html>
            """

        let extractor = ReadabilityExtractor(options: .init(enableClustering: true))
        let article = try extractor.extract(fromHTML: html, url: URL(string: "https://blog.example.com/scaling")!)

        #expect(article.byline == "Taylor Dev")
        #expect(article.textContent.contains("Our team redesigned ingestion pipelines"))
        #expect(article.textContent.contains("improved observability for on-call engineers"))
        #expect(!article.textContent.lowercased().contains("subscribe to our newsletter"))

        // lazy media recovered, 1x1 tracker removed
        #expect(article.contentHTML.contains("src=\"https://cdn.example.com/image-hero.jpg\""))
        #expect(!article.contentHTML.contains("tracker.gif"))
    }

    @Test("Clusters split article sections in document order and excludes promo blocks")
    func extractFromHTML_splitArticleAcrossSections_clustersInDocumentOrder() throws {
        let html = """
            <html>
              <head>
                <title>Travel Magazine</title>
              </head>
              <body>
                <div class="site-nav">
                  <a href="/destinations">Destinations</a>
                  <a href="/guides">Guides</a>
                </div>

                <div class="story-part content-segment">
                  <h1>Three Days in Lisbon</h1>
                  <p>Start in Alfama at sunrise, then walk toward miradouros where trams and tiled facades frame the hills with sweeping river views.</p>
                </div>

                <div class="promo related">You may also like ten other city guides.</div>

                <section class="story-part content-segment">
                  <p>Spend the afternoon in Baixa and Chiado, stopping for pastries, neighborhood coffee, and short museum visits between plazas.</p>
                  <p>Finish with dinner by the waterfront and a night tram ride back uphill to see the old quarter lit across the valley.</p>
                </section>
              </body>
            </html>
            """

        let extractor = ReadabilityExtractor(options: .init(enableClustering: true, clusterTopN: 10))
        let article = try extractor.extract(fromHTML: html, url: URL(string: "https://travel.example.com/lisbon")!)

        let first = article.textContent.range(of: "Start in Alfama at sunrise")
        let second = article.textContent.range(of: "Spend the afternoon in Baixa")
        #expect(first != nil)
        #expect(second != nil)
        if let first, let second {
            #expect(first.lowerBound < second.lowerBound)
        }
        #expect(!article.textContent.lowercased().contains("you may also like"))
    }

    @Test("Preserves data tables and captions inside article content")
    func extractFromHTML_keepsDataTableWithinArticle() throws {
        let html = """
            <html>
              <head><title>Market Brief</title></head>
              <body>
                <article class="post-body">
                  <h1>Quarterly Snapshot</h1>
                  <p>The quarter showed broad gains across infrastructure categories, with sustained demand in edge compute and storage systems.</p>
                  <p>Below is a compact summary table used by analysts for comparing segment performance trends over time.</p>
                  <table>
                    <caption>Segment Revenue (USDm)</caption>
                    <tr><th>Segment</th><th>Q1</th><th>Q2</th><th>Q3</th></tr>
                    <tr><td>Core</td><td>120</td><td>126</td><td>131</td></tr>
                    <tr><td>Edge</td><td>78</td><td>83</td><td>90</td></tr>
                  </table>
                  <p>Management expects moderate expansion next quarter while margins remain stable despite ongoing logistics volatility.</p>
                </article>
              </body>
            </html>
            """

        let extractor = ReadabilityExtractor()
        let article = try extractor.extract(fromHTML: html, url: URL(string: "https://finance.example.com/brief")!)

        #expect(article.textContent.contains("Quarterly Snapshot"))
        #expect(article.textContent.contains("Segment Revenue"))
        #expect(article.contentHTML.contains("<table"))
        #expect(article.contentHTML.contains("<caption"))
        #expect(article.contentHTML.contains("Segment Revenue (USDm)"))
    }

    @Test("Extracts lead image from metadata when valid")
    func extractFromHTML_leadImageFromMetadata() throws {
        let html = """
            <html>
              <head>
                <title>Photo Essay</title>
                <meta property="og:image" content="https://cdn.example.com/hero.jpg">
                <meta property="og:image:width" content="1200">
                <meta property="og:image:height" content="630">
              </head>
              <body>
                <article>
                  <p>This article includes a hero image in metadata, and it should be selected even without content images.</p>
                  <p>The body has enough text to pass the readability threshold for extraction.</p>
                </article>
              </body>
            </html>
            """

        let extractor = ReadabilityExtractor()
        let article = try extractor.extract(fromHTML: html, url: URL(string: "https://example.com/essay")!)

        #expect(article.leadImageURL?.absoluteString == "https://cdn.example.com/hero.jpg")
    }

    @Test("Rejects small metadata image and falls back to content hero")
    func extractFromHTML_leadImageFallsBackToContent() throws {
        let html = """
            <html>
              <head>
                <title>Feature</title>
                <meta property="og:image" content="https://cdn.example.com/icon.png">
                <meta property="og:image:width" content="80">
                <meta property="og:image:height" content="80">
              </head>
              <body>
                <article>
                  <h1>Feature Story</h1>
                  <p>Longform content begins here with enough descriptive text to pass readability heuristics.</p>
                  <p>Additional narrative text ensures the extraction pipeline accepts the article body.</p>
                  <img class="hero" src="/images/lead.jpg" width="1400" height="700" alt="Hero image">
                </article>
              </body>
            </html>
            """

        let extractor = ReadabilityExtractor()
        let article = try extractor.extract(fromHTML: html, url: URL(string: "https://example.com/feature")!)

        #expect(article.leadImageURL?.absoluteString == "https://example.com/images/lead.jpg")
    }

    @Test("Filters logo-style images before selecting lead image")
    func extractFromHTML_leadImageFiltersLogo() throws {
        let html = """
            <html>
              <head><title>Gallery</title></head>
              <body>
                <article>
                  <img class="site-logo" src="https://cdn.example.com/logo.png" width="300" height="300">
                  <figure>
                    <img src="https://cdn.example.com/gallery/hero.jpg" width="1600" height="900" alt="Gallery hero">
                  </figure>
                  <p>Gallery text content with sufficient length to be scored as article.</p>
                  <p>More content to ensure the article is valid and non-empty.</p>
                </article>
              </body>
            </html>
            """

        let extractor = ReadabilityExtractor()
        let article = try extractor.extract(fromHTML: html, url: URL(string: "https://example.com/gallery")!)

        #expect(article.leadImageURL?.absoluteString == "https://cdn.example.com/gallery/hero.jpg")
    }

    @Test("Removes images with hide/hidden classes from extracted content")
    func extractFromHTML_removesHiddenClassImages() throws {
        let html = """
            <html>
              <head><title>Hidden Images</title></head>
              <body>
                <article>
                  <h1>Hidden Assets</h1>
                  <p>Content paragraph with enough text to satisfy readability requirements.</p>
                  <p>Another paragraph adds length and context to make the article valid.</p>
                  <img class="promo hide-banner" src="https://cdn.example.com/hidden.jpg" width="1200" height="700">
                  <img class="visible-hero" src="https://cdn.example.com/visible.jpg" width="1200" height="700">
                </article>
              </body>
            </html>
            """

        let extractor = ReadabilityExtractor()
        let article = try extractor.extract(fromHTML: html, url: URL(string: "https://example.com/hidden")!)

        #expect(!article.contentHTML.contains("hidden.jpg"))
        #expect(article.contentHTML.contains("visible.jpg"))
    }

    @Test("Strips empty paragraphs from extracted HTML")
    func extractFromHTML_stripsEmptyParagraphs() throws {
        let html = """
            <html>
              <head><title>Empty Paragraphs</title></head>
              <body>
                <article>
                  <h1>Empty Paragraph Cleanup</h1>
                  <p>First content paragraph has enough descriptive text to contribute meaningfully to extraction output.</p>
                  <p>   </p>
                  <p></p>
                  <p>
                  </p>
                  <p>Second content paragraph adds more detail so readability thresholds are clearly satisfied.</p>
                </article>
              </body>
            </html>
            """

        let extractor = ReadabilityExtractor()
        let article = try extractor.extract(fromHTML: html, url: URL(string: "https://example.com/empty-p")!)

        let paragraphTagCount = article.contentHTML.components(separatedBy: "<p").count - 1
        #expect(paragraphTagCount == 2)
        #expect(article.contentHTML.contains("First content paragraph"))
        #expect(article.contentHTML.contains("Second content paragraph"))
        #expect(!article.contentHTML.contains("<p></p>"))
    }

}
