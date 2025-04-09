# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.8.3]

### Fixed

- Fixed ABI regression that impacted notification autocapture and the integration SDK.

## [0.8.2]

### Changed

- Updated API endpoint from `c.us.heap-api.com` to `mh.bf.contentsquare.net`.

## [0.8.1]

### Fixed

- Fixed an issue where the framework's Info.plist had an invalid minimum OS version, preventing App
  Store releases.

## [0.8.0]

### Changed

- The SDK is now distributed as a dynamic XCFramework.
- The SDK now depends on the binary-distributed CSSwiftProtobuf instead of SwiftProtobuf from source.
- The interfaces from HeapSwiftCoreInterfaces have been merged into this project.  **This is a
  breaking change that requires updates to the latest versions of HeapIOSAutocapture,
  HeapNotificationAutocapture, and HeapContentsquareIntegration.**  If an error appears at build
  time, update the corresponding packages.

- The minimum deployment targets have increased to macOS 11, iOS 13, tvOS 13, and watchOS 6.0.

### Added

- Added support for visionOS.

## [0.7.2]

### Fixed

- Zero length events (`Heap.shared.track("")`) are no longer uploaded to the server, where they were
  being rejected.

## [0.7.1]

### Added

- The SDK now sends identity to the Live data feed.

## [0.7.0]

### Added

- Added new interfaces for upcoming autocapture release.

## [0.6.1]

### Fixed

- Fixed session creation from integration code.

## [0.6.0]

### Added

- Added new `startRecording` option, `resumePreviousSession`, which resumes the previous session on
  start if the session has not yet expired.
- Added new signature `stopRecording(deleteUser: Bool)` which deletes the current user state.
  Subsequent calls to `startRecording` will have a new user and session as a result.
- Added several internal interfaces to support an upcoming integration.

## [0.5.3]

### Changed

- Improved trace logging for failed Sqlite queries.

## [0.5.2]

### Added

- Added `enableInteractionReferencingPropertyCapture`, which will be used in heap-ios-autocapture
  0.5.0 and later to enable "Target Ivar" capture.  The feature is off-by-default to avoid edge
  conditions that can cause Swift's `Mirror` functionality to crash.

### Deprecated

- Deprecated `disableInteractionReferencingPropertyCapture` in favor of off-by-default behavior.

## [0.5.1]

### Fixed

- Native track calls now preserve session expiration dates set by heap.js when using
  `Heap.attachWebView`.

### Added

- Added `Heap.shared.environmentId`, which returns the current environment ID or `nil` if not
  recording.
- Added `sourceProperties` to `trackInteraction` (for use by autocapture frameworks).

## [0.5.0]

### Fixed

- Fixed crash on `Heap.attachWebView` when called twice on the same web view prior to iOS 15.
  Now, subsequent calls are ignored.

- Fixed small memory leak when an attached `WKWebView` is deallocated.  This was caused by the 
  `WKUserContentController` maintaining a strong self reference when it has message handlers
  attached.  This change may trigger a warning message from WebKit on `WKWebView` deallocation,
  which can be resolved by calling `Heap.detachWebView` when removing the web view.

- `Heap.removeHeapJsCookie` is now public.

### Changed

- `Heap.shared.resetIdentity()` and `Heap.shared.identify()` no longer clear event properties by
  default when a new user is identified.
  
  The previous behavior is available using the option `.clearEventPropertiesOnNewUser`.

- Changed uploader behavior around server errors.

### Added

- Added option `.clearEventPropertiesOnNewUser` to continue using existing SDK behavior where event
  properties are cleared when a new user is identified.

- Added `Heap.detachWebView`.  This method removes most integrations added with
  `Heap.attachWebView` with the exception of the heap.js cookie.  This method is optional and
  intended to be used before deallocating a `WKWebView`.

## [0.4.0]

### Added

- Added `.captureVendorId` option to enable capture of **iOS Vendor ID**  and **Initial iOS Vendor
  ID** from `UIDevice.current.identifierForVendor`. This supports a behavior change discussed in the
  **Changed** section.

### Changed

- **Target Text** and **Target accessibilityLabel** are now trimmed of whitespace.

- Properties from `addEventProperties` will no longer show up on sessions, matching Classic SDK
  behavior.  Pageviews and events are not affected by the change.

- The SDK no longer captures **iOS Vendor ID** and **Initial iOS Vendor ID** by default. This change
  allows developers to opt into Vendor ID tracking after they've validated their use complies with
  Apple's [user privacy and data use] guidelines.
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

[0.8.3]: https://github.com/heap/heap-swift-core-sdk/releases/tag/0.8.3
[0.8.2]: https://github.com/heap/heap-swift-core-sdk/releases/tag/0.8.2
[0.8.1]: https://github.com/heap/heap-swift-core-sdk/releases/tag/0.8.1
[0.8.0]: https://github.com/heap/heap-swift-core-sdk/releases/tag/0.8.0
[0.7.2]: https://github.com/heap/heap-swift-core-sdk/compare/0.7.1...0.7.2
[0.7.1]: https://github.com/heap/heap-swift-core-sdk/compare/0.7.0...0.7.1
[0.7.0]: https://github.com/heap/heap-swift-core-sdk/compare/0.6.1...0.7.0
[0.6.1]: https://github.com/heap/heap-swift-core-sdk/compare/0.6.0...0.6.1
[0.6.0]: https://github.com/heap/heap-swift-core-sdk/compare/0.5.3...0.6.0
[0.5.3]: https://github.com/heap/heap-swift-core-sdk/compare/0.5.2...0.5.3
[0.5.2]: https://github.com/heap/heap-swift-core-sdk/compare/0.5.1...0.5.2
[0.5.1]: https://github.com/heap/heap-swift-core-sdk/compare/0.5.0...0.5.1
[0.5.0]: https://github.com/heap/heap-swift-core-sdk/compare/0.4.0...0.5.0
[0.4.0]: https://github.com/heap/heap-swift-core-sdk/compare/0.3.1...0.4.0
[0.3.1]: https://github.com/heap/heap-swift-core-sdk/compare/0.3.0...0.3.1
[0.3.0]: https://github.com/heap/heap-swift-core-sdk/compare/0.2.1...0.3.0
[0.2.1]: https://github.com/heap/heap-swift-core-sdk/compare/0.2.0...0.2.1
[0.2.0]: https://github.com/heap/heap-swift-core-sdk/compare/0.1.2...0.2.0
[0.1.2]: https://github.com/heap/heap-swift-core-sdk/compare/0.1.1...0.1.2
[0.1.1]: https://github.com/heap/heap-swift-core-sdk/compare/0.1.0...0.1.1
[0.1.0]: https://github.com/heap/heap-swift-core-sdk/releases/tag/0.1.0
[user privacy and data use]: https://developer.apple.com/app-store/user-privacy-and-data-use/
