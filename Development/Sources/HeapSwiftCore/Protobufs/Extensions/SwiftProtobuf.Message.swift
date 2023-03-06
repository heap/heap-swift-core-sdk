import Foundation

// NOTE: For release builds, we mark the import as @_implementationOnly to
// indicate that we aren't exporting API from SwiftProtobuf.  This lets us
// expose our library ABI to consuming frameworks (like
// heap-ios-autocapture-sdk) without warnings that we're importing an
// unstable library.

#if BUILD_HEAP_SWIFT_CORE_FOR_DEVELOPMENT
import SwiftProtobuf
#else
@_implementationOnly import SwiftProtobuf
#endif

extension SwiftProtobuf.Message {
    /// Sets the property at the keypath if not nil.
    ///
    /// This works around SwiftProtobuf's behavior of having optional properties not be nullable.
    mutating func setIfNotNil<T>(_ keyPath: WritableKeyPath<Self, T>, _ value: T?, andTrue condition: Bool = true) {
        if condition,
           let value = value {
            self[keyPath: keyPath] = value
        }
    }
}
