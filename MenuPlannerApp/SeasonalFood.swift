import SwiftUI

struct SeasonalFood: Identifiable {
    enum Category: String, CaseIterable {
        case fish = "魚"
        case vegetable = "野菜"
    }
    
    let id = UUID()
    let name: String
    let month: Int
    let category: Category
}

struct SeasonalFoodsProvider {
    let januaryFish: [String] = ["鯛", "カキ","サワラ","ブリ"]
    let januaryVegetables: [String] = ["大根","れんこん","里芋","牛蒡","長芋","さつまいも"]

    let februaryFish: [String] = ["しらうお", "金目鯛","鯛"]
    let februaryVegetables: [String] = ["カリフラワー","キャベツ","レンコン","みずな"]
    
    let marchFish: [String] = ["しらうお", "さより","シラス","鯛"]
    let marchVegetables: [String] = ["うど","かぶ","ニラ"]
    
    let aprilFish: [String] = ["しらうお", "さより","シラス","鯛","メバル"]
    let aprilVegetables: [String] = ["アスパラガス","グリーンピース","クレソン","さやえんどう"]
    
    let mayFish: [String] = ["かつお", "いさき","シラス","あじ","メバル"]
    let mayVegetables: [String] = ["アスパラガス","グリーンピース","クレソン","さやえんどう"]

    let juneFish: [String] = ["あじ","あゆ","いさき","かじき","カツオ","かます","かれい","カワハギ","キス","キビナゴ","スズキ","タチウオ","タコ","ワカメ"]
    let juneVegetables: [String] = ["オクラ","かぼちゃ","きゅうり","空芯菜","アスパラガス","グリーンピース","さやいんげん","しそ","そら豆","玉ねぎ","冬瓜","とうもろこし","トマト","ニラ","パプリカ","ピーマン","モロヘイヤ"]
    
    let julyFish: [String] = ["あじ","カンパチ","すずき"]
    let julyVegetables: [String] = ["青唐辛子","明日葉","いんげん"]
    
    let augustFish: [String] = ["あじ","カジキマグロ","すずき"]
    let augustVegetables: [String] = ["青唐辛子","明日葉","いんげん"]
    
    let septemberFish: [String] = ["シャケ","さんま"]
    let septemberVegetables: [String] = ["青唐辛子","明日葉","いんげん"]
    
    let octorberFish: [String] = ["シャケ","さんま"]
    let octorberVegetables: [String] = ["にんじん","松茸","みょうが"]
    
    let novemberFish: [String] = ["シャケ","さば"]
    let novemberVegetables: [String] = ["えのき","銀杏","くわい"]
    
    let decemberFish: [String] = ["アンコウ","ぶり","たら"]
    let decemberVegetables: [String] = ["みずな","小松菜"]


    var foods: [SeasonalFood] {
        let fishByMonth: [[String]] = [januaryFish, februaryFish,marchFish,aprilFish,mayFish,juneFish,julyFish,augustFish,septemberFish,octorberFish,novemberFish,decemberFish]
        let vegetablesByMonth: [[String]] = [januaryVegetables, februaryVegetables,marchVegetables,aprilVegetables,mayVegetables,juneVegetables,julyVegetables,augustVegetables,septemberVegetables,octorberVegetables,novemberVegetables,decemberVegetables]

        return fishByMonth.enumerated().flatMap { month, foods in
            foods.map { name in
                SeasonalFood(name: name, month: month + 1, category: .fish)
            }
        } + vegetablesByMonth.enumerated().flatMap { month, foods in
            foods.map { name in
                SeasonalFood(name: name, month: month + 1, category: .vegetable)
            }
        }
    }
}

struct SeasonalFoodListView: View {
    let foods: [SeasonalFood]
    @State private var selectedMonth: Int  // 選択されている月を管理するState

    init(provider: SeasonalFoodsProvider) {
        self.foods = provider.foods
        let currentMonth = Calendar.current.component(.month, from: Date())  // 現在の月を取得
        _selectedMonth = State(initialValue: currentMonth)  // Stateの初期値を現在の月に設定
    }

    var body: some View {
        VStack {
            Picker("月選択", selection: $selectedMonth) {
                ForEach(1...12, id: \.self) { month in
                    Text("\(month)月").tag(month)
                }
            }
//            .pickerStyle(SegmentedPickerStyle())
            .padding()

            List {
                let foodsForMonth = foods.filter { $0.month == selectedMonth }
                if !foodsForMonth.isEmpty {
                    Section(header: Text("\(selectedMonth)月の旬の食材")) {
                        ForEach(SeasonalFood.Category.allCases, id: \.self) { category in
                            let foodsForCategory = foodsForMonth.filter { $0.category == category }
                            if !foodsForCategory.isEmpty {
                                Section(header: Text(category.rawValue)
                                    .font(.headline)
                                    .bold()
                                    .foregroundColor(.green)) {
                                    ForEach(foodsForCategory) { food in
                                        Text(food.name)
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .listStyle(InsetGroupedListStyle())
        }
        .navigationTitle("旬の食材一覧")
    }
}

