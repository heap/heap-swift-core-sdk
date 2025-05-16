# HeapSwiftCore

HeapSwiftCore is an implementation of the Heap SDK for Apple systems that support Swift (iOS,
iPadOS, tvOS, macOS, watchOS, and visionOS). It serves several purposes:

- It provides the base SDK for initializing Heap and sending manual events, e.g.
  `Heap.shared.startRecording("YOUR_APP_ID")` and
  `Heap.shared.track("applied discount", properties: [ "coupon code": couponCode ])`.
- It manages the storage and upload of events.
- It provides components to support our other iOS and cross platform SDKs.

## Installation and Usage

Heap can be installed using the developer instructions at https://developers.heap.io/docs/ios
