import UIKit
import MobileCoreServices
import os.log
import SwiftUI
import WebKit  // 追加

class ActionViewController: UIViewController {

    var pageTitle: String?
    var pageYield: String?
    var pageIngredients:[String]?
    var pageUnits:[String]?
    var pageURL: String?


    override func viewDidLoad() {
        super.viewDidLoad()

        // Get the item[s] we're handling from the extension context.
        if let item = self.extensionContext?.inputItems.first as? NSExtensionItem {
            for provider in item.attachments! {
                if provider.hasItemConformingToTypeIdentifier(kUTTypePropertyList as String) {
                    print("Loading item...")  // Changed os_log to print
                    provider.loadItem(forTypeIdentifier: kUTTypePropertyList as String, options: nil, completionHandler: { (result, error) in
                        if let error = error {
                            print("Error loading item: \(error.localizedDescription)")  // Changed os_log to print
                            return
                        }
                        print("Item loaded.")  // Changed os_log to print
                        if let resultDictionary = result as? NSDictionary, let javaScriptValues = resultDictionary[NSExtensionJavaScriptPreprocessingResultsKey] as? NSDictionary {
                            self.pageTitle = javaScriptValues["title"] as? String
                            self.pageYield = javaScriptValues["yield"] as? String ?? "" // If yield is null, set it as an empty string
                            self.pageIngredients = javaScriptValues["ingredients"] as? [String]
                            self.pageUnits = javaScriptValues["units"] as? [String]
                            self.pageURL = javaScriptValues["url"] as? String
                            print("Page Title: \(self.pageTitle ?? "nil")")  // Changed os_log to print
                            print("Page yield: \(self.pageYield ?? "nil")")  // Changed os_log to print
                            print("Page ingredients: \(self.pageIngredients ?? ["nil"])")  // Changed os_log to print
                        }

                    })
                }
            }
        }
    }



    @IBAction func done() {
        if let pageTitle = pageTitle, let pageYield = pageYield, let pageIngredients = pageIngredients, let pageUnits = pageUnits, let pageURL = pageURL {
            setSharedData(title: pageTitle, yield: pageYield, ingredients: pageIngredients, units: pageUnits, url: pageURL)
        }
        self.extensionContext!.completeRequest(returningItems: self.extensionContext!.inputItems, completionHandler: nil)
    }

    func setSharedData(title: String, yield: String, ingredients: [String], units: [String], url: String) {
        let defaults = UserDefaults(suiteName: "group.takayuki.hashimoto.menuplannerapp.batch")
        defaults?.set(title, forKey: "title")
        defaults?.set(yield, forKey: "yield")
        defaults?.set(ingredients, forKey: "ingredients")
        defaults?.set(units, forKey: "units")
        defaults?.set(url, forKey: "url")
        defaults?.synchronize()
    }
}
