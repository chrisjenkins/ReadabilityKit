# ReadabilityKit

ReadabilityKit is a Swift Package for extracting clean, readable article content from web pages or raw HTML.

It is designed for Apple platforms and returns cleaned HTML, plain text, and article metadata (`title`, `byline`, `excerpt`).

## Features

- Async extraction from a URL via pluggable loaders (`URLSessionHTMLLoader`, `WebViewDOMLoader`)
- Direct extraction from raw HTML (`extract(fromHTML:url:)`)
- Multi-stage parsing pipeline (normalization, scoring, clustering, cleanup)
- Content scoring with dedicated scorer types
- Cluster-based main-content selection
- Output as both `contentHTML` and `textContent`
- Configurable extraction and media-preservation options (`ExtractionOptions`)

## Requirements

- Swift 5.9+
- iOS 15+
- macOS 12+
- tvOS 15+
- watchOS 8+

## Installation

Add ReadabilityKit to your `Package.swift` dependencies:

```swift
.dependencies: [
    .package(url: "https://github.com/<your-org-or-user>/ReadabilityKit.git", branch: "main")
]
```

Then add the product to your target:

```swift
.target(
    name: "YourTarget",
    dependencies: [
        .product(name: "ReadabilityKit", package: "ReadabilityKit")
    ]
)
```

## Quick Start

```swift
import Foundation
import ReadabilityKit

let extractor = ReadabilityExtractor()
let url = URL(string: "https://example.com/article")!

Task {
    do {
        let article = try await extractor.extract(from: url)
        print(article.title)
        print(article.textContent)
    } catch {
        print("Extraction failed: \(error)")
    }
}
```

## Loader Strategies

By default, `ReadabilityExtractor` uses `URLSessionHTMLLoader`.

```swift
import ReadabilityKit

let extractor = ReadabilityExtractor(
    loader: URLSessionHTMLLoader()
)
```

If you want rendered DOM (after page load), use `WebViewDOMLoader`:

```swift
import ReadabilityKit

@MainActor
func makeExtractor() -> ReadabilityExtractor {
    ReadabilityExtractor(loader: WebViewDOMLoader())
}
```

## Extract From Raw HTML

```swift
import Foundation
import ReadabilityKit

let html = """
<html>
  <head><title>Example</title></head>
  <body><article><h1>Hello</h1><p>Readable content here...</p></article></body>
</html>
"""

let extractor = ReadabilityExtractor(options: .init(enableClustering: true))
let article = try extractor.extract(
    fromHTML: html,
    url: URL(string: "https://example.com/post")!
)

print(article.title)
print(article.contentHTML)
```

## Parsing Pipeline

`ReadabilityExtractor` follows this flow:

1. Load HTML using the configured `URLLoading` implementation.
2. Parse DOM with SwiftSoup.
3. Run document cleaning passes (unsafe tags, break normalization, unlikely candidate removal).
4. Score candidates using paragraph/class/link-density + density scoring.
5. Select content via clustering (or best single node if clustering is disabled).
6. Run element cleaning passes (junk blocks, lazy media, table cleanup, etc.).
7. Build the final `Article`.

## Output Model

`Article` contains:

- `url: URL`
- `title: String`
- `byline: String?`
- `excerpt: String?`
- `contentHTML: String`
- `textContent: String`

## Configuration

Use `ExtractionOptions` to tune behavior:

- `preserveHTML`
- `keepIframes`
- `keepVideos`
- `keepAudio`
- `wrapInArticleTag`
- `enableClustering`
- `clusterTopN`
- `clusterMaxRankGap`
- `clusterMaxDepthDelta`
- `clusterMinTokenJaccard`

Example:

```swift
let options = ExtractionOptions(
    preserveHTML: true,
    keepIframes: false,
    keepVideos: true,
    keepAudio: true,
    wrapInArticleTag: true,
    enableClustering: true
)

let extractor = ReadabilityExtractor(options: options)
```

## Errors

ReadabilityKit throws `ReadabilityError` for common failures:

- `invalidResponse`
- `httpStatus(Int)`
- `decodingFailed`
- `emptyHTML`
- `parseFailed`
- `noReadableContent`

## Package Structure

Current source layout under `Sources/ReadabilityKit`:

- `Models/`
  - `Article`
  - `ExtractionOptions`
  - `ReadabilityError`
- `Loading/`
  - `URLLoading`
  - `URLSessionHTMLLoader`
  - `WebViewDOMLoader`
- `Extraction/`
  - `ReadabilityExtractor`
- `Scoring/`
  - `ElementScorer`
  - `ClassWeightScorer`
  - `LinkDensityScorer`
  - `ParagraphScorer`
  - `DensityScoring`
- `Clustering/`
  - `ClusteringCandidate`
  - `ClusteringEngine`
- `Cleaning/`
  - `CleaningPass`, `DocumentCleaningPass`, `ElementCleaningPass`
  - Document and element cleaning pass implementations

## Development

Build:

```bash
swift build
```

Run tests:

```bash
swift test
```
