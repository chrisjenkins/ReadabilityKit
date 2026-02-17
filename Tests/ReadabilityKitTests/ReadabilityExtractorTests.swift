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

    @Test("Excludes hidden sidebar from candidate scoring")
    func extractFromHTML_hiddenSidebarDoesNotWinCandidateSelection() throws {
        let html = """
            <html>
              <head><title>Hidden Sidebar</title></head>
              <body>
                <aside hidden class="sidebar content">
                  <h2>Related coverage</h2>
                  <p>This hidden block contains a lot of text and links that should never be selected as article content.</p>
                  <p>Even with substantial copy, hidden nodes must not influence readability scoring decisions.</p>
                </aside>

                <article class="story-body">
                  <h1>Visible Story</h1>
                  <p>Visible article text explains the core event with enough narrative detail to satisfy readability scoring.</p>
                  <p>Additional visible paragraphs ensure this section is clearly the correct extraction target.</p>
                </article>
              </body>
            </html>
            """

        let extractor = ReadabilityExtractor()
        let article = try extractor.extract(fromHTML: html, url: URL(string: "https://example.com/hidden-sidebar")!)

        #expect(article.textContent.contains("Visible article text explains the core event"))
        #expect(!article.textContent.contains("Related coverage"))
        #expect(!article.textContent.contains("hidden block contains"))
    }

    @Test("Excludes aria-hidden nodes from candidate scoring")
    func extractFromHTML_ariaHiddenNodesAreExcludedFromScoring() throws {
        let html = """
            <html>
              <head><title>Aria Hidden</title></head>
              <body>
                <section aria-hidden="true" class="content promo">
                  <h2>Promoted module</h2>
                  <p>This text should be ignored because it is explicitly marked aria-hidden for assistive technologies.</p>
                </section>

                <main class="article-content">
                  <h1>Accessibility-Aware Extraction</h1>
                  <p>The extractor should prioritize visible narrative content and avoid hidden promotional containers.</p>
                  <p>This second paragraph provides enough text to pass extraction thresholds while remaining visible.</p>
                </main>
              </body>
            </html>
            """

        let extractor = ReadabilityExtractor()
        let article = try extractor.extract(fromHTML: html, url: URL(string: "https://example.com/aria-hidden")!)

        #expect(article.textContent.contains("Accessibility-Aware Extraction"))
        #expect(!article.textContent.contains("Promoted module"))
        #expect(!article.textContent.contains("explicitly marked aria-hidden"))
    }

    @Test("Can disable hidden-node filtering and keep hidden content")
    func extractFromHTML_canDisableHiddenNodeFiltering() throws {
        let html = """
            <html>
              <head><title>Hidden Toggle</title></head>
              <body>
                <article>
                  <h1>Visibility Option</h1>
                  <p>Main body text remains visible and should always be extracted.</p>
                  <div style="display: none;">
                    <p>Hidden appendix text only appears when hidden filtering is disabled.</p>
                  </div>
                </article>
              </body>
            </html>
            """

        let extractor = ReadabilityExtractor(options: .init(filterHiddenNodes: false))
        let article = try extractor.extract(fromHTML: html, url: URL(string: "https://example.com/hidden-toggle")!)

        #expect(article.textContent.contains("Main body text remains visible"))
        #expect(article.textContent.contains("Hidden appendix text only appears"))
    }

    @Test("Removes title-duplicate headers from extracted content")
    func extractFromHTML_dedupesTitleHeaders() throws {
        let html = """
            <html>
              <head>
                <title>Example Story</title>
                <meta property="og:title" content="Example Story">
              </head>
              <body>
                <article class="article-content">
                  <h1>Example Story</h1>
                  <h2>Example Story - Example.com</h2>
                  <p>This paragraph contains enough descriptive text to satisfy readability extraction requirements.</p>
                  <h2>Background</h2>
                  <p>Additional content explains why section headers should be preserved when they are not duplicates.</p>
                </article>
              </body>
            </html>
            """

        let extractor = ReadabilityExtractor()
        let article = try extractor.extract(fromHTML: html, url: URL(string: "https://example.com/story")!)

        #expect(article.title == "Example Story")
        #expect(!article.contentHTML.contains("<h1>Example Story</h1>"))
        #expect(!article.contentHTML.contains("Example Story - Example.com"))
        #expect(article.contentHTML.contains("<h2>Background</h2>"))
        #expect(article.textContent.contains("This paragraph contains enough descriptive text"))
    }

    @Test("Can disable title/header dedupe")
    func extractFromHTML_canDisableTitleHeaderDedupe() throws {
        let html = """
            <html>
              <head>
                <title>Deep Report</title>
                <meta property="og:title" content="Deep Report">
              </head>
              <body>
                <article>
                  <h1>Deep Report</h1>
                  <p>Main article paragraph with sufficient narrative text to pass extractor thresholds.</p>
                  <p>Second paragraph keeps the article robust and non-trivial for scoring.</p>
                </article>
              </body>
            </html>
            """

        let extractor = ReadabilityExtractor(
            options: .init(dedupeTitleHeaders: false, dropPreambleHeadersBeforeFirstParagraph: false)
        )
        let article = try extractor.extract(fromHTML: html, url: URL(string: "https://example.com/deep-report")!)

        #expect(article.contentHTML.contains("<h1>Deep Report</h1>"))
    }

    @Test("Removes preamble header before first paragraph")
    func extractFromHTML_removesPreambleHeaderBeforeFirstParagraph() throws {
        let html = """
            <html>
              <head><title>Preamble Cleanup</title></head>
              <body>
                <article class="story">
                  <h2>Updated 2 hours ago</h2>
                  <p>This opening paragraph contains enough text to ensure extraction succeeds while validating preamble cleanup.</p>
                  <h2>Section Context</h2>
                  <p>Subsequent section heading should remain because it is part of the article structure.</p>
                </article>
              </body>
            </html>
            """

        let extractor = ReadabilityExtractor()
        let article = try extractor.extract(fromHTML: html, url: URL(string: "https://example.com/preamble")!)

        #expect(!article.contentHTML.contains("Updated 2 hours ago"))
        #expect(article.contentHTML.contains("<h2>Section Context</h2>"))
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

    @Test("Preserves ordered and unordered lists in extracted HTML")
    func extractFromHTML_preservesOrderedAndUnorderedLists() throws {
        let html = """
            <html>
              <head><title>List Preservation</title></head>
              <body>
                <article>
                  <h1>Checklist for Release Day</h1>
                  <p>This guide explains a practical sequence for preparing deployment, validating outcomes, and communicating status to stakeholders.</p>
                  <ol>
                    <li>Freeze merges for the release branch.</li>
                    <li>Run the verification test suite.</li>
                    <li>Tag the release candidate.</li>
                  </ol>
                  <p>After the ordered rollout steps, teams also track follow-up actions in a general checklist for maintenance and communication.</p>
                  <ul>
                    <li>Monitor error rates and latency.</li>
                    <li>Post release notes in team channels.</li>
                    <li>Schedule a short retrospective.</li>
                  </ul>
                </article>
              </body>
            </html>
            """

        let extractor = ReadabilityExtractor()
        let article = try extractor.extract(fromHTML: html, url: URL(string: "https://example.com/lists")!)

        #expect(article.contentHTML.contains("<ol"))
        #expect(article.contentHTML.contains("<ul"))
        #expect(article.contentHTML.contains("Freeze merges for the release branch."))
        #expect(article.contentHTML.contains("Monitor error rates and latency."))
    }

    @Test("Preserves figures and images with src attributes")
    func extractFromHTML_preservesFiguresAndImagesWithSrc() throws {
        let html = """
            <html>
              <head><title>Figure Src Preservation</title></head>
              <body>
                <article>
                  <h1>Visual Story</h1>
                  <p>This article includes photography and descriptive text so extraction keeps the full story structure and associated media references.</p>
                  <figure class="hero-figure">
                    <img src="https://cdn.example.com/photos/mountain-hero.jpg" alt="Mountain at sunrise" width="1400" height="933">
                    <figcaption>Sunrise over the ridge line.</figcaption>
                  </figure>
                  <p>The narrative continues with additional context about weather, route planning, and safety considerations for hikers.</p>
                </article>
              </body>
            </html>
            """

        let extractor = ReadabilityExtractor()
        let article = try extractor.extract(fromHTML: html, url: URL(string: "https://example.com/figure-src")!)

        #expect(article.contentHTML.contains("<figure"))
        #expect(article.contentHTML.contains("<img"))
        #expect(article.contentHTML.contains("src=\"https://cdn.example.com/photos/mountain-hero.jpg\""))
        #expect(article.contentHTML.contains("<figcaption"))
        #expect(article.contentHTML.contains("Sunrise over the ridge line."))
    }

    @Test("Preserves figures and images with srcset attributes")
    func extractFromHTML_preservesFiguresAndImagesWithSrcset() throws {
        let html = """
            <html>
              <head><title>Figure Srcset Preservation</title></head>
              <body>
                <article>
                  <h1>Responsive Images</h1>
                  <p>Responsive imagery should remain intact in extracted content so clients can choose appropriately sized assets for different displays.</p>
                  <figure>
                    <img
                      src="https://cdn.example.com/photos/river-640.jpg"
                      srcset="https://cdn.example.com/photos/river-640.jpg 640w, https://cdn.example.com/photos/river-1280.jpg 1280w"
                      alt="River valley"
                    >
                    <figcaption>River valley at midday.</figcaption>
                  </figure>
                  <figure>
                    <img
                      data-src="https://cdn.example.com/photos/forest-640.jpg"
                      data-srcset="https://cdn.example.com/photos/forest-640.jpg 640w, https://cdn.example.com/photos/forest-1280.jpg 1280w"
                      alt="Forest trail"
                    >
                    <figcaption>Forest trail in late afternoon.</figcaption>
                  </figure>
                  <p>Additional explanatory text ensures the readability threshold is met without relying only on captions.</p>
                </article>
              </body>
            </html>
            """

        let extractor = ReadabilityExtractor()
        let article = try extractor.extract(fromHTML: html, url: URL(string: "https://example.com/figure-srcset")!)

        #expect(article.contentHTML.contains("<figure"))
        #expect(article.contentHTML.contains("srcset=\"https://cdn.example.com/photos/river-640.jpg 640w, https://cdn.example.com/photos/river-1280.jpg 1280w\""))
        #expect(article.contentHTML.contains("src=\"https://cdn.example.com/photos/forest-640.jpg\""))
        #expect(article.contentHTML.contains("srcset=\"https://cdn.example.com/photos/forest-640.jpg 640w, https://cdn.example.com/photos/forest-1280.jpg 1280w\""))
        #expect(article.contentHTML.contains("Forest trail in late afternoon."))
    }

    @Test("Preserves standard text formatting tags in extracted HTML")
    func extractFromHTML_preservesStandardTextFormattingTags() throws {
        let html = """
            <html>
              <head><title>Formatting Preservation</title></head>
              <body>
                <article>
                  <h1>Primary Heading</h1>
                  <p>This opening paragraph contains enough detail to ensure readability extraction succeeds consistently across the full content block.</p>

                  <h2>Section Heading</h2>
                  <p>We use <strong>strong emphasis</strong>, <em>stress emphasis</em>, <b>bold text</b>, and <i>italic text</i> to validate inline formatting retention.</p>

                  <h3>Subsection Heading</h3>
                  <p>Additional narrative length helps maintain score thresholds while preserving semantic heading hierarchy and typographic intent.</p>

                  <h4>Detail Heading</h4>
                  <p>Final paragraph confirms formatting tags remain in the extracted HTML output rather than being flattened into plain text only.</p>
                </article>
              </body>
            </html>
            """

        let extractor = ReadabilityExtractor()
        let article = try extractor.extract(fromHTML: html, url: URL(string: "https://example.com/formatting")!)

        #expect(article.contentHTML.contains("<h1"))
        #expect(article.contentHTML.contains("<h2"))
        #expect(article.contentHTML.contains("<h3"))
        #expect(article.contentHTML.contains("<h4"))
        #expect(article.contentHTML.contains("<strong>strong emphasis</strong>"))
        #expect(article.contentHTML.contains("<em>stress emphasis</em>"))
        #expect(article.contentHTML.contains("<b>bold text</b>"))
        #expect(article.contentHTML.contains("<i>italic text</i>"))
    }

    @Test("Parses included BBC fixture HTML")
    func extractFromHTML_bbcFixture_parsesCorrectly() throws {
        let fixtureURL = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .appendingPathComponent("Resources")
            .appendingPathComponent("bbc.html")
        let html = try String(contentsOf: fixtureURL, encoding: .utf8)

        let extractor = ReadabilityExtractor()
        let article = try extractor.extract(fromHTML: html, url: URL(string: "https://www.bbc.com/news/articles/c70ne31d884o")!)

        #expect(article.title.contains("Government abandons plans to delay 30 council elections"))
        #expect(!article.textContent.isEmpty)
        #expect(article.textContent.contains("The government has abandoned plans to delay 30 council elections in England"))
        #expect(article.contentHTML.contains("<p"))
    }

    @Test("Falls back to JSON-LD metadata when OG/meta tags are missing")
    func extractFromHTML_jsonLDFallbackMetadata() throws {
        let html = """
            <html>
              <head>
                <title>Fallback Title</title>
                <script type="application/ld+json">
                  {
                    "@context": "https://schema.org",
                    "@type": "NewsArticle",
                    "headline": "JSON-LD Headline",
                    "description": "JSON-LD description for metadata fallback.",
                    "author": { "@type": "Person", "name": "Jordan Writer" },
                    "image": { "@type": "ImageObject", "url": "https://cdn.example.com/jsonld-hero.jpg" }
                  }
                </script>
              </head>
              <body>
                <article>
                  <p>This article body has enough text to satisfy readability extraction and validate metadata fallback behavior.</p>
                  <p>Additional paragraph content confirms the parser can produce stable article output with JSON-LD metadata only.</p>
                </article>
              </body>
            </html>
            """

        let extractor = ReadabilityExtractor()
        let article = try extractor.extract(fromHTML: html, url: URL(string: "https://example.com/jsonld")!)

        #expect(article.title == "JSON-LD Headline")
        #expect(article.byline == "Jordan Writer")
        #expect(article.excerpt == "JSON-LD description for metadata fallback.")
        #expect(article.leadImageURL?.absoluteString == "https://cdn.example.com/jsonld-hero.jpg")
    }

    @Test("Includes qualifying sibling content when using single-candidate mode")
    func extractFromHTML_singleModeIncludesSiblingContent() throws {
        let html = """
            <html>
              <head><title>Sibling Inclusion</title></head>
              <body>
                <p class="standfirst">This standfirst introduces the story context with enough detail to qualify as meaningful article text for extraction heuristics.</p>

                <div class="article-content">
                  <h1>Deep Dive Release Notes</h1>
                  <p>The main body covers architectural changes, migration impacts, and rollout safety checks for distributed services.</p>
                  <p>It also explains follow-up work, monitoring strategy, and incident-response preparation for launch day.</p>
                </div>

                <div class="related-links">
                  <a href="/related-a">Related A</a>
                  <a href="/related-b">Related B</a>
                </div>
              </body>
            </html>
            """

        let extractor = ReadabilityExtractor(options: .init(enableClustering: false))
        let article = try extractor.extract(fromHTML: html, url: URL(string: "https://example.com/siblings")!)

        #expect(article.textContent.contains("This standfirst introduces the story context"))
        #expect(article.textContent.contains("The main body covers architectural changes"))
    }

    @Test("Retries with relaxed pruning when strict unlikely-candidate removal drops real content")
    func extractFromHTML_retriesWithRelaxedPruning() throws {
        let html = """
            <html>
              <head><title>Opinion Column</title></head>
              <body>
                <div class="comments">
                  <h1>Why Regional Trains Need Better Scheduling</h1>
                  <p>Commuters across the region are reporting longer waits, missed transfers, and inconsistent service updates throughout the week.</p>
                  <p>Transport planners say capacity constraints and outdated dispatch workflows are driving delays that compound during evening peaks.</p>
                </div>
              </body>
            </html>
            """

        let extractor = ReadabilityExtractor()
        let article = try extractor.extract(fromHTML: html, url: URL(string: "https://example.com/column")!)

        #expect(article.textContent.contains("Commuters across the region are reporting longer waits"))
        #expect(article.textContent.contains("Transport planners say capacity constraints"))
    }

    @Test("Uses preferred domain rule root for BBC fixture to reduce chrome")
    func extractFromHTML_bbcFixture_preferDomainRules() throws {
        let fixtureURL = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .appendingPathComponent("Resources")
            .appendingPathComponent("bbc.html")
        let html = try String(contentsOf: fixtureURL, encoding: .utf8)

        let extractor = ReadabilityExtractor(
            options: .init(enableDomainRules: true, domainRuleMode: .preferRules)
        )
        let article = try extractor.extract(fromHTML: html, url: URL(string: "https://www.bbc.com/news/articles/c70ne31d884o")!)

        #expect(article.textContent.contains("The government has abandoned plans to delay 30 council elections in England"))
        #expect(!article.textContent.contains("Skip to content"))
    }

    @Test("Can disable domain rules and still extract BBC fixture")
    func extractFromHTML_bbcFixture_domainRulesDisabled() throws {
        let fixtureURL = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .appendingPathComponent("Resources")
            .appendingPathComponent("bbc.html")
        let html = try String(contentsOf: fixtureURL, encoding: .utf8)

        let extractor = ReadabilityExtractor(options: .init(enableDomainRules: false))
        let article = try extractor.extract(fromHTML: html, url: URL(string: "https://www.bbc.com/news/articles/c70ne31d884o")!)

        #expect(article.title.contains("Government abandons plans to delay 30 council elections"))
        #expect(!article.textContent.isEmpty)
    }

}
