//
//  HeapJSConfigController.swift
//  Webview Demos
//
//  Created by Brian Nickel on 5/23/23.
//

import UIKit

class HeapJSConfigController: UIViewController {
    
    
    @IBOutlet weak var urlField: UITextField!
    @IBOutlet weak var originField: UITextField!
    @IBOutlet weak var domainField: UITextField!
    @IBOutlet weak var pathField: UITextField!
    @IBOutlet weak var secureField: UISwitch!
    @IBOutlet weak var submitButton: UIButton!
    
    var url: URL? {
        guard
            let text = urlField.text,
            let url = URL(string: text)
        else { return nil }
        return url
    }
    
    var origin: String {
        originField.text ?? ""
    }
    
    var domain: String {
        domainField.text ?? ""
    }
    
    var path: String {
        pathField.text ?? ""
    }
    
    var secure: Bool {
        secureField.isOn
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        urlField.text = UserDefaults.standard.string(forKey: "url")
        originField.text = UserDefaults.standard.string(forKey: "origin")
        domainField.text = UserDefaults.standard.string(forKey: "domain")
        pathField.text = UserDefaults.standard.string(forKey: "path")
        secureField.isOn = UserDefaults.standard.bool(forKey: "secure")
    }
    
    @IBAction func updateSubmitButtonState() {
        submitButton.isEnabled = url != nil && !origin.isEmpty && !domain.isEmpty && !path.isEmpty
    }

    @IBAction func submit(_ sender: Any) {
        UserDefaults.standard.set(url?.absoluteString, forKey: "url")
        UserDefaults.standard.set(origin, forKey: "origin")
        UserDefaults.standard.set(domain, forKey: "domain")
        UserDefaults.standard.set(path, forKey: "path")
        UserDefaults.standard.set(secure, forKey: "secure")
        self.performSegue(withIdentifier: "test", sender: sender)
    }
}
