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

For Swift Package Manager:

- The internal development repo can be added to an Xcode project using `git@github.com:heap/heap-swift-core.git`.
- The public mirror can be added to an Xcode project using `https://github.com/heap/heap-swift-core.git`.

For CocoaPods, including (React Native and Flutter SDKs), the project can be added using `s.dependency 'HeapSwiftCore', '~> 0.1'` for podspecs and `pod 'HeapSwiftCore', '~> 0.1' for podfiles.

# Usage

Heap can be initialized using `Heap.shared.startRecording("YOUR_APP_ID")`.  Once initialized, you can track events using
`Heap.shared.track("event name")` and use other functions covered in the documentation.

If at any point you wish to disable tracking, simply call `Heap.shared.stopRecording()`.

By default, Heap will log messages that will be informative in a production environment.  To enable messages that may be helpful in a
development environment, use `Heap.shared.logLevel = .debug`.  To enable messages for troubleshooting complex issues, use
`Heap.shared.loglevel = .trace`.

Log messages will appear in the Xcode log window and, with the exception of trace messages, will also appear in Console.app. You can
redirect messages to another channel implementing `LogChannel` and setting `Heap.shared.logChannel` to an instance of your class.

# Dependencies

- HeapSwiftCore has one runtime dependency, [swift-protobuf v1.x](https://github.com/apple/swift-protobuf), which it uses to build payloads
  to send to the server.
- HeapSwiftCore also has two testing dependencies, [Quick](https://github.com/Quick/Quick) and [Nimble](https://github.com/Quick/Nimble),
  which are used for BDD-style testing.

# Development

HeapSwiftCore is packaged as a Swift Package and can be developed on by opening the folder in either Xcode or Visual Studio Code.  Sources
exist in [Sources](Sources/) and tests exist in [Tests](Tests/).  There are also example apps in [Examples](Examples/) which can be used for
manually validating Heap.

# HeapSwiftCoreInterfaces

If you take a look in [../Package.swift][../Package.swift], you'll see that HeapSwiftCore has a binary target called
HeapSwiftCoreInterfaces.  This exists because HeapIOSAutocapture requires a stable ABI provided by Library Evolution and Swift Package
Manager doesn't have an ergonomic way to enable Library Evolution in a source package.

Instead, we compile a small XCFramework, HeapSwiftCoreInterfaces, which provides a stable ABI that can be used by HeapIOSAutocapture's
binary target, requiring only a thin wrapper on top to connect `Heap.shared` to the autocapture SDK.

Details on how this gets deployed are covered below.

# CI Pipeline

Each branch pushed to the server triggers a build in [the repo-heap-swift-core-required BuildKite pipeline][buildkite-req].  This pipeline
is defined in [../.buildkite/buildkite_required.yml](../.buildkite/buildkite_required.yml), which triggers various targets in
[../Makefile](../Makefile).  The latest commit must pass this build in order for a PR to be merged.

Steps in the CI pipeline can be executed manually by running the make targets in the root directory.  For example, you can run
`make iphone_ios12_unit_tests`, which is roughly equivalent of running the tests in Xcode with an iOS 12 simulator.  Tests that run on a
non-macOS device will create a temporary simulator which is destroyed at the end of testing.

The specifics of the CI system are described in the [iOS CI Infrastructure][ci] document (Heap internal).

# Triggering a HeapSwiftCore Release

Use the following process to trigger a release.

1.  Create a new branch for the release, potentially including the version name in the branch name (e.g. `release-0.2.7-alpha.1`
    for version 0.2.7-alpha.1).
2.  Use [`DevTools/LibraryVersions.py`](../DevTools/LibraryVersions.py) to set the version. (e.g.
    `./DevTools/LibraryVersions.py --library=core 0.2.7-alpha.1` for version 0.2.7-alpha.1).
3.  Make sure [`CHANGELOG.md`](../CHANGELOG.md) is up-to-date with features from the release in the appropriate section.
4.  Create a PR, make sure tests run, and that it is approved.
5.  Merge the PR.
6.  Run `make release_core_from_origin_main` to trigger a release.  This will push a tag with the version at `origin/main` to `origin`.
7.  [Wait for the tag to finish building.][buildkite]
8.  Release the new podspec.  Unfortunately, this step is still manual and requires you to be a member of the Heap organization on CocoaPods.
    Run the following in the internal repo:
   
    ```shell
    git checkout main && git pull && pod trunk push HeapSwiftCore.podspec
    ```

# Triggering a HeapSwiftCoreInterfaces Release

HeapSwiftCoreInterfaces should update much less frequently than HeapSwiftCore.  Essentially, it only needs to be changed if we are adding
features that are consumed by a binary framework. If you find yourself modifying a file in that folder, you will want to perform the
following steps:

1. Create a new branch for adding those feature to HeapSwiftCoreInterfaces.
2.  Use [`DevTools/LibraryVersions.py`](../DevTools/LibraryVersions.py) to set the version. (e.g.
    `./DevTools/LibraryVersions.py --library=interfaces 0.2.7` for version 0.2.7).
3.  Create a PR, make sure tests run, and that it is approved.
4.  Merge the PR.
5.  Run `make release_interfaces_from_origin_main` to trigger a release.  This will push a tag with the version at `origin/main` to
    `origin`.
6.  [Wait for the tag to finish building.][buildkite]
7.  Release the new podspec.  Unfortunately, this step is still manual and requires you to be a member of the Heap organization on CocoaPods.
    Run the following in the internal repo:
   
    ```shell
    git checkout main && git pull && pod trunk push HeapSwiftCoreInterfaces.podspec
    ```
8.  Create a new branch for feature development.
9.  Run `make apply_interfaces_to_public_packages` to update dependencies in Packages.swift and HeapSwiftCore.podspec.

> **Note**
> 
> Steps in this process are bound to break, as they aren't run as often and depend on the CI being in tip-top shape.  If step 6 fails, you can
> tag the commit manually. If step 7 fails on the CI, the make command or child scripts can be run locally to diagnose or circumvent the error.
> In the very worst case, you can tag the commit yourself on the public repo and move on to step 9.
>
> _If_ you have to run anything manually, capture it as a ticket so we can fix it later on.

[specs]: https://heapinc.atlassian.net/wiki/spaces/CAP/pages/2604990512/Capture+Core+SDKs
[buildkite]: https://buildkite.com/heap/repo-heap-swift-core
[buildkite-req]: https://buildkite.com/heap/repo-heap-swift-core-required
[ci]: https://heapinc.atlassian.net/wiki/spaces/CAP/pages/1327202313/iOS+CI+Infrastructure
[new-release]: https://github.com/heap/heap-swift-core-sdk/releases/new
