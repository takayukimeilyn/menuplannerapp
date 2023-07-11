import SwiftUI
import Combine
import CoreData

struct InputView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @State private var date: Date
    @State private var mealTime = "朝食"
    @State private var mealTag: String = ""
    @State private var menuName: String = ""
    @State private var referenceURL: String = ""
    @State private var isCreatingNewMenu = false
    @State private var isInputtingMenu = false
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var mealsByDate: MealsByDate
    @State private var isShowingMyMenuList = false
//    @State private var mealTagIcon: String = "questionmark"
    @State private var selectedMyMenu: MyMenu? // New property

    var existingMenu: MyMenu? // <- Add this property
    
    init(date: Date? = nil, mealsByDate: MealsByDate, existingMenu: MyMenu? = nil) {
        self._date = State(initialValue: date ?? Date()) // オプショナル型のdateを使用
        self.mealsByDate = mealsByDate
        self.existingMenu = existingMenu // <- Set the existingMenu
        self._mealTag = State(initialValue: existingMenu?.mealTag ?? mealTag)
    }
    
    @FetchRequest(
        entity: MyMenu.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \MyMenu.name, ascending: true)]
    ) private var myMenus: FetchedResults<MyMenu>
    
    @FetchRequest(
        entity: Meal.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \Meal.date, ascending: true)]
    ) private var meals: FetchedResults<Meal> // New property
    
    var mealTimes = ["朝食", "昼食", "夕食", "その他"]
    var mealTags = ["主菜", "副菜", "主食", "汁物", "デザート", "その他"]
    
    let mealTagIcons = ["主菜": "steak", "副菜": "broccoli", "主食": "bread", "汁物": "soup", "デザート": "cupcake", "その他": "questionmark"]
    
    let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy/M/d"
        return formatter
    }()

    var body: some View {
        NavigationView {
            Form {
                Section {
                    DatePicker("日付", selection: $date, displayedComponents: .date)
                    Picker("朝食・昼食・夕食", selection: $mealTime) {
                        ForEach(mealTimes, id: \.self) {
                            Text($0)
                        }
                    }
                }
                
                Section(header: HStack {
                    Text("メニュー")
                    Spacer()
                    Button(action: {
                        self.isShowingMyMenuList.toggle()
                    }) {
                        HStack {
                            Image(systemName: "magnifyingglass")
                            Text("マイメニューから選択")
                        }
                    }
                    .sheet(isPresented: $isShowingMyMenuList) {
                        // モーダルで表示するビュー
                        ChoseMyMenuListView(isPresented: $isShowingMyMenuList, selectedMenu: $selectedMyMenu)
                    }
                }) {
                    if let selectedMenu = selectedMyMenu {
                        VStack {
                            Text(selectedMenu.name ?? "")
                        }
                        Text(selectedMenu.mealTag ?? "主菜")
                    } else {
                        HStack {
                            TextField("メニューを入力してください", text: $menuName)
                        }
                        Picker("種類", selection: $mealTag){
                            ForEach(mealTags, id: \.self) {
                                Text($0)
                            }
                        }
                    }
                }
                Section(header: Text("参考レシピサイト")) {
                    TextField("URL", text: $referenceURL)
                }
            }
            .navigationBarItems(trailing: Button(action: {
                saveMeal()
            }) {
                Text("保存")
            })
        }
        .onAppear {
            if let existingMenu = existingMenu {
                selectedMyMenu = existingMenu
                referenceURL = existingMenu.referenceURL?.absoluteString ?? "" // Set referenceURL if there is existingMenu
            }
        }
    }
    
    func saveMeal() {
        let newMeal = Meal(context: viewContext)
        newMeal.date = date
        newMeal.mealTime = mealTime
        newMeal.mealTag = mealTag

        if let selectedMenu = selectedMyMenu {
            newMeal.menuName = selectedMenu.name
            newMeal.mealTag = selectedMenu.mealTag
            newMeal.menu = selectedMenu
            newMeal.menu?.referenceURL = selectedMenu.referenceURL
        } else if !menuName.isEmpty {
            let existingMenu = myMenus.first(where: { $0.name == menuName })
            if let existingMenu = existingMenu {
                // Use the existing MyMenu
                newMeal.menuName = existingMenu.name
                newMeal.mealTag = existingMenu.mealTag
                newMeal.menu = existingMenu
            } else {
                // Create new MyMenu
                let newMyMenu = MyMenu(context: viewContext)
                newMyMenu.name = menuName
                newMyMenu.mealTag = mealTag
                newMeal.menu = newMyMenu
                newMeal.menuName = menuName
                
                // Convert the referenceURL string to a URL object and assign it
                if let url = URL(string: referenceURL) {
                    newMyMenu.referenceURL = url
                }
            }
        }

        do {
            try viewContext.save()
            let day = Calendar.current.startOfDay(for: date)
            if mealsByDate.data[day] != nil {
                mealsByDate.data[day]!.append(newMeal)
            } else {
                mealsByDate.data[day] = [newMeal]
            }
            presentationMode.wrappedValue.dismiss()
        } catch {
            print("Failed to save Meal: \(error)")
        }
    }
}

extension Binding {
   func onChange(_ handler: @escaping (Value) -> Void) -> Binding<Value> {
       Binding(
           get: { self.wrappedValue },
           set: { newValue in
               self.wrappedValue = newValue
               handler(newValue)
           }
       )
   }
}

struct ChoseMyMenuListView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(
        entity: MyMenu.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \MyMenu.name, ascending: true)]
    ) private var myMenus: FetchedResults<MyMenu>

    @Binding var isPresented: Bool
    @Binding var selectedMenu: MyMenu? // BindingをselectedMenuに変更

    @State private var searchText = ""

    var body: some View {
        VStack {
            HStack {
                Button(action: {
                    self.isPresented = false
                }) {
                    Text("戻る")
                }
                Spacer()
            }
            .padding()

            TextField("検索...", text: $searchText)
                .padding(7)
                .background(Color(.systemGray6))
                .cornerRadius(8)
                .padding(.horizontal)

            List {
                ForEach(myMenus.filter {
                    self.searchText.isEmpty ? true : $0.name!.contains(self.searchText)
                }) { menu in
                    Button(action: {
                        self.selectedMenu = menu // selectedMenuを更新
                        self.isPresented = false
                    }) {
                        Text(menu.name ?? "")
                    }
                }
            }
        }
    }
}
