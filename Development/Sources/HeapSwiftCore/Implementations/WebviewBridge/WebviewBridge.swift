#if canImport(WebKit)

import WebKit

class WebviewBridge: NSObject, WKScriptMessageHandler {
    
    // Generated from https://github.com/heap/heap-webview-core/pull/3/commits/ae43d8abfe6005a37b494528c85c4626c326ef69
    // This is the contents of `dist/bundle/heap-swift-core.js` after `npm run compile:bundles`, but replacing `\` with `\\` because we're in a string.
    static let embeddedScript = WKUserScript(source: """
        (()=>{"use strict";let e=0;const t={};const r="\\nFailed to find a suitable bridge for Heap. All operations will be ignored.\\n\\nIf using HeapSwiftCore (Apple platforms), ensure you are calling Heap.attachWebView with the appropriate origins.\\n".trim();var n,o;const i=null===(o=null===(n=window.webkit)||void 0===n?void 0:n.messageHandlers)||void 0===o?void 0:o.HeapSwiftBridge;function a(e){return["number","boolean","string","bigint"].includes(typeof e)}function s(e,t,r){var n;if(!e)return null;if("object"!=typeof e)return t.debug("Ignoring properties because they are not an object",r),null;const o={};for(const i of Object.keys(e)){const s=e[i];a(s)?o[i]=s.toString():t.debug(`Ignoring property ${i} because the value ${(null===(n=null==s?void 0:s.toString)||void 0===n?void 0:n.call(s))||s} is not a valid property type`,r)}return o}function l(e){return e&&"string"==typeof e}function d(e,t,r){if(!e)return null;if(!l(e.name))return t.debug("Source will be ignored because name was omitted.",r),null;if(!l(e.version))return t.debug("Source will be ignored because version was omitted.",r),null;if(!l(e.platform))return t.debug("Source will be ignored because platform was omitted.",r),null;const n={name:e.name,version:e.version,platform:e.platform},o=s(e.properties,t,r);return o&&(n.properties=o),n}function c(e,t,r,n){if(!l(t))return;const o={logLevel:r,message:t};l(n)&&(o.source=n),e("heapLogger_log",o)}i&&(window.__heapNativeMessage=e=>{(function(e){return"result"===e.type})(e)&&function(e){var r;null===(r=t[e.callbackId])||void 0===r||r.call(t,e),delete t[e.callbackId]}(e)});const u=(i?(r,n)=>{if(!i)return Promise.resolve();const{promise:o,callbackId:a}=function(){const r="cb:"+e++,n=new Promise(((e,n)=>{t[r]=t=>{t.error?n(t.error):e(t.data)}}));return{callbackId:r,promise:n}}();return i.postMessage({type:"invocation",method:r,arguments:n,callbackId:a}),o}:null)||(()=>{let e=!1;return()=>(e||(e=!0,console.warn(r)),Promise.resolve(null))})(),p=(e=>({error(t,r){c(e,t,"error",r)},warn(t,r){c(e,t,"warn",r)},info(t,r){c(e,t,"info",r)},debug(t,r){c(e,t,"debug",r)},trace(t,r){c(e,t,"trace",r)},setLogLevel(t){e("heapLogger_setLogLevel",{logLevel:t})},getLogLevel:()=>e("heapLogger_logLevel",{})}))(u),g=((e,t,r=null)=>{const n=null==r?void 0:r.name,o=d(r,t,n);return{startRecording(r,o){0!==arguments.length?l(r)?e("startRecording",{environmentId:r,options:o||{}}):t.warn("startRecording failed because environmentId was not a string.",n):t.warn("startRecording failed because environmentId was omitted.",n)},stopRecording(){e("stopRecording",{})},track(r,i,a,c){if(0===arguments.length)return void t.warn("track failed because event was omitted.",n);if(!l(r))return void t.warn("track failed because event was not a string.",n);const u=s(i,t,n),p=d(c,t,n)||o,g=function(e,t,r){return e?"function"!=typeof e.getTime?(t.debug("Timestamp will be ignored because it is not a date.",r),null):e.getTime():null}(a,t,n),f={event:r};u&&(f.properties=u),g&&(f.javascriptEpochTimestamp=g),p&&(f.sourceInfo=p),e("track",f)},identify(r){0!==arguments.length?l(r)?e("identify",{identity:r}):t.warn("identify failed because identity was not a string.",n):t.warn("identify failed because identity was omitted.",n)},resetIdentity(){e("resetIdentity",{})},addUserProperties(r){const o=s(r,t,n);o&&(0!==Object.keys(o).length?e("addUserProperties",{properties:o}):t.warn("addUserProperties was called without any valid properties."))},addEventProperties(r){const o=s(r,t,n);o&&(0!==Object.keys(o).length?e("addEventProperties",{properties:o}):t.warn("addUserProperties was called without any valid properties."))},removeEventProperty(r){0!==arguments.length?l(r)?e("removeEventProperty",{name:r}):t.warn("removeEventProperty failed because name was not a string.",n):t.warn("removeEventProperty failed because name was omitted.",n)},clearEventProperties(){e("clearEventProperties",{})},getSessionId:()=>e("sessionId",{}),fetchSessionId:()=>e("fetchSessionId",{}),getUserId:()=>e("userId",{}),getIdentity:()=>e("identity",{})}})(u,p);window.HeapLogger=p,window.Heap=g})();
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
