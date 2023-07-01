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

        return true
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        PersistenceController.shared.loadDataAndSave()  // updated line
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

        let pageTitle = defaults?.string(forKey: "title")
        let yield = defaults?.string(forKey: "yield")
        let ingredients = defaults?.stringArray(forKey: "ingredients")
        let units = defaults?.stringArray(forKey: "units")
        let pageURL = defaults?.string(forKey: "url")


        if let pageTitle = pageTitle, let ingredients = ingredients, let units = units {
            let viewContext = self.container.viewContext
            let newMenu = MyMenu(context: viewContext)
            newMenu.name = pageTitle
            newMenu.referenceURL = URL(string: pageURL ?? "")
            for (index, ingredientName) in ingredients.enumerated() {
                if !ingredientName.isEmpty {
                    let newIngredient = Ingredient(context: viewContext)
                    newIngredient.name = ingredientName
                    newIngredient.unit = units[index]
                    newMenu.addToIngredients(newIngredient)
                }
            }

            do {
                try viewContext.save()
                // Save成功後にUserDefaultsからデータを削除
                defaults?.removeObject(forKey: "title")
                defaults?.removeObject(forKey: "yield")
                defaults?.removeObject(forKey: "ingredients")
                defaults?.removeObject(forKey: "units")
                defaults?.synchronize()
            } catch {
                // エラーハンドリングはここに書く
                print("Failed to save MyMenu: \(error)")
            }
        }
    }
}
