import HeapSwiftCoreInterfaces

class CountingContentsquareIntegration: _ContentsquareIntegration {
    
    var sessionTimeoutDuration: TimeInterval
    var contentsquareMethods: _ContentsquareMethods? = nil
    
    var pageviews: [Pageview] = []
    
    init(sessionTimeoutDuration: TimeInterval) {
        self.sessionTimeoutDuration = sessionTimeoutDuration
    }
    
    func didTrackHeapPageview(_ pageview: Pageview) {
        pageviews.append(pageview)
    }
    
    func setContentsquareMethods(_ methods: _ContentsquareMethods) {
        self.contentsquareMethods = methods
    }
}
