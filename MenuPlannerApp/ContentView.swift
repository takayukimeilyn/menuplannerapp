import SwiftUI
import CoreData

struct ContentView: View {
//    @AppStorage("isFirstLaunch") var isFirstLaunch = true
    @State var showTutorial: Bool = false
//
//    init() {
//        let isFirstLaunch = UserDefaults.standard.object(forKey: "isFirstLaunch") as? Bool
//        _showTutorial = State(initialValue: isFirstLaunch ?? true)
//    }


    var body: some View {
        if showTutorial {
            TutorialView(showTutorial: $showTutorial)
//                .onDisappear {
//                    isFirstLaunch = false
//                }
        } else {
            VStack {
                TabView {
                    MyMenuListView()
                        .tabItem {
                            Image(systemName: "star.fill")
                            Text("マイメニュー")
                        }
                    
                    MenuPlanList()
                        .tabItem {
                            Image(systemName: "list.bullet")
                            Text("献立予定表")
                        }
                    
                    
                    ShoppingListView()
                        .tabItem {
                            Image(systemName: "cart.fill")
                            Text("買い物リスト")
                        }
                    
                    SettingsView(showTutorial: $showTutorial)
                        .tabItem {
                            Label("設定", systemImage: "gearshape.fill")
                        }
                }
            }
            
            // Replace with your ad unit ID
            AdBannerView(adUnitID: "ca-app-pub-9878109464323588/6532689844")
                .frame(height: 50)
        }
    }
}
