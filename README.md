# EmbeddedSwiftUtilities, as used in [gnorium.com](https://gnorium.com)

Utility functions and helpers for Embedded Swift environments.

## Overview

EmbeddedSwiftUtilities provides common helper functions and utilities optimized for Embedded Swift and WebAssembly environments.

## Installation

### Swift Package Manager

Add EmbeddedSwiftUtilities to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/gnorium/embedded-swift-utilities", branch: "main")
]
```

Then add it to your target dependencies:

```swift
.target(
    name: "YourTarget",
    dependencies: [
        .product(name: "EmbeddedSwiftUtilities", package: "embedded-swift-utilities")
    ]
)
```

## Requirements

- Swift 6.2+

## License

Apache License 2.0 - See [LICENSE](LICENSE) for details

## Contributing

Contributions welcome! Please open an issue or submit a pull request.

## Related Packages

- [design-tokens](https://github.com/gnorium/design-tokens) - Universal design tokens based on Apple HIG
- [markdown-utilities](https://github.com/gnorium/markdown-utilities) - Markdown rendering with media attribution support
- [web-admin](https://github.com/gnorium/web-admin) - Web administration panel for applications
- [web-apis](https://github.com/gnorium/web-apis) - Web API implementations for Swift WebAssembly
- [web-builders](https://github.com/gnorium/web-builders) - HTML, CSS, JS, and SVG DSL builders
- [web-components](https://github.com/gnorium/web-components) - Reusable UI components for web applications
- [web-formats](https://github.com/gnorium/web-formats) - Structured data format builders
- [web-security](https://github.com/gnorium/web-security) - Portable security utilities for web applications
- [web-types](https://github.com/gnorium/web-types) - Shared web types and design tokens
