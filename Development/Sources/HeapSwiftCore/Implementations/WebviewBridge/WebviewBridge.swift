#if canImport(WebKit)

import WebKit
import HeapSwiftCoreInterfaces

class WebviewBridge: NSObject, WKScriptMessageHandler {
    
    // Generated from https://github.com/heap/heap-webview-core/pull/9/commits/86d92e1fd836cd18d55b3dc9fb897449eff1f7ac
    // This is the contents of `dist/heap-swift-core.js` after `npm run compile:bundles`, but replacing `\` with `\\` because we're in a string.
    static let embeddedScript = WKUserScript(source: """
        (()=>{"use strict";var e,t,r,n,i,o,a={175:(e,t)=>{Object.defineProperty(t,"__esModule",{value:!0}),t.createNoopBridge=void 0;var r="\\nFailed to find a suitable bridge for Heap. All operations will be ignored.\\n\\nIf using HeapSwiftCore (Apple platforms), ensure you are calling Heap.attachWebView with the appropriate origins.\\n".trim();t.createNoopBridge=function(){var e=!1;return function(){return e||(e=!0,console.warn(r)),Promise.resolve(null)}}},367:function(e,t,r){var n=this&&this.__createBinding||(Object.create?function(e,t,r,n){void 0===n&&(n=r);var i=Object.getOwnPropertyDescriptor(t,r);i&&!("get"in i?!t.__esModule:i.writable||i.configurable)||(i={enumerable:!0,get:function(){return t[r]}}),Object.defineProperty(e,n,i)}:function(e,t,r,n){void 0===n&&(n=r),e[n]=t[r]}),i=this&&this.__exportStar||function(e,t){for(var r in e)"default"===r||Object.prototype.hasOwnProperty.call(t,r)||n(t,e,r)};Object.defineProperty(t,"__esModule",{value:!0}),t.createNoopBridge=void 0;var o=r(175);Object.defineProperty(t,"createNoopBridge",{enumerable:!0,get:function(){return o.createNoopBridge}}),i(r(576),t)},576:(e,t)=>{Object.defineProperty(t,"__esModule",{value:!0}),t.isHeapSDKInvocation=t.isHeapSDKInvocationResult=void 0,t.isHeapSDKInvocationResult=function(e){return"result"===e.type},t.isHeapSDKInvocation=function(e){return"invocation"===e.type}},154:(e,t,r)=>{Object.defineProperty(t,"__esModule",{value:!0}),t.createHeap=void 0;var n=r(502);t.createHeap=function(e,t,r){void 0===r&&(r=null);var i=null==r?void 0:r.name,o=(0,n.sanitizeSourceInfo)(r,t,i);return{startRecording:function(r,o){0!==arguments.length?(0,n.isNonEmptyString)(r)?e("startRecording",{environmentId:r,options:o||{}}):t.warn("startRecording failed because environmentId was not a string.",i):t.warn("startRecording failed because environmentId was omitted.",i)},stopRecording:function(){e("stopRecording",{})},track:function(r,a,c,s){if(0!==arguments.length)if((0,n.isNonEmptyString)(r)){var u=(0,n.sanitizeProperties)(a,t,i),l=(0,n.sanitizeSourceInfo)(s,t,i)||o,d=(0,n.sanitizeTimestamp)(c,t,i),p={event:r};u&&(p.properties=u),d&&(p.javascriptEpochTimestamp=d),l&&(p.sourceLibrary=l),e("track",p)}else t.warn("track failed because event was not a string.",i);else t.warn("track failed because event was omitted.",i)},identify:function(r){0!==arguments.length?(0,n.isNonEmptyString)(r)?e("identify",{identity:r}):t.warn("identify failed because identity was not a string.",i):t.warn("identify failed because identity was omitted.",i)},resetIdentity:function(){e("resetIdentity",{})},addUserProperties:function(r){var o=(0,n.sanitizeProperties)(r,t,i);o&&(0!==Object.keys(o).length?e("addUserProperties",{properties:o}):t.warn("addUserProperties was called without any valid properties."))},addEventProperties:function(r){var o=(0,n.sanitizeProperties)(r,t,i);o&&(0!==Object.keys(o).length?e("addEventProperties",{properties:o}):t.warn("addUserProperties was called without any valid properties."))},removeEventProperty:function(r){0!==arguments.length?(0,n.isNonEmptyString)(r)?e("removeEventProperty",{name:r}):t.warn("removeEventProperty failed because name was not a string.",i):t.warn("removeEventProperty failed because name was omitted.",i)},clearEventProperties:function(){e("clearEventProperties",{})},setLogLevel:function(e){t.setLogLevel(e)},getSessionId:function(){return e("sessionId",{})},fetchSessionId:function(){return e("fetchSessionId",{})},getUserId:function(){return e("userId",{})},getIdentity:function(){return e("identity",{})}}}},502:function(e,t,r){var n=this&&this.__values||function(e){var t="function"==typeof Symbol&&Symbol.iterator,r=t&&e[t],n=0;if(r)return r.call(e);if(e&&"number"==typeof e.length)return{next:function(){return e&&n>=e.length&&(e=void 0),{value:e&&e[n++],done:!e}}};throw new TypeError(t?"Object is not iterable.":"Symbol.iterator is not defined.")};Object.defineProperty(t,"__esModule",{value:!0}),t.sanitizeTimestamp=t.sanitizeSourceInfo=t.isNonEmptyString=t.sanitizeProperties=void 0;var i=r(748);function o(e,t,r){var o,a,c;if(!e)return null;if("object"!=typeof e)return t.debug("Ignoring properties because they are not an object",r),null;var s={};try{for(var u=n(Object.keys(e)),l=u.next();!l.done;l=u.next()){var d=l.value,p=e[d];(0,i.isPropertyValue)(p)?s[d]=p.toString():t.debug("Ignoring property ".concat(d," because the value ").concat((null===(c=null==p?void 0:p.toString)||void 0===c?void 0:c.call(p))||p," is not a valid property type"),r)}}catch(e){o={error:e}}finally{try{l&&!l.done&&(a=u.return)&&a.call(u)}finally{if(o)throw o.error}}return s}function a(e){return e&&"string"==typeof e}t.sanitizeProperties=o,t.isNonEmptyString=a,t.sanitizeSourceInfo=function(e,t,r){if(!e)return null;if(!a(e.name))return t.debug("Source will be ignored because name was omitted.",r),null;if(!a(e.version))return t.debug("Source will be ignored because version was omitted.",r),null;if(!a(e.platform))return t.debug("Source will be ignored because platform was omitted.",r),null;var n={name:e.name,version:e.version,platform:e.platform},i=o(e.properties,t,r);return i&&(n.properties=i),n},t.sanitizeTimestamp=function(e,t,r){return e?"function"!=typeof e.getTime?(t.debug("Timestamp will be ignored because it is not a date.",r),null):e.getTime():null}},748:(e,t)=>{Object.defineProperty(t,"__esModule",{value:!0}),t.isPropertyValue=void 0,t.isPropertyValue=function(e){return["number","boolean","string","bigint"].includes(typeof e)}},482:(e,t,r)=>{Object.defineProperty(t,"__esModule",{value:!0}),t.isHeapSDKInvocationResult=t.isHeapSDKInvocation=t.createNoopBridge=t.createLogger=t.createHeap=void 0;var n=r(154);Object.defineProperty(t,"createHeap",{enumerable:!0,get:function(){return n.createHeap}});var i=r(123);Object.defineProperty(t,"createLogger",{enumerable:!0,get:function(){return i.createLogger}});var o=r(367);Object.defineProperty(t,"createNoopBridge",{enumerable:!0,get:function(){return o.createNoopBridge}}),Object.defineProperty(t,"isHeapSDKInvocation",{enumerable:!0,get:function(){return o.isHeapSDKInvocation}}),Object.defineProperty(t,"isHeapSDKInvocationResult",{enumerable:!0,get:function(){return o.isHeapSDKInvocationResult}})},123:(e,t,r)=>{Object.defineProperty(t,"__esModule",{value:!0}),t.createLogger=void 0;var n=r(502);function i(e,t,r,i){if((0,n.isNonEmptyString)(t)){var o={logLevel:r,message:t};(0,n.isNonEmptyString)(i)&&(o.source=i),e("heapLogger_log",o)}}t.createLogger=function(e){return{error:function(t,r){i(e,t,"error",r)},warn:function(t,r){i(e,t,"warn",r)},info:function(t,r){i(e,t,"info",r)},debug:function(t,r){i(e,t,"debug",r)},trace:function(t,r){i(e,t,"trace",r)},setLogLevel:function(t){e("heapLogger_setLogLevel",{logLevel:t})},getLogLevel:function(){return e("heapLogger_logLevel",{})}}}},695:(e,t,r)=>{var n,i;Object.defineProperty(t,"__esModule",{value:!0}),t.getSwiftInvocationHandler=void 0;var o=r(482),a=r(569),c=null===(i=null===(n=window.webkit)||void 0===n?void 0:n.messageHandlers)||void 0===i?void 0:i.HeapSwiftBridge,s=function(e,t){if(!c)return Promise.resolve();var r=(0,a.createCallback)(),n=r.promise,i=r.callbackId;return c.postMessage({type:"invocation",method:e,arguments:t,callbackId:i}),n};c&&(window.__heapNativeMessage=function(e){(0,o.isHeapSDKInvocationResult)(e)&&(0,a.dispatchCallback)(e)}),t.getSwiftInvocationHandler=function(){return c?s:null}},569:(e,t)=>{Object.defineProperty(t,"__esModule",{value:!0}),t.dispatchCallback=t.createCallback=void 0;var r=0,n={};t.createCallback=function(){var e="cb:".concat(r++),t=new Promise((function(t,r){n[e]=function(e){e.error?r(e.error):t(e.data)}}));return{callbackId:e,promise:t}},t.dispatchCallback=function(e){var t;null===(t=n[e.callbackId])||void 0===t||t.call(n,e),delete n[e.callbackId]}}},c={};function s(e){var t=c[e];if(void 0!==t)return t.exports;var r=c[e]={exports:{}};return a[e].call(r.exports,r,r.exports,s),r.exports}e=s(482),t=s(482),r=s(482),n=(0,s(695).getSwiftInvocationHandler)()||(0,e.createNoopBridge)(),i=(0,r.createLogger)(n),o=(0,t.createHeap)(n,i),window.HeapLogger=i,window.Heap=o})();
    """, injectionTime: .atDocumentStart, forMainFrameOnly: true)
    
    weak var webView: WKWebView?
    let origins: [Origin]
    let injectHeapJavaScript: Bool
    
    // Keep a list of rejected origins so we don't log incessantly about it.
    var rejectedOriginDescriptions: Set<String> = []

    init(webView: WKWebView, origins: Set<String>, injectHeapJavaScript: Bool) {
        self.webView = webView
        self.origins = origins.compactMap(Origin.init(rawValue:))
        self.injectHeapJavaScript = injectHeapJavaScript
    }
    
    func register() {
        
        guard let webView = webView else { return }
        
        webView.configuration.userContentController.add(self, name: "HeapSwiftBridge")
        
        if injectHeapJavaScript {
            webView.configuration.userContentController.addUserScript(WebviewBridge.embeddedScript)
        }
        
        HeapLogger.shared.debug("Heap attached to web view with allowed origins: \(origins.map(\.description).joined(separator: ", "))")
    }
    
    func remove() {
        webView?.configuration.userContentController.removeScriptMessageHandler(forName: "HeapSwiftBridge")
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
                    let data = try HeapBridgeSupport.shared.handleInvocation(method: method, arguments: arguments)
                    replyWithData(data?._toHeapJSON() ?? JSON.null, to: message, callbackId: callbackId)
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
        
        HeapLogger.shared.trace("Web view received an unknown message over the JavaScript bridge.")
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
        HeapLogger.shared.trace("Sending message to web view: \(payload)")
        
        do {
            let data = try JSONEncoder().encode(payload)
            guard let jsonString = String(data: data, encoding: .utf8) else { return }
            
            webView.evaluateJavaScript("window.__heapNativeMessage(\(jsonString))", in: frame, in: world, completionHandler: { result in
                if case .failure(let error) = result {
                    HeapLogger.shared.warn("An error occured while invoking a JavaScript callback: \(error)")
                }
            })
        } catch {
        }
    }
    
    func send(_ payload: Encodable) {
        guard let webView = webView else { return }
        HeapLogger.shared.trace("Sending message to web view: \(payload)")
        
        do {
            let data = try JSONEncoder().encode(payload)
            guard let jsonString = String(data: data, encoding: .utf8) else { return }

            webView.evaluateJavaScript("window.Heap.nativeMessage(\(jsonString))", completionHandler: { _, error in
                if let error = error {
                    HeapLogger.shared.warn("An error occured while invoking a JavaScript callback: \(error)")
                }
            })
        } catch {
        }
    }
}

#endif
