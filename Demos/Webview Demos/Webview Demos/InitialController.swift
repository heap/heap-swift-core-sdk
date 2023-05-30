import UIKit
import HeapSwiftCore

class InitialController: UIViewController {

    @IBOutlet weak var environmentIdField: UITextField!
    @IBOutlet weak var submitButton: UIButton!
    
    var environmentId: String {
        environmentIdField?.text ?? ""
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        environmentIdField.text = UserDefaults.standard.string(forKey: "environmentId")
        updateSubmitButtonState()
    }
    
    @IBAction func updateSubmitButtonState() {
        submitButton.isEnabled = !environmentId.isEmpty
    }

    @IBAction func submit(_ sender: Any) {
        UserDefaults.standard.set(environmentId, forKey: "environmentId")
        Heap.shared.logLevel = .trace
        Heap.shared.startRecording(environmentId)
        self.performSegue(withIdentifier: "environment", sender: sender)
    }
}
