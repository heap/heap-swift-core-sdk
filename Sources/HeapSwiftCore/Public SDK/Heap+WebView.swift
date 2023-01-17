#if canImport(WebKit)
import WebKit

extension Heap {
    public func attachWebView(_ webView: WKWebView, origins: Set<String>) {
        WebviewBridge(webView: webView, origins: origins).register()
    }
}

#endif
