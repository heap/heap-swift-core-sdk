#if canImport(WebKit)
import XCTest
import Quick
import Nimble
import WebKit
@testable import HeapSwiftCore
@testable import HeapSwiftCoreTestSupport

final class WebviewBridgeSpec: HeapSpec {
    
    override func spec() {
        describe("WebviewBridge") {
            describe("register") {
                it("persists the bridge") {
                    let webView = WKWebView(frame: .zero)
                    weak var weakBridge: WebviewBridge?
                    defer { weakBridge?.remove() }
                    
                    autoreleasepool {
                        let bridge = WebviewBridge(webView: webView, origins: ["*"])
                        bridge.register()
                        weakBridge = bridge
                    }
                    expect(weakBridge).notTo(beNil())
                }
                
                it("sets heapWebviewBridge") {
                    let webView = WKWebView(frame: .zero)
                    let bridge = WebviewBridge(webView: webView, origins: ["*"])
                    defer { bridge.remove() }
                    
                    bridge.register()
                    expect(webView.heapWebviewBridge).to(equal(bridge))
                }
                
                // This is a proxy for checking that `register` fails when already registered.
                it("does not override heapWebviewBridge when already set") {
                    
                    let webView = WKWebView(frame: .zero)
                    let bridge1 = WebviewBridge(webView: webView, origins: ["*"])
                    let bridge2 = WebviewBridge(webView: webView, origins: ["*"])
                    defer { bridge1.remove(); bridge2.remove() }
                    
                    bridge1.register()
                    bridge2.register()
                    expect(webView.heapWebviewBridge).to(equal(bridge1))
                }
            }
            
            describe("remove") {
                it("clears heapWebviewBridge") {
                    let webView = WKWebView(frame: .zero)
                    let bridge = WebviewBridge(webView: webView, origins: ["*"])
                    bridge.register()
                    bridge.remove()
                    expect(webView.heapWebviewBridge).to(beNil())
                }
                
                it("does not clear the bridge if isn't the registered bridge") {
                    let webView = WKWebView(frame: .zero)
                    let bridge1 = WebviewBridge(webView: webView, origins: ["*"])
                    let bridge2 = WebviewBridge(webView: webView, origins: ["*"])
                    bridge1.register()
                    bridge2.remove()
                    expect(webView.heapWebviewBridge).to(equal(bridge1))
                }
                
                it("lets the bridge get deallocated") {
                    let webView = WKWebView(frame: .zero)
                    weak var weakBridge: WebviewBridge?
                    
                    autoreleasepool {
                        let bridge = WebviewBridge(webView: webView, origins: ["*"])
                        bridge.register()
                        bridge.remove()
                        weakBridge = bridge
                    }
                    expect(weakBridge).toEventually(beNil())
                }

                it("lets register get called again") {
                    let webView = WKWebView(frame: .zero)
                    let bridge1 = WebviewBridge(webView: webView, origins: ["*"])
                    let bridge2 = WebviewBridge(webView: webView, origins: ["*"])
                    bridge1.register()
                    bridge1.remove()
                    bridge2.register()
                    expect(webView.heapWebviewBridge).to(equal(bridge2))
                }
            }
            
            describe("detachWebView") {
                it("removes the attached listener") {
                    let webView = WKWebView(frame: .zero)
                    weak var weakBridge: WebviewBridge?
                    
                    autoreleasepool {
                        WebviewBridge(webView: webView, origins: ["*"]).register()
                        WebviewBridge.detachWebView(webView)
                    }
                    
                    expect(weakBridge).toEventually(beNil())
                }
            }
            
            // This test consistently passes locally but is flaky on the CI. Since we don't control _when_ the webview
            // deallocates and it can take a shockingly long time, we need to disable the test.
            xit("removes itself when the web view deallocates") {
                weak var weakWebView: WKWebView?
                weak var weakBridge: WebviewBridge?
                
                autoreleasepool {
                    let webView = WKWebView(frame: .zero)
                    let bridge = WebviewBridge(webView: webView, origins: ["*"])
                    bridge.register()
                    weakWebView = webView
                    weakBridge = bridge
                }
                
                // The webview can take a variable amount of time to free itself, give it some slack.
                expect(weakWebView).toEventually(beNil(), timeout: .seconds(5), description: "PRECONDITION")
                expect(weakBridge).to(beNil())
            }
        }
    }
}
#endif
