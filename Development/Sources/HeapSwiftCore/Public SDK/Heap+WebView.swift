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
    
    /// Attaches Heap to a webview for use with the @heap/heap-webview-bridge NPM package.
    ///
    /// The @heap/heap-webview-bridge NPM package provides a JavaScript version of the Heap SDK
    /// that performs its work through HeapSwiftCore.
    ///
    /// - Parameters:
    ///   - webView: The web view to attach to Heap.
    ///   - origins: The set of URL origins to accept Heap method calls from.
    @objc
    public func attachWebView(_ webView: WKWebView, origins: Set<String>) {
        WebviewBridge(webView: webView, origins: origins).register()
    }
    
    /// Attaches Heap to a webview for use with the @heap/heap-webview-bridge NPM package.
    ///
    /// The @heap/heap-webview-bridge NPM package provides a JavaScript version of the Heap SDK
    /// that performs its work through HeapSwiftCore.
    ///
    /// If using `injectHeapJavaScript: true`, a userscript is added to the web view that supplies
    /// `window.Heap`.  This allows methods like `Heap.track("My Event")` to be called from simple
    /// web pages without pulling in a JavaScript dependency.
    ///
    /// - Parameters:
    ///   - webView: The web view to attach to Heap.
    ///   - origins: The set of URL origins to accept Heap method calls from.
    ///   - injectHeapJavaScript: If true, a JavaScript version of the Heap SDK will be added to
    ///     the web view.  This is different from the heap.js autocapture library.
    @objc
    public func attachWebView(_ webView: WKWebView, origins: Set<String>, injectHeapJavaScript: Bool) {
        WebviewBridge(webView: webView, origins: origins, injectHeapJavaScript: injectHeapJavaScript).register()
    }
    
    /// Enables session synchronization between the app's Heap environment and heap.js running in
    /// the web view.
    ///
    /// This is not guaranteed to work until the feature has been announced and documented on
    /// <https://developers.heap.io>.
    ///
    /// When attached, any heap.js instance with matching settings, origins, and environment ID
    /// will share a single user and session allowing native and web events to appear as a single
    /// user journey.
    ///
    /// This method and `Heap.shared.startRecording` should both be called before loading a URL in
    /// the web view to ensure all page views are bound to the common session.
    ///
    /// If an app has multiple web views, it is recommended that you call this on each one if using
    /// it on any of them.
    ///
    /// Once integrated, it is possible that the cookies will persist across multiple sessions, even
    /// after `Heap.shared.stopRecording` has been called. To completely remove this integration,
    /// use `Heap.shared.removeHeapJsCookie(for:from:)` each place you used this method.
    ///
    ///
    /// - Parameters:
    ///   - webView: The web view to attach to Heap.
    ///   - origins: The set of URL origins to accept Heap method calls from.
    ///   - settings: Cookie settings to use when configuring heap.js. These should provide the
    ///     same cookie domain, path, and secure flag as the `_hp2_id.$environmentId` cookie on
    ///     your site as found in a browser's developer console.
    @objc
    public func attachWebView(_ webView: WKWebView, origins: Set<String>, bindHeapJsWith settings: HeapJsSettings) {
        WebviewBridge(webView: webView, origins: origins, bindHeapJsWith: settings).register()
    }

    /// Removes heap integrations added with `attachWebView` in preparation for deallocation.
    ///
    /// This method removes web message listeners from the web view in order to guarantee that
    /// the `WKUserContentController` is deallocated when the `WKWebView` is deallocated. The Heap
    /// SDK doesn't maintain a strong references to the containing web view, but some versions of
    /// iOS do not release all web view elements if a message listener is attached.
    ///
    /// If you do not call this method, Heap will automatically remove the content listener, but
    /// this can cause WebKit to log error messages.
    @objc
    public func detachWebView(_ webView: WKWebView) {
        WebviewBridge.detachWebView(webView)
    }
    
    /// Removes a heap.js cookie previously set with `Heap.shared.attachWebView`.
    ///
    /// This method should be used when removing a heap.js integration from an app.  It should be
    /// called before any web views are loaded within the app.  It may be called before or after
    /// `Heap.shared.startRecording`.
    /// - Parameters:
    ///   - environmentId: An environment ID that was previously used in a heap.js integration.
    ///   - webView: The heap.js settings that were used with `Heap.shared.attachWebView`.
    @objc(removeHeapJsCookieForEnvironmentId:fromWebView:)
    public func removeHeapJsCookie(for environmentId: String, from webView: WKWebView) {
        WebviewBridge.removeHeapJsCookie(for: environmentId, from: webView)
    }
}

#endif
