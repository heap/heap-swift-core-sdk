# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.2.1]

### Fixed

- Added missing Objective-C module to HeapSwiftCoreInterfaces to unblock CocoaPods release.

## [0.2.0]

### Added

- Added option `startSessionImmediately` to begin tracking sessions immediately.

### Changed

- Default behavior for sessions has been changed (`startSessionImmediately = false`).  
  Tracking of sessions is now delayed until one of the following is called:
  - `Heap.shared.track()`
  - `Heap.shared.trackPageview()`
  - `Heap.shared.trackInteraction()`
  - `Heap.shared.uncommittedInteractionEvent()`
  - `Heap.shared.fetchSessionId()`

## [0.1.2]

### Changed

- Split out public APIs into a ABI-stable XCFramework to better support heap-ios-autocapture-sdk.

### Fixed

- Removed usage of `unsafeFlags` in Package.swift.

## [0.1.1]

### Fixed

- Omits properties containing empty keys and values.

## [0.1.0]

### Added

- Manual capture SDK.
- Support methods and classes for runtime bridges.
- Support methods and classes for autocapture sources.
- Support for manual capture within WKWebView.
- Support for platforms targeting Swift: macOS, watchOS, iOS, iPadOS, tvOS.

[0.2.1]: https://github.com/heap/heap-swift-core-sdk/compare/0.2.0...0.2.1
[0.2.0]: https://github.com/heap/heap-swift-core-sdk/compare/0.1.2...0.2.0
[0.1.2]: https://github.com/heap/heap-swift-core-sdk/compare/0.1.1...0.1.2
[0.1.1]: https://github.com/heap/heap-swift-core-sdk/compare/0.1.0...0.1.1
[0.1.0]: https://github.com/heap/heap-swift-core-sdk/releases/tag/0.1.0
