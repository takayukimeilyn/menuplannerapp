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
    // ... repeat for all categories and months

    let februaryFish: [String] = []
    let februaryVegetables: [String] = []
    
    let marchFish: [String] = []
    let marchVegetables: [String] = []
    
    let aprilFish: [String] = []
    let aprilVegetables: [String] = []
    
    let mayFish: [String] = []
    let mayVegetables: [String] = []

    let juneFish: [String] = ["あじ","あゆ","いさき","かじき","カツオ","かます","かれい","カワハギ","キス","キビナゴ","スズキ","タチウオ","タコ","ワカメ"]
    let juneVegetables: [String] = ["オクラ","かぼちゃ","きゅうり","空芯菜","アスパラガス","グリーンピース","さやいんげん","しそ","そら豆","玉ねぎ","冬瓜","とうもろこし","トマト","ニラ","パプリカ","ピーマン","モロヘイヤ"]

    // ... continue for all months

    var foods: [SeasonalFood] {
        let fishByMonth: [[String]] = [januaryFish, februaryFish,marchFish,aprilFish,mayFish,juneFish] // ... continue for all months
        let vegetablesByMonth: [[String]] = [januaryVegetables, februaryVegetables,marchVegetables,aprilVegetables,mayVegetables,juneVegetables] // ... continue for all months

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

    init(provider: SeasonalFoodsProvider) {
        self.foods = provider.foods
    }


    var body: some View {
        List {
            ForEach(1...12, id: \.self) { month in
                let foodsForMonth = foods.filter { $0.month == month }
                if !foodsForMonth.isEmpty {
                    Section(header: Text("\(month)月の旬の食材")) {
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
        }
        .listStyle(InsetGroupedListStyle())
        .navigationTitle("旬の食材一覧")
    }
}
