import UIKit
import WebKit
import HeapSwiftCore

class HybridViewController: UIViewController {
    
    @IBOutlet var webview: WKWebView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        Heap.shared.attachWebView(webview, origins: ["https://example.com"], injectHeapJavaScript: true)

        let htmlFile = Bundle.main.url(forResource: "index", withExtension: "html")
        let html = try! String(contentsOf: htmlFile!)
        webview.loadHTMLString(html, baseURL: URL(string: "https://example.com"))
    }
}
