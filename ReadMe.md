# ReadableSwift

ReadableSwift is a Swift Package for extracting clean, readable article content from web pages or raw HTML.

It is designed for Apple platforms and returns both cleaned HTML and plain text content, plus common metadata such as title, byline, and excerpt.

## Features

- Async extraction from a URL (`extract(from:)`)
- Direct extraction from raw HTML (`extract(fromHTML:url:)`)
- Content scoring and clustering to pick main article body
- Metadata extraction (`title`, `byline`, `excerpt`)
- Output as both `contentHTML` and `textContent`
- Configurable extraction and media-preservation options

## Requirements

- Swift 5.9+
- iOS 15+
- macOS 12+
- tvOS 15+
- watchOS 8+

## Installation

Add ReadableSwift to your `Package.swift` dependencies:

```swift
.dependencies: [
    .package(url: "https://github.com/<your-org-or-user>/ReadableSwift.git", branch: "main")
]
```

Then add the product to your target:

```swift
.target(
    name: "YourTarget",
    dependencies: [
        .product(name: "ReadableSwift", package: "ReadableSwift")
    ]
)
```

## Quick Start

```swift
import Foundation
import ReadableSwift

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

## Extract From Raw HTML

```swift
import Foundation
import ReadableSwift

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

ReadableSwift throws `ReadableError` for common failures:

- `invalidResponse`
- `httpStatus(Int)`
- `decodingFailed`
- `emptyHTML`
- `parseFailed`
- `noReadableContent`

## Development

Build:

```bash
swift build
```

Run tests:

```bash
swift test
```
