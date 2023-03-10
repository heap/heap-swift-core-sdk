# HeapSwiftCore

HeapSwiftCore is an implementation of the Heap SDK for Apple systems that support Swift (iOS, iPadOS, tvOS, macOS, and watchOS). It serves
several purposes:

- It provides the base SDK for initializing Heap and sending manual events, e.g. `Heap.shared.startRecording("YOUR_APP_ID")` and
  `Heap.shared.track("applied discount", properties: [ "coupon code": couponCode ])`.
- It manages the storage and upload of events.
- It provides functions that allow autocapture frameworks to send events, e.g., `Heap.shared.trackPageview` and
  `Heap.shared.trackInteraction`.
- It provides delegate methods that allow autocapture frameworks to respond to system events, i.e. `Heap.shared.addSource`.
- It provides support tools for bridging to other runtimes and languages, i.e., `HeapBridgeSupport` and `Heap.shared.addBridge`.
- It provides support for web view event capture using the bridging mechanisms described above.

## Installation and Usage

Heap can be installed using the developer instructions at https://developers.heap.io/docs/ios

## Dependencies

HeapSwiftCore has one dependency, [swift-protobuf v1.x](https://github.com/apple/swift-protobuf), which it uses to build payloads to send
to the server.

## Development

HeapSwiftCore development happens within the [Development](Development/) directory and more detailed instructions at
[Development/README.md](Development/README.md).
