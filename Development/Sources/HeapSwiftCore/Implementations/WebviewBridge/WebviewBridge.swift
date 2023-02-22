#if canImport(WebKit)

import WebKit

class WebviewBridge: NSObject, WKScriptMessageHandler {
    
    static let embeddedScript = WKUserScript(source: """
        (()=>{"use strict";let e=0;const t={};var o,r;const n=null===(r=null===(o=window.webkit)||void 0===o?void 0:o.messageHandlers)||void 0===r?void 0:r.HeapSwiftBridge;n&&(window.__heapNativeMessage=e=>{(function(e){return"result"===e.type})(e)&&function(e){var o;null===(o=t[e.callbackId])||void 0===o||o.call(t,e),delete t[e.callbackId]}(e)});const i="\\nFailed to find a suitable bridge for Heap. All operations will be ignored.\\n\\nIf using HeapSwiftCore (Apple platforms), ensure you are calling Heap.attachWebView with the appropriate origins.\\n".trim();function l(e){return["number","boolean","string","bigint"].includes(typeof e)}function a(e,t,o){var r;if(!e)return null;if("object"!=typeof e)return t.logDev("Ignoring properties because they are not an object",o),null;const n={};for(const i of Object.keys(e)){const a=e[i];l(a)?n[i]=a.toString():t.logDev(`Ignoring property ${i} because the value ${(null===(r=null==a?void 0:a.toString)||void 0===r?void 0:r.call(a))||a} is not a valid property type`,o)}return n}function s(e){return e&&"string"==typeof e}function d(e,t,o){if(!e)return null;if(!s(e.name))return t.logDebug("Source will be ignored because name was omitted.",o),null;if(!s(e.version))return t.logDebug("Source will be ignored because version was omitted.",o),null;if(!s(e.platform))return t.logDebug("Source will be ignored because platform was omitted.",o),null;const r={name:e.name,version:e.version,platform:e.platform},n=a(e.properties,t,o);return n&&(r.properties=n),r}function c(e,t,o,r){if(!s(t))return;const n={logLevel:o,message:t};s(r)&&(n.source=r),e("heapLogger_log",n)}const g=(n?(o,r)=>{if(!n)return Promise.resolve();const{promise:i,callbackId:l}=function(){const o="cb:"+e++,r=new Promise(((e,r)=>{t[o]=t=>{t.error?r(t.error):e(t.data)}}));return{callbackId:o,promise:r}}();return n.postMessage({type:"invocation",method:o,arguments:r,callbackId:l}),i}:null)||(()=>{let e=!1;return()=>(e||(e=!0,console.warn(i)),Promise.resolve(null))})(),u=(e=>({logCritical(t,o){c(e,t,"critical",o)},logProd(t,o){c(e,t,"prod",o)},logDev(t,o){c(e,t,"dev",o)},logDebug(t,o){c(e,t,"debug",o)},setLogLevel(t){e("heapLogger_setLogLevel",{logLevel:t})},getLogLevel:()=>e("heapLogger_logLevel",{})}))(g),p=((e,t,o=null)=>{const r=null==o?void 0:o.name,n=d(o,t,r);return{startRecording(o,n){0!==arguments.length?s(o)?e("startRecording",{environmentId:o,options:n||{}}):t.logProd("startRecording failed because environmentId was not a string.",r):t.logProd("startRecording failed because environmentId was omitted.",r)},stopRecording(){e("stopRecording",{})},track(o,i,l,c){if(0===arguments.length)return void t.logDev("track failed because event was omitted.",r);if(!s(o))return void t.logDev("track failed because event was not a string.",r);const g=a(i,t,r),u=d(c,t,r)||n,p=function(e,t,o){return e?"function"!=typeof e.getTime?(t.logDev("Timestamp will be ignored because it is not a date.",o),null):e.getTime():null}(l,t,r),v={event:o};g&&(v.properties=g),p&&(v.javascriptEpochTimestamp=p),u&&(v.sourceInfo=u),e("track",v)},identify(o){0!==arguments.length?s(o)?e("identify",{identity:o}):t.logDev("identify failed because identity was not a string.",r):t.logDev("identify failed because identity was omitted.",r)},resetIdentity(){e("resetIdentity",{})},addUserProperties(o){const n=a(o,t,r);n&&(0!==Object.keys(n).length?e("addUserProperties",{properties:n}):t.logDev("addUserProperties was called without any valid properties."))},addEventProperties(o){const n=a(o,t,r);n&&(0!==Object.keys(n).length?e("addEventProperties",{properties:n}):t.logDev("addUserProperties was called without any valid properties."))},removeEventProperty(o){0!==arguments.length?s(o)?e("removeEventProperty",{name:o}):t.logDev("removeEventProperty failed because name was not a string.",r):t.logDev("removeEventProperty failed because name was omitted.",r)},clearEventProperties(){e("clearEventProperties",{})},getSessionId:()=>e("sessionId",{}),getUserId:()=>e("userId",{}),getIdentity:()=>e("identity",{})}})(g,u);window.HeapLogger=u,window.Heap=p})();
    """, injectionTime: .atDocumentStart, forMainFrameOnly: true)
    
    weak var webView: WKWebView?
    let origins: [Origin]
    let injectHeapJavaScript: Bool

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
        
        HeapLogger.shared.logDebug("Web view received the following message:\n\(message.body)")
        
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
        
        HeapLogger.shared.logDebug("Web view received an unknown message over the JavaScript bridge.")
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
            
            webView.evaluateJavaScript("window.__heapNativeMessage(\(jsonString))", in: frame, in: world, completionHandler: { result in
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
