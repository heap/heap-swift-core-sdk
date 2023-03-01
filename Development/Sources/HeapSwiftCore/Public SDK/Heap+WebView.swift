#if canImport(WebKit)
import WebKit

extension Heap {
    @objc
    public func attachWebView(_ webView: WKWebView, origins: Set<String>, injectHeapJavaScript: Bool = false) {
        WebviewBridge(webView: webView, origins: origins, injectHeapJavaScript: injectHeapJavaScript).register()
    }
    
    @objc(attachWebView:origins:)
    public func __attachWebView(_ webView: WKWebView, origins: Set<String>) {
        attachWebView(webView, origins: origins)
    }
}

#endif
