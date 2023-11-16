import UIKit
import WebKit
import HeapSwiftCore

import UIKit

class JavaScriptBridgeController: UIViewController {
    
    @IBOutlet weak var webview: WKWebView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if #available(iOS 16.4, *) {
            webview.isInspectable = true
        }

        Heap.shared.attachWebView(webview, origins: ["https://example.com"], injectHeapJavaScript: true)
        
        let htmlFile = Bundle.main.url(forResource: "javascript-bridge", withExtension: "html")
        let html = try! String(contentsOf: htmlFile!)
        webview.loadHTMLString(html, baseURL: URL(string: "https://example.com"))
    }
    
    deinit {
        Heap.shared.detachWebView(webview)
    }
}
