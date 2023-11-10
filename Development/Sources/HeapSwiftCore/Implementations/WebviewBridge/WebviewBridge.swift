#if canImport(WebKit)

import WebKit
import HeapSwiftCoreInterfaces

class WebviewBridge: NSObject, WKScriptMessageHandler, HeapBridgeSupportDelegate {
    
    static let embeddedScript = WKUserScript(source: heapWebviewBridgeJavascript, injectionTime: .atDocumentStart, forMainFrameOnly: true)
    
    weak var webView: WKWebView?
    let origins: [Origin]
    let injectHeapJavaScript: Bool
    let heapJsSettings: HeapJsSettings?
    
    let bridgeSupport: HeapBridgeSupport
    
    var _bridgeTarget: Any?
    
    @available(iOS 14.0, macOS 11.0, *)
    var bridgeTarget: (WKFrameInfo, WKContentWorld)? {
        get { _bridgeTarget as? (WKFrameInfo, WKContentWorld) }
        set { _bridgeTarget = newValue }
    }
    
    // Keep a list of rejected origins so we don't log incessantly about it.
    var rejectedOriginDescriptions: Set<String> = []

    init(webView: WKWebView, origins: Set<String>, injectHeapJavaScript: Bool = false, bindHeapJsWith settings: HeapJsSettings? = nil) {
        self.webView = webView
        self.origins = origins.compactMap(Origin.init(rawValue:))
        self.injectHeapJavaScript = injectHeapJavaScript
        self.heapJsSettings = settings
        self.bridgeSupport = .init()
    }
    
    func register() {
        
        guard let webView = webView else { return }
        
        self.bridgeSupport.delegate = self
        
        webView.configuration.userContentController.add(self, name: "HeapSwiftBridge")
        
        if injectHeapJavaScript {
            webView.configuration.userContentController.addUserScript(WebviewBridge.embeddedScript)
        }
        
        if heapJsSettings != nil {
            setHeapJsCookie()
            NotificationCenter.default.addObserver(self, selector: #selector(setHeapJsCookie), name: HeapStateForHeapJSChangedNotification, object: nil)
        }
        
        HeapLogger.shared.debug("Heap attached to web view with allowed origins: \(origins.map(\.description).joined(separator: ", "))")
    }
    
    /// Removes the webview integration from the webview.
    ///
    /// This method is not currently called anywhere and is included just for completeness.
    /// Each behavior that is automatic is called out in the method.
    func remove() {
        
        // The webview bridge has a weak reference to webView, so the message handler is
        // automatically deallocated when `webView` is deallocated. It does not need to be manually
        // called.
        webView?.configuration.userContentController.removeScriptMessageHandler(forName: "HeapSwiftBridge")
        
        // The notification center automatically removes observers when deallocated, which will
        // occur when the webview is deallocated. It does not need to be manually called.
        NotificationCenter.default.removeObserver(self, name: HeapStateForHeapJSChangedNotification, object: nil)
    }
    
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        
        guard origins.contains(where: { $0.matches(message.frameInfo) }) else {
            
            let description = message.frameInfo.securityOrigin.heapDescription
            
            // Log the invalid origin, once.
            if rejectedOriginDescriptions.insert(description).inserted {
                HeapLogger.shared.warn("Web view received a message from an unauthorized security origin \(description).  Allowed origins are \(origins.map(\.rawValue).joined(separator: ", "))")
            }
            
            return
        }
        
        HeapLogger.shared.trace("Web view received the following message:\n\(message.body)")
        
        if let body = message.body as? [String: Any],
           let type = body["type"] as? String {
            
            if type == "invocation",
               let method = body["method"] as? String,
               let arguments = body["arguments"] as? [String: Any] {
                
                let callbackId = body["callbackId"] as? String
                
                do {
                    let data = try bridgeSupport.handleInvocation(method: method, arguments: arguments)
                    replyWithData(data?._toHeapJSON() ?? JSON.null, to: message, callbackId: callbackId)
                } catch InvocationError.unknownMethod {
                    replyWithError("Unknown method: \(method)", to: message, callbackId: callbackId)
                } catch InvocationError.invalidParameters {
                    replyWithError("Invalid parameters", to: message, callbackId: callbackId)
                } catch {
                    replyWithError("Unknown error while invoking \(method)", to: message, callbackId: callbackId)
                }
                
                return
            } else if type == "heapjs-extend-session",
                      let sessionId = body["sessionId"] as? String,
                      let expirationDate = body["expirationDate"] as? Double {
                Heap.shared.consumer.extendSession(sessionId: sessionId, preferredExpirationDate: Date(timeIntervalSince1970: expirationDate / 1000))
            }
            
            if type == "result",
               let callbackId = body["callbackId"] as? String {
                
                let data = body["data"] as? String
                let error = body["error"] as? String

                bridgeSupport.handleResult(callbackId: callbackId, data: data, error: error)
               
                return
            }
        }
        
        HeapLogger.shared.trace("Web view received an unknown message over the JavaScript bridge.")
    }
    
    func replyWithData(_ data: JSON, to message: WKScriptMessage, callbackId: String?) {
        guard let callbackId = callbackId else { return }
        
        let caller: ScriptCaller
        
        if #available(iOS 14.0, macOS 11.0, *) {
            caller = scriptCaller(to: message.frameInfo, in: message.world)
        } else {
            caller = scriptCaller()
        }
        
        send(HeapBridgeSupport.InvocationResult(callbackId: callbackId, data: data), with: caller)
    }
    
    func replyWithError(_ error: String, to message: WKScriptMessage, callbackId: String?) {
        guard let callbackId = callbackId else { return }
        
        let caller: ScriptCaller
        
        if #available(iOS 14.0, macOS 11.0, *) {
            caller = scriptCaller(to: message.frameInfo, in: message.world)
        } else {
            caller = scriptCaller()
        }
        
        send(HeapBridgeSupport.InvocationResult(callbackId: callbackId, error: error), with: caller)
    }
    
    func sendInvocation(_ invocation: HeapBridgeSupport.Invocation) {
        
        let caller: ScriptCaller
        
        if #available(iOS 14.0, macOS 11.0, *) {
            if let (frameInfo, world) = bridgeTarget {
                caller = scriptCaller(to: frameInfo, in: world)
            } else {
                caller = scriptCaller()
            }
        } else {
            caller = scriptCaller()
        }
        
        send(invocation, with: caller) { result in
            if case let .failure(error) = result, let callbackId = invocation.callbackId {
                self.bridgeSupport.handleResult(callbackId: callbackId, data: nil, error: error.message)
            }
        }
    }
    
    typealias ScriptCaller = (_ webview: WKWebView, _ javascript: String, _ completionHandler: @escaping ((Result<Any, Error>) -> Void)) -> Void
    
    @available(iOS 14.0, macOS 11.0, *)
    func scriptCaller(to frame: WKFrameInfo, in world: WKContentWorld) -> ScriptCaller {
        return { webView, javascript, completionHandler in
            webView.evaluateJavaScript(javascript, in: frame, in: world, completionHandler: completionHandler)
        }
    }
    
    func scriptCaller() -> ScriptCaller {
        return { webView, javascript, completionHandler in
            webView.evaluateJavaScript(javascript, completionHandler: { result, error in
                if let error = error {
                    completionHandler(.failure(error))
                } else {
                    completionHandler(.success(result as Any))
                }
            })
        }
    }

    func send(_ payload: Encodable, with caller: ScriptCaller, delivered: ((Result<Void, CallbackError>) -> Void)? = nil) {
        guard let webView = webView else {
            delivered?(.failure(.init(message: "Webview deallocated")))
            return
        }
        
        HeapLogger.shared.trace("Sending message to web view: \(payload)")
        
        do {
            let data = try JSONEncoder().encode(payload)
            guard let jsonString = String(data: data, encoding: .utf8) else {
                delivered?(.failure(.init(message: "Empty payload")))
                return
            }
            
            caller(webView, "window.__heapNativeMessage(\(jsonString))") { result in
                if case .failure(let error) = result {
                    HeapLogger.shared.warn("An error occured while sending message to server: \(error)")
                    delivered?(.failure(.init(message: "Script error")))
                } else {
                    delivered?(.success(()))
                }
            }
        } catch {
            delivered?(.failure(.init(message: "Failed ot encode payload")))
        }
    }
}

extension WebviewBridge {
    
    @objc
    func setHeapJsCookie() {
        guard
            let heapJsSettings = self.heapJsSettings,
            let webView = self.webView
        else { return }
        
        guard
            let state = Heap.shared.consumer.fetchSession(),
            let cookie = state.toHeapJsCookie(settings: heapJsSettings)
        else {
            HeapLogger.shared.warn("Failed to generate heap.js session cookie.")
            return
        }
        
        webView.configuration.websiteDataStore.httpCookieStore.setCookie(cookie)
    }
    
    static func removeHeapJsCookie(for environmentId: String, from webView: WKWebView) {
        let httpCookieStore = webView.configuration.websiteDataStore.httpCookieStore
        let cookieName = State.heapJsCookieName(for: environmentId)
        httpCookieStore.getAllCookies({ cookies in
            for cookie in cookies where cookie.name == cookieName {
                httpCookieStore.delete(cookie)
            }
        })
    }
}

#endif
