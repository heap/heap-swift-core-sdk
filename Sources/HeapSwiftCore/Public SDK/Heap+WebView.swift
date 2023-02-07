#if canImport(WebKit)
import WebKit

extension Heap {
    public func attachWebView(_ webView: WKWebView, origins: Set<String>, injectHeapJavaScript: Bool = false) {
        WebviewBridge(webView: webView, origins: origins, injectHeapJavaScript: injectHeapJavaScript).register()
    }
}

#endif
