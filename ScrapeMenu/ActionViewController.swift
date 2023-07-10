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
    var pageImages: [String]?
    
    // UI要素を追加
    let titleLabel = UILabel()
    let yieldLabel = UILabel()
    let ingredientsLabel = UILabel()
    let pageImageView = UIImageView()  // 新たに追加


    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.backgroundColor = UIColor(white: 0.9, alpha: 1.0)  //薄めのグレー
        

        // UI要素の設定
        let spacing: CGFloat = 10.0 // ラベル間の余白
        
        titleLabel.frame = CGRect(x: 20, y: 80, width: self.view.frame.width - 40, height: 30)
        titleLabel.backgroundColor = .white
        titleLabel.layer.cornerRadius = 5.0

        yieldLabel.frame = CGRect(x: 20, y: titleLabel.frame.origin.y + titleLabel.frame.size.height + spacing, width: self.view.frame.width - 40, height: 30)
        yieldLabel.backgroundColor = .white
        yieldLabel.layer.cornerRadius = 5.0

        ingredientsLabel.frame = CGRect(x: 20, y: yieldLabel.frame.origin.y + yieldLabel.frame.size.height + spacing, width: self.view.frame.width - 40, height: 120)
        ingredientsLabel.numberOfLines = 0
        ingredientsLabel.backgroundColor = .white
        ingredientsLabel.layer.cornerRadius = 5.0
        
        // ImageViewの配置を定義します
        pageImageView.frame = CGRect(x: 20, y: ingredientsLabel.frame.origin.y + ingredientsLabel.frame.size.height + spacing, width: self.view.frame.width - 40, height: 200)
        pageImageView.backgroundColor = .lightGray
        pageImageView.contentMode = .scaleAspectFit  // 画像のアスペクト比を保持しつつ表示
        
        self.view.addSubview(titleLabel)
        self.view.addSubview(yieldLabel)
        self.view.addSubview(ingredientsLabel)
        self.view.addSubview(pageImageView)  // ビューにImageViewを追加

        

        // Get the item[s] we're handling from the extension context.
        if let item = self.extensionContext?.inputItems.first as? NSExtensionItem {
            for provider in item.attachments! {
                if provider.hasItemConformingToTypeIdentifier(kUTTypePropertyList as String) {
                    provider.loadItem(forTypeIdentifier: kUTTypePropertyList as String, options: nil, completionHandler: { (result, error) in
                        if let error = error {
                            print("Error loading item: \(error.localizedDescription)")  // Changed os_log to print
                            return
                        }
                        if let resultDictionary = result as? NSDictionary, let javaScriptValues = resultDictionary[NSExtensionJavaScriptPreprocessingResultsKey] as? NSDictionary {
                            self.pageTitle = javaScriptValues["title"] as? String
                            self.pageYield = javaScriptValues["yield"] as? String ?? "" // If yield is null, set it as an empty string
                            self.pageIngredients = javaScriptValues["ingredients"] as? [String]
                            self.pageUnits = javaScriptValues["units"] as? [String]
                            self.pageURL = javaScriptValues["url"] as? String
                            self.pageImages = javaScriptValues["images"] as? [String]

                            
                            // UI要素にデータをセット
                            DispatchQueue.main.async {
                                self.titleLabel.text = "メニュー名: \(self.pageTitle ?? "nil")"
                                self.yieldLabel.text = "数量: \(self.pageYield ?? "nil")"
                                self.ingredientsLabel.text = "材料: \(self.pageIngredients?.joined(separator: ", ") ?? "nil")"
                                if let firstImageURL = self.pageImages?.first, let url = URL(string: firstImageURL), let data = try? Data(contentsOf: url) {
                                    self.pageImageView.image = UIImage(data: data)
                                }
                            }
                        }
                    })
                }
            }
        }
    }

    @IBAction func done() {
        if let pageTitle = pageTitle, let pageYield = pageYield, let pageIngredients = pageIngredients, let pageUnits = pageUnits, let pageURL = pageURL, let pageImages = pageImages {
                setSharedData(title: pageTitle, yield: pageYield, ingredients: pageIngredients, units: pageUnits, url: pageURL, images: pageImages)
            }
            self.extensionContext!.completeRequest(returningItems: self.extensionContext!.inputItems, completionHandler: nil)
    }

    @IBAction func backToOriginalSite(_ sender: Any) {
        self.extensionContext!.completeRequest(returningItems: self.extensionContext!.inputItems, completionHandler: nil)
    }
    
    func setSharedData(title: String, yield: String, ingredients: [String], units: [String], url: String, images: [String]) {
        let defaults = UserDefaults(suiteName: "group.takayuki.hashimoto.menuplannerapp.batch")
        
        // 共有するデータを辞書として保存
        let dataDictionary: [String: Any] = ["title": title, "yield": yield, "ingredients": ingredients, "units": units, "url": url, "images": images]
        
        // 既存のデータを取得
        var sharedDataArray = defaults?.array(forKey: "sharedData") as? [[String: Any]] ?? []
        
        // 新しいデータを追加
        sharedDataArray.append(dataDictionary)
        
        // 更新されたデータを保存
        defaults?.set(sharedDataArray, forKey: "sharedData")
        defaults?.synchronize()
    }
}
