import UIKit
import WebKit
import HeapSwiftCore

class HeapJSTestController: UIViewController {

    @IBOutlet weak var webview: WKWebView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if #available(iOS 16.4, *) {
            webview.isInspectable = true
        }
        
        guard
            let urlString = UserDefaults.standard.string(forKey: "url"),
            let url = URL(string: urlString),
            let origin = UserDefaults.standard.string(forKey: "origin"),
            let domain = UserDefaults.standard.string(forKey: "domain"),
            let path = UserDefaults.standard.string(forKey: "path")
        else {
            return // Sad
        }
        
        let secure = UserDefaults.standard.bool(forKey: "secure")
        
        Heap.shared.attachWebView(webview, origins: [origin], bindHeapJsWith: .init(domain: domain, path: path, secure: secure))
        webview.load(URLRequest(url: url))
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
