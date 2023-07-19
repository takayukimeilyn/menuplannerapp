import SwiftUI
import GoogleMobileAds  // AdMob SDKをインポート

struct SettingsView: View {
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
    @Binding var showTutorial: Bool
    var seasonalFoodsProvider = SeasonalFoodsProvider()  // StateObjectを通常の変数に変更
    @ObservedObject var interstitial = Interstitial()
    @State private var showSeasonalFoods = false  // 追加

    var body: some View {
        NavigationView {
            List {
                Section(header: Text("チュートリアル")) {
                    Button(action: {
                        showTutorial = true
                    }) {
                        HStack {
                            Image(systemName: "info.circle")
                            Text("レシピサイトから情報を取得する方法")
                        }
                    }
                }
                
                Section(header: Text("お役立ち情報")) {
                    Button(action: {
                        interstitial.onAdDismissed = {  // 広告が閉じられたときにshowSeasonalFoodsをtrueにする
                            self.showSeasonalFoods = true
                            self.presentationMode.wrappedValue.dismiss()
                            self.presentSeasonalFoodListView()
                        }
                        interstitial.presentInterstitial()
                    }) {
                        HStack {
                            Image(systemName: "leaf.arrow.triangle.circlepath")
                            Text("旬の食材を確認する")
                        }
                    }
                    .onAppear() {
                        interstitial.loadInterstitial()
                    }
                    .disabled(!interstitial.interstitialAdLoaded)
                }


                // 他の設定項目
            }
            .navigationTitle("設定")
            .listStyle(GroupedListStyle())
        }
    }
    // SeasonalFoodListViewをモーダルとして表示するメソッド
    func presentSeasonalFoodListView() {
        let viewController = UIHostingController(rootView: SeasonalFoodListView(provider: seasonalFoodsProvider))
        UIApplication.shared.windows.first?.rootViewController?.present(viewController, animated: true, completion: nil)
    }
}
