import Foundation
import HeapSwiftCoreInterfaces

extension Value {
    init(value: any HeapPropertyValue) {
        self.init()
        self.string = value.heapValue
    }
}

extension HeapPropertyValue {
    var protoValue: Value {
        .init(value: self)
    }
}
