import UIKit
import MobileCoreServices

class ActionViewController: UIViewController {

    var urlString: String?

    override func viewDidLoad() {
        super.viewDidLoad()
    
        // Get the item[s] we're handling from the extension context.
        if let item = self.extensionContext?.inputItems.first as? NSExtensionItem {
            for provider in item.attachments! {
                if provider.hasItemConformingToTypeIdentifier(kUTTypeURL as String) {
                    provider.loadItem(forTypeIdentifier: kUTTypeURL as String, options: nil, completionHandler: { (url, error) in
                        if let shareURL = url as? URL {
                            self.urlString = shareURL.absoluteString
                            print("Shared URL: \(self.urlString ?? "No URL")")
                        }
                    })
                }
            }
        }
    }

    @IBAction func done() {
        // Return any edited content to the host app.
        // This template doesn't do anything, so we just echo the passed in items.
        if let urlString = urlString {
            setSharedURL(url: urlString)
        }
        self.extensionContext!.completeRequest(returningItems: self.extensionContext!.inputItems, completionHandler: nil)
    }
    
    func setSharedURL(url: String) {
        let defaults = UserDefaults(suiteName: "group.takayuki.hashimoto.menuplannerapp.batch")
        defaults?.set(url, forKey: "url")
        defaults?.synchronize()
    }
}
