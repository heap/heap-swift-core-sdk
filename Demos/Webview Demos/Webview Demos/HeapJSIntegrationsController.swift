import UIKit
import WebKit
import HeapSwiftCore

class HeapJSIntegrationsController: UIViewController {

    @IBOutlet weak var webview: WKWebView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if #available(iOS 16.4, *) {
            webview.isInspectable = true
        }
        
        Heap.shared.attachWebView(webview, origins: ["https://example.com"], bindHeapJsWith: .init(domain: ".example.com"))
        
        let htmlFile = Bundle.main.url(forResource: "heapjs-integrations", withExtension: "html")
        let html = try! String(contentsOf: htmlFile!)
        webview.loadHTMLString(html, baseURL: URL(string: "https://example.com"))
    }

    @IBAction func identify(_ sender: Any) {
        Heap.shared.identify("webview user")
    }
    
    @IBAction func resetIdentity(_ sender: Any) {
        Heap.shared.resetIdentity()
    }
    
    deinit {
        Heap.shared.detachWebView(webview)
    }
}
