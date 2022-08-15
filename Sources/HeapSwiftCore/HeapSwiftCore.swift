public class HeapSwiftCore {
    
    public init() {
        
        #if os(macOS)
            _ = HeapSwiftCoremacOS()
        #elseif os(iOS)
            _ = HeapSwiftCoreiOS()
        #elseif os(watchOS)
            _ = HeapSwiftCorewatchOS()
        #elseif os(tvOS)
            _ = HeapSwiftCoretvOS()
        #endif
        
        print("Hello HeapSwiftCore")
    }
}
