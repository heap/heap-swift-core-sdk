import Foundation

extension Value {
    init(value: any HeapPropertyValue) {
        self.init()
        self.string = value.heapValue
    }
}
