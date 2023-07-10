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
                let pageURL = dataDictionary["url"] as? String else { continue }
            
                    
            let viewContext = self.container.viewContext
            let newMenu = MyMenu(context: viewContext)
            newMenu.name = pageTitle
            newMenu.referenceURL = URL(string: pageURL ?? "")
            for (index, ingredientName) in ingredients.enumerated() {
                if !ingredientName.isEmpty {
                    let newIngredient = Ingredient(context: viewContext)
                    newIngredient.name = ingredientName
                    newIngredient.unit = units[index]
                    newIngredient.servings = yield
                    newMenu.addToIngredients(newIngredient)
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
}
