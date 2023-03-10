# HeapSwiftCore Development

This directory is used for development of HeapSwiftCore.

## Project structure

Since Xcode downloads all dependencies specified in `/Package.swift` and a `Package.swift` file cannot reference sources outside it, this
project uses the following structure:

```
heap-swift-core
┗ Package.swift (public)
┗ Development
  ┗ Package.swift (development)
  ┗ Sources
  ┃ ┗ HeapSwiftCore
  ┃ ┗ HeapSwiftCoreTestSupport
  ┃ ┗ Protobufs
  ┗ Tests
    ┗ HeapSwiftCoreTests
    ┗ HeapSwiftCoreTests-AdSupport
```

This allows development to happen in the `Development` directory without pulling in test dependencies.  In general, the parent package
and the child should be the same except that the parent only contains the code required in an app.

# Documents

The behavior of this project is defined in the [Capture Core SDKs][specs] documentation folder (Heap internal).

# Installation and Usage

Heap can be installed using the developer instructions at https://developers.heap.io/docs/ios

During development, HeapSwiftCore can be added to an Xcode project or Swift package using `git@github.com:heap/heap-swift-core.git` or the
mirror at `git@github.com:heap/heap-swift-core-sdk.git`.

Once the repo is made public, users will be able to using `https://github.com/heap/heap-swift-core.git`.

For projects that require Cocoapods, such as the development of React Native and Flutter SDKs, there is a private repo at
https://github.com/heap/pre-release-cocoapods.  You can add it as a local pod repository using
`pod repo add pre-release-cocoapods git@github.com:heap/pre-release-cocoapods.git main`.  Once added, you can use it by adding the following
to the top of your `Podfile`:

```
source 'git@github.com:heap/pre-release-cocoapods.git'
source 'https://cdn.cocoapods.org/'
```

Then you can then add it as a dependency in your podspec with `s.dependency 'HeapSwiftCore'`.

Once this repo is made public, you will be able to remove references to `pre-release-cocoapods`.

# Usage

Heap can be initialized using `Heap.shared.startRecording("YOUR_APP_ID")`.  Once initialized, you can track events using
`Heap.shared.track("event name")` and use other functions covered in the documentation.

If at any point you wish to disable tracking, simply call `Heap.shared.stopRecording()`.

By default, Heap will log messages that will be informative in a production environment.  To enable messages that may be helpful in a
development environment, use `HeapLogger.shared.logLevel = .debug`.  To enable messages for troubleshooting complex issues, use
`HeapLogger.shared.loglevel = .trace`.

Log messages will appear in the Xcode log window and, with the exception of trace messages, will also appear in Console.app. You can
redirect messages to another channel implementing `LogChannel` and setting `HeapLogger.shared.logChannel to an instance of your class.

# Dependencies

- HeapSwiftCore has one runtime dependency, [swift-protobuf v1.x](https://github.com/apple/swift-protobuf), which it uses to build payloads
  to send to the server.
- HeapSwiftCore also has two testing dependencies, [Quick](https://github.com/Quick/Quick) and [Nimble](https://github.com/Quick/Nimble),
  which are used for BDD-style testing.

# Development

HeapSwiftCore is packaged as a Swift Package and can be developed on by opening the folder in either Xcode or Visual Studio Code.  Sources
exist in [Sources](Sources/) and tests exist in [Tests](Tests/).  There are also example apps in [Examples](Examples/) which can be used for
manually validating Heap.

# CI Pipeline

Each branch pushed to the server triggers a build in [the repo-heap-swift-core-required BuildKite pipeline][buildkite-req].  This pipeline
is defined in [../.buildkite/buildkite_required.yml](../.buildkite/buildkite_required.yml), which triggers various targets in
[../Makefile](../Makefile).  The latest commit must pass this build in order for a PR to be merged.

Steps in the CI pipeline can be executed manually by running the make targets in the root directory.  For example, you can run
`make iphone_ios12_unit_tests`, which is roughly equivalent of running the tests in Xcode with an iOS 12 simulator.  Tests that run on a
non-macOS device will create a temporary simulator which is destroyed at the end of testing.

The specifics of the CI system are described in the [iOS CI Infrastructure][ci] document (Heap internal).


[specs]: https://heapinc.atlassian.net/wiki/spaces/CAP/pages/2604990512/Capture+Core+SDKs
[buildkite-req]: https://buildkite.com/heap/repo-heap-swift-core-required
[ci]: https://heapinc.atlassian.net/wiki/spaces/CAP/pages/1327202313/iOS+CI+Infrastructure
