#if canImport(WebKit)

import WebKit

class WebviewBridge: NSObject, WKScriptMessageHandler {
    
    weak var webView: WKWebView?
    let origins: [Origin]
    let eventConsumer: WebviewEventConsumer

    init(webView: WKWebView, origins: Set<String>, eventConsumer: any EventConsumerProtocol) {
        self.webView = webView
        self.origins = origins.compactMap(Origin.init(rawValue:))
        self.eventConsumer = WebviewEventConsumer(eventConsumer: eventConsumer)
    }
    
    func register() {
        webView?.configuration.userContentController.add(self, name: "HeapSwiftBridge")
        HeapLogger.shared.logDev("Heap attached to web view with allowed origins: \(origins.map(\.description).joined(separator: ", "))")
    }
    
    func remove() {
        webView?.configuration.userContentController.removeScriptMessageHandler(forName: "HeapSwiftBridge")
    }
    
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        
        guard origins.contains(where: { $0.matches(message.frameInfo) }) else {
            
            HeapLogger.shared.logDev("Web view received a message from an unauthorized security origin \(message.frameInfo.securityOrigin.heapDescription).  Allowed origins are \(origins.map(\.rawValue).joined(separator: ", "))")
            
            return
        }
        
        HeapLogger.shared.logDev("Web view received the following message:\n\(message.body)")
        
        if let body = message.body as? [String: Any],
           let type = body["type"] as? String {
            
            if type == "invocation",
               let method = body["method"] as? String,
               let arguments = body["arguments"] as? [String: Any] {
                
                let callbackId = body["callbackId"] as? String
                
                do {
                    let data = try eventConsumer.handleInvocation(method: method, arguments: arguments)
                    replyWithData(data, to: message, callbackId: callbackId)
                } catch InvocationError.unknownMethod {
                    replyWithError("Unknown method: \(method)", to: message, callbackId: callbackId)
                } catch InvocationError.invalidParameters {
                    replyWithError("Invalid parameters", to: message, callbackId: callbackId)
                } catch {
                    replyWithError("Unknown error while invoking \(method)", to: message, callbackId: callbackId)
                }
                
                return
            }
        }
        
        HeapLogger.shared.logDev("Web view received an unknown message over the JavaScript bridge.")
    }
    
    func replyWithData(_ data: JSON, to message: WKScriptMessage, callbackId: String?) {
        guard let callbackId = callbackId else { return }
        if #available(iOS 14.0, macOS 11.0, *) {
            send(HeapSDKInvocationResult(callbackId: callbackId, data: data), to: message.frameInfo, in: message.world)
        } else {
            send(HeapSDKInvocationResult(callbackId: callbackId, data: data))
        }
    }
    
    func replyWithError(_ error: String, to message: WKScriptMessage, callbackId: String?) {
        guard let callbackId = callbackId else { return }
        if #available(iOS 14.0, macOS 11.0, *) {
            send(HeapSDKInvocationResult(callbackId: callbackId, error: error), to: message.frameInfo, in: message.world)
        } else {
            send(HeapSDKInvocationResult(callbackId: callbackId, error: error))
        }
    }
    
    @available(iOS 14.0, macOS 11.0, *)
    func send(_ payload: Encodable, to frame: WKFrameInfo, in world: WKContentWorld) {
        guard let webView = webView else { return }
        HeapLogger.shared.logDebug("Sending message to web view: \(payload)")
        
        do {
            let data = try JSONEncoder().encode(payload)
            guard let jsonString = String(data: data, encoding: .utf8) else { return }
            
            webView.evaluateJavaScript("window.Heap.nativeMessage(\(jsonString))", in: frame, in: world, completionHandler: { result in
                if case .failure(let error) = result {
                    HeapLogger.shared.logDebug("An error occured while invoking a JavaScript callback: \(error)")
                }
            })
        } catch {
        }
    }
    
    func send(_ payload: Encodable) {
        guard let webView = webView else { return }
        HeapLogger.shared.logDebug("Sending message to web view: \(payload)")
        
        do {
            let data = try JSONEncoder().encode(payload)
            guard let jsonString = String(data: data, encoding: .utf8) else { return }

            webView.evaluateJavaScript("window.Heap.nativeMessage(\(jsonString))", completionHandler: { _, error in
                if let error = error {
                    HeapLogger.shared.logDebug("An error occured while invoking a JavaScript callback: \(error)")
                }
            })
        } catch {
        }
    }
}

#endif
