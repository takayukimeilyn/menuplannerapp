import SwiftUI
import CoreData

struct ContentView: View {
    var body: some View {
        TabView {
            MenuPlanList()
                .tabItem {
                    Image(systemName: "list.bullet")
                    Text("献立予定表")
                }
            
            MyMenuListView()
                .tabItem {
                    Image(systemName: "star.fill")
                    Text("マイメニュー")
                }
            
            ShoppingListView()
                .tabItem {
                    Image(systemName: "cart.fill")
                    Text("買い物リスト")
                }
            
//            SeasonalFoodListView(provider: SeasonalFoodsProvider())
//                .tabItem {
//                    Image(systemName: "carrot.fill")
//                    Text("旬の食材")
//                }
        }
    }
}
