//
//  MenuPlannerAppApp.swift
//  MenuPlannerApp
//
//  Created by 橋本隆之 on 2023/05/27.
//

import SwiftUI
import GoogleMobileAds

@main
struct MenuPlannerAppApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
                .onAppear(perform: persistenceController.loadDataAndSave)  // updated line
                .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
                    persistenceController.loadDataAndSave()
                }
        }
    }
}

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        // Start Google Mobile Ads
        GADMobileAds.sharedInstance().start(completionHandler: nil)
        GADMobileAds.sharedInstance().requestConfiguration.testDeviceIdentifiers = [ "792e6321be57a6ad9399deb261a42224" ]
        GADMobileAds.sharedInstance().start { (status: GADInitializationStatus) in
          print("AdMob Ads SDK initialization status: \(status.description)")
        }
        
        UserDefaults(suiteName: "group.takayuki.hashimoto.menuplannerapp.batch")?.synchronize()
        PersistenceController.shared.loadDataAndSave()
        
        // 初回起動時にサンプルデータを生成
        PersistenceController.shared.initializeSampleDataIfNeeded()

        return true
    }

    func applicationWillEnterForeground(_ application: UIApplication) { // 修正した行
//        UserDefaults(suiteName: "group.takayuki.hashimoto.menuplannerapp.batch")?.synchronize()
//        PersistenceController.shared.loadDataAndSave()
//        PersistenceController.shared.container.viewContext.refreshAllObjects()
    }
}

// UIViewRepresentable wrapper for AdMob banner view
struct AdBannerView: UIViewRepresentable {
    let adUnitID: String

    func makeUIView(context: Context) -> GADBannerView {
        let bannerView = GADBannerView(adSize: GADAdSizeFromCGSize(CGSize(width: 320, height: 50))) // Set your desired banner ad size
        bannerView.adUnitID = adUnitID
        bannerView.rootViewController = UIApplication.shared.windows.first?.rootViewController
        bannerView.load(GADRequest())
        return bannerView
    }

    func updateUIView(_ uiView: GADBannerView, context: Context) {}
}

extension PersistenceController {
    func loadDataAndSave() {
        let defaults = UserDefaults(suiteName: "group.takayuki.hashimoto.menuplannerapp.batch")
        defaults?.synchronize()
        
        guard let sharedDataArray = defaults?.array(forKey: "sharedData") as? [[String: Any]] else { return }


        for dataDictionary in sharedDataArray {
            guard let pageTitle = dataDictionary["title"] as? String,
                  let yield = dataDictionary["yield"] as? String,
                  let ingredients = dataDictionary["ingredients"] as? [String],
                  let units = dataDictionary["units"] as? [String],
                  let pageURL = dataDictionary["url"] as? String,
                  let instructions = dataDictionary["instructions"] as? [String],  // Add instructions here
                  let cookTime = dataDictionary["cookTime"] as? String  // Add cookTime here
            else {
                continue
            }
                    
            let viewContext = self.container.viewContext
            let newMenu = MyMenu(context: viewContext)
            newMenu.name = pageTitle
            newMenu.referenceURL = URL(string: pageURL ?? "")
            for (index, ingredientName) in ingredients.enumerated() {
                if !ingredientName.isEmpty {
                    let newIngredient = Ingredient(context: viewContext)
                    newIngredient.name = ingredientName
                    newIngredient.unit = units[index]
                    newIngredient.order = Int16(index)
                    newIngredient.servings = yield
                    newMenu.addToIngredients(newIngredient)
                    newMenu.instruction = instructions.joined(separator: "\n")  // Join array of strings into a single string with line breaks
                    newMenu.cookTime = cookTime
                }
            }
            if let imagesURLs = dataDictionary["images"] as? [String], let imageURL = imagesURLs.first, let url = URL(string: imageURL), let imageData = try? Data(contentsOf: url) {
                newMenu.image = imageData
            }
                    
            do {
                try viewContext.save()
                // Save成功後にUserDefaultsからデータを削除

            } catch {
                // エラーハンドリングはここに書く
                print("Failed to save MyMenu: \(error)")
            }
        }
        defaults?.removeObject(forKey: "sharedData")
        defaults?.synchronize()
    }
    
    func initializeSampleDataIfNeeded() {
            let defaults = UserDefaults.standard
            if !defaults.bool(forKey: "hasLaunchedBefore") {
                // ここで初回起動時の処理（サンプルデータの作成など）を行う
                createSampleMenus()
                defaults.set(true, forKey: "hasLaunchedBefore")
                defaults.synchronize()
            }
        }
        
    func createSampleMenus() {
        let viewContext = self.container.viewContext
        
        // Sample1
        let menu1 = MyMenu(context: viewContext)
        menu1.name = "ごろごろ野菜のカレー"
        menu1.mealTag = "主菜"
        menu1.image = UIImage(named: "curry.jpg")?.pngData()
        menu1.rating = 5

        let ingredient1_1 = Ingredient(context: viewContext)
        ingredient1_1.name = "じゃがいも"
        ingredient1_1.unit = "3個"
        ingredient1_1.servings = "2人前"
        menu1.addToIngredients(ingredient1_1)

        let ingredient1_2 = Ingredient(context: viewContext)
        ingredient1_2.name = "にんじん"
        ingredient1_2.unit = "2本"
        ingredient1_2.servings = "2人前"
        menu1.addToIngredients(ingredient1_2)

        // Sample2
        let menu2 = MyMenu(context: viewContext)
        menu2.name = "昔懐かしオムライス"
        menu2.mealTag = "主菜"
        menu2.image = UIImage(named: "omurice.jpg")?.pngData()
        menu2.rating = 4


        let ingredient2_1 = Ingredient(context: viewContext)
        ingredient2_1.name = "たまご"
        ingredient2_1.unit = "4個"
        ingredient2_1.servings = "5人前"
        menu2.addToIngredients(ingredient2_1)
        
        let ingredient2_2 = Ingredient(context: viewContext)
        ingredient2_2.name = "鶏胸肉"
        ingredient2_2.unit = "100g"
        ingredient2_2.servings = "5人前"
        menu2.addToIngredients(ingredient2_2)
        
        // Sample3
        let menu3 = MyMenu(context: viewContext)
        menu3.name = "ボリューム満点ハンバーグ"
        menu3.mealTag = "主菜"
        menu3.image = UIImage(named: "humberg.jpg")?.pngData()
        menu3.rating = 3


        let ingredient3_1 = Ingredient(context: viewContext)
        ingredient3_1.name = "ひき肉"
        ingredient3_1.unit = "400g"
        ingredient3_1.servings = "小さめ10個"
        menu3.addToIngredients(ingredient3_1)
        
        // Add ingredient2_1 to ShoppingList
        let newShoppingItem2_1 = Shopping(context: viewContext)
        newShoppingItem2_1.name = ingredient2_1.name
        newShoppingItem2_1.unit = ingredient2_1.unit
        newShoppingItem2_1.ingredient = ingredient2_1
        ingredient2_1.addToShopping(newShoppingItem2_1)
        
        let newShoppingItem1_1 = Shopping(context: viewContext)
        newShoppingItem1_1.name = ingredient1_1.name
        newShoppingItem1_1.unit = ingredient1_1.unit
        newShoppingItem1_1.ingredient = ingredient1_1
        ingredient1_1.addToShopping(newShoppingItem1_1)
        
        let newShoppingItem3_1 = Shopping(context: viewContext)
        newShoppingItem3_1.name = ingredient3_1.name
        newShoppingItem3_1.unit = ingredient3_1.unit
        newShoppingItem3_1.ingredient = ingredient3_1
        ingredient3_1.addToShopping(newShoppingItem3_1)
        
        // 献立に追加
        let newMeal1 = Meal(context: viewContext)
        newMeal1.date = Date()
        newMeal1.mealTime = "夕食"
        newMeal1.image = menu3.image
        newMeal1.menuName = menu3.name
        newMeal1.mealTag = menu3.mealTag
        
        let newMeal2 = Meal(context: viewContext)
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: Date())!
        newMeal2.date = tomorrow
        newMeal2.mealTime = "昼食"
        newMeal2.image = menu2.image
        newMeal2.menuName = menu2.name
        newMeal2.mealTag = menu2.mealTag
        
        let newMeal3 = Meal(context: viewContext)
        newMeal3.date = tomorrow
        newMeal3.mealTime = "夕食"
        newMeal3.image = menu1.image
        newMeal3.menuName = menu1.name
        newMeal3.mealTag = menu1.mealTag

        do {
            try viewContext.save()
        } catch {
            print("Failed to save MyMenu: \(error)")
        }
    }

}
