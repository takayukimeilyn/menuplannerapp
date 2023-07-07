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
    
    // UI要素を追加
    let titleLabel = UILabel()
    let yieldLabel = UILabel()
    let ingredientsLabel = UILabel()
    
    // 前回のデータを表示するラベルを追加
    let prevTitleLabel = UILabel()
    let prevYieldLabel = UILabel()
    let prevIngredientsLabel = UILabel()

    override func viewDidLoad() {
        super.viewDidLoad()
        // UI要素の設定
        titleLabel.frame = CGRect(x: 20, y: 80, width: 280, height: 20)
        yieldLabel.frame = CGRect(x: 20, y: 110, width: 280, height: 20)
        ingredientsLabel.frame = CGRect(x: 20, y: 140, width: 280, height: 60)
        ingredientsLabel.numberOfLines = 0
        
        self.view.addSubview(titleLabel)
        self.view.addSubview(yieldLabel)
        self.view.addSubview(ingredientsLabel)
        
        // 前回のデータを表示するラベルの設定
        prevTitleLabel.frame = CGRect(x: 20, y: 200, width: 280, height: 20)
        prevYieldLabel.frame = CGRect(x: 20, y: 230, width: 280, height: 20)
        prevIngredientsLabel.frame = CGRect(x: 20, y: 260, width: 280, height: 60)
        prevIngredientsLabel.numberOfLines = 0

        self.view.addSubview(prevTitleLabel)
        self.view.addSubview(prevYieldLabel)
        self.view.addSubview(prevIngredientsLabel)

        loadPreviousData()
        

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
                            
                            // UI要素にデータをセット
                            DispatchQueue.main.async {
                                self.titleLabel.text = "Title: \(self.pageTitle ?? "nil")"
                                self.yieldLabel.text = "Yield: \(self.pageYield ?? "nil")"
                                self.ingredientsLabel.text = "Ingredients: \(self.pageIngredients?.joined(separator: ", ") ?? "nil")"
                            }
                        }
                    })
                }
            }
        }
    }
    
    func loadPreviousData() {
        let defaults = UserDefaults(suiteName: "group.takayuki.hashimoto.menuplannerapp.batch")
        let prevTitle = defaults?.string(forKey: "title") ?? "nil"
        let prevYield = defaults?.string(forKey: "yield") ?? "nil"
        let prevIngredients = defaults?.object(forKey: "ingredients") as? [String] ?? ["nil"]
        
        prevTitleLabel.text = "Before Title: \(prevTitle)"
        prevYieldLabel.text = "Before Yield: \(prevYield)"
        prevIngredientsLabel.text = "Before Ingredients: \(prevIngredients.joined(separator: ", "))"
    }


    @IBAction func done() {
        if let pageTitle = pageTitle, let pageYield = pageYield, let pageIngredients = pageIngredients, let pageUnits = pageUnits, let pageURL = pageURL {
            setSharedData(title: pageTitle, yield: pageYield, ingredients: pageIngredients, units: pageUnits, url: pageURL)
        }
        self.extensionContext!.completeRequest(returningItems: self.extensionContext!.inputItems, completionHandler: nil)
    }

//    func setSharedData(title: String, yield: String, ingredients: [String], units: [String], url: String) {
//        let defaults = UserDefaults(suiteName: "group.takayuki.hashimoto.menuplannerapp.batch")
//        defaults?.set(title, forKey: "title")
//        defaults?.set(yield, forKey: "yield")
//        defaults?.set(ingredients, forKey: "ingredients")
//        defaults?.set(units, forKey: "units")
//        defaults?.set(url, forKey: "url")
//        defaults?.synchronize()
//    }
    func setSharedData(title: String, yield: String, ingredients: [String], units: [String], url: String) {
        let defaults = UserDefaults(suiteName: "group.takayuki.hashimoto.menuplannerapp.batch")
        
        // 共有するデータを辞書として保存
        let dataDictionary: [String: Any] = ["title": title, "yield": yield, "ingredients": ingredients, "units": units, "url": url]
        
        // 既存のデータを取得
        var sharedDataArray = defaults?.array(forKey: "sharedData") as? [[String: Any]] ?? []
        
        // 新しいデータを追加
        sharedDataArray.append(dataDictionary)
        
        // 更新されたデータを保存
        defaults?.set(sharedDataArray, forKey: "sharedData")
        defaults?.synchronize()
    }

}
