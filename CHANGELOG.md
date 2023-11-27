# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

> **Note**
>
> When publishing releases, the syntax of `## [VERSION_NUMBER]` is used to automatically
> extract the release notes.  To ensure the entire section is copied, only include `###` or
> deeper headings in a release section.

## [Unreleased]

### Changed

- `Heap.shared.resetIdentity()` and `Heap.shared.identify()` no longer clear event properties by default when a new user is identified.
  The previous behavior is available using the option `.clearEventPropertiesOnNewUser`.

### Added

- Added option `.clearEventPropertiesOnNewUser` to continue using existing SDK behavior where event properties are cleared when a new user is identified.

## [0.4.0]

### Added

- Added `.captureVendorId` option to enable capture of **iOS Vendor ID**  and
  **Initial iOS Vendor ID** from `UIDevice.current.identifierForVendor`.
  This supports a behavior change discussed in the **Changed** section.

### Changed

- **Target Text** and **Target accessibilityLabel** are now trimmed of whitespace.

- Properties from `addEventProperties` will no longer show up on sessions, matching Classic SDK behavior.  Pageviews and events are not affected by the change.

- The SDK no longer captures **iOS Vendor ID** and **Initial iOS Vendor ID** by default.
  This change allows developers to opt into Vendor ID tracking after they've validated
  their use complies with Apple's [user privacy and data use](https://developer.apple.com/app-store/user-privacy-and-data-use/) guidelines.
  To enable these properties, use the `.captureVendorId` option in `startRecording`.
  
## [0.3.1]

### Fixed

- Fixed code signing on macOS. The issue was caused by the HeapSwiftCoreInterfaces zip file not
  preserving symlinks.

### Added

- Exposed `+[HeapSourceInfo sourceInfoWithName:version:platform:properties:]` and
 `-[Heap track:properties:sourceInfo:]` to Objective-C.

## [0.3.0]

### Added

- Added app version change and install events.  These will fire when an environment first
  encounters a different application identifier, app name, or version at session start.

### Changed

- Changed process to retrieve iOS device model. `sysctlbyname` is now used to retrieve the 
  detailed hardware identifier (e.g., "iPhone10,3"). This results in more specific 
  model identification than the generic `UIDevice.model` approach which is now used
  as a fallback.

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

[Unreleased]: https://github.com/heap/heap-swift-core-sdk/compare/0.4.0...main
[0.4.0]: https://github.com/heap/heap-swift-core-sdk/compare/0.3.1...0.4.0
[0.3.1]: https://github.com/heap/heap-swift-core-sdk/compare/0.3.0...0.3.1
[0.3.0]: https://github.com/heap/heap-swift-core-sdk/compare/0.2.1...0.3.0
[0.2.1]: https://github.com/heap/heap-swift-core-sdk/compare/0.2.0...0.2.1
[0.2.0]: https://github.com/heap/heap-swift-core-sdk/compare/0.1.2...0.2.0
[0.1.2]: https://github.com/heap/heap-swift-core-sdk/compare/0.1.1...0.1.2
[0.1.1]: https://github.com/heap/heap-swift-core-sdk/compare/0.1.0...0.1.1
[0.1.0]: https://github.com/heap/heap-swift-core-sdk/releases/tag/0.1.0
