import Foundation
import SwiftProtobuf

extension SwiftProtobuf.Message {
    /// Sets the property at the keypath if not nil.
    ///
    /// This works around SwiftProtobuf's behavior of having optional properties not be nullable.
    mutating func setIfNotNil<T>(_ keyPath: WritableKeyPath<Self, T>, _ value: T?) {
        if let value = value {
            self[keyPath: keyPath] = value
        }
    }
}
