@objc public class HeapJsSettings: NSObject {
    public let domain: String
    public let path: String
    public let secure: Bool
    
    @objc
    public init(domain: String, path: String = "/", secure: Bool = true) {
        self.domain = domain
        self.path = path
        self.secure = secure
    }
    
    @objc(settingsWithDomain:)
    public static func __settings(domain: String) -> HeapJsSettings {
        return .init(domain: domain)
    }
}


#if canImport(WebKit)
import WebKit

extension Heap {
    
    @objc
    public func attachWebView(_ webView: WKWebView, origins: Set<String>) {
        WebviewBridge(webView: webView, origins: origins).register()
    }
    
    @objc
    public func attachWebView(_ webView: WKWebView, origins: Set<String>, injectHeapJavaScript: Bool) {
        WebviewBridge(webView: webView, origins: origins, injectHeapJavaScript: injectHeapJavaScript).register()
    }
    
    @objc
    public func attachWebView(_ webView: WKWebView, origins: Set<String>, bindHeapJsWith settings: HeapJsSettings) {
        WebviewBridge(webView: webView, origins: origins, bindHeapJsWith: settings).register()
    }
    
    @objc(removeHeapJsCookieForEnvironmentId:fromWebView:)
    func removeHeapJsCookie(for environmentId: String, from webView: WKWebView) {
        WebviewBridge.removeHeapJsCookie(for: environmentId, from: webView)
    }
}

#endif
