import SwiftUI
import CoreData

struct EditView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var meal: Meal
    @ObservedObject var mealsByDate: MealsByDate
    @State private var selectedDate: Date
    @State private var menuName: String
    @State private var selectedMenuURL: URL?
    @State private var selectedMenu: MyMenu?
    @State private var isShowingMyMenuList = false
    @State private var showingModal = false

    
    init(meal: Meal, mealsByDate: MealsByDate) {
        self.meal = meal
        self.mealsByDate = mealsByDate
        _selectedDate = State(initialValue: meal.date ?? Date())
        // Check if the meal has associated menu and use its data
        if let menu = meal.menu {
            _menuName = State(initialValue: menu.name ?? "")
            if let referenceURI = menu.referenceURL {
                _selectedMenuURL = State(initialValue: referenceURI)
            } else {
                _selectedMenuURL = State(initialValue: nil)
            }
        } else {
            _menuName = State(initialValue: meal.menuName ?? "")
            _selectedMenuURL = State(initialValue: nil)
        }
    }
    
    func fetchMyMenu(withName name: String) -> MyMenu? {
        let fetchRequest: NSFetchRequest<MyMenu> = MyMenu.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "name == %@", name)
        
        do {
            let results = try viewContext.fetch(fetchRequest)
            return results.first
        } catch {
            print("Failed to fetch MyMenu with name \(name): \(error)")
            return nil
        }
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    DatePicker("日付", selection: $selectedDate, displayedComponents: .date)
                }

                Section {
                    Picker("Meal Time", selection: Binding<String>(
                        get: { self.meal.mealTime ?? "夕食" },
                        set: { self.meal.mealTime = $0 }
                    )) {
                        ForEach(["朝食", "昼食", "夕食", "その他"], id: \.self) {
                            Text($0)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }

                Section(header: HStack {
                    Text("メニュー名")
                    Spacer()
                    Button(action: {
                        self.isShowingMyMenuList.toggle()
                    }) {
                        HStack {
                            Image(systemName: "magnifyingglass")
                            Text("My Menuから選択")
                        }
                    }
                    .sheet(isPresented: $isShowingMyMenuList) {
                        ChoseMyMenuListView(isPresented: $isShowingMyMenuList, selectedMenu: $selectedMenu)
                    }

                }) {
                    if let selectedMenu = selectedMenu {
                        VStack {
                            // Use Button instead of NavigationLink
                            Button(action: {
                                // Set showingModal to true when button is pressed
                                showingModal = true
                            }) {
                                Text(selectedMenu.name ?? "")
                            }
                            // Show the modal when showingModal is true
                            .sheet(isPresented: $showingModal) {
                                // Pass the selectedMenu to MyMenuEditView
                                MyMenuEditView(menu: selectedMenu)
                            }
                        }
                    } else {
                        HStack {
                            TextField("メニューを入力してください", text: $menuName)
                        }
                    }
                }
            }
        }
        .navigationBarItems(trailing:
                                HStack(spacing: 20) {
            Button(action: {
                // 削除処理
                viewContext.delete(meal)
                do {
                    try viewContext.save()
                } catch {
                    print("Failed to delete Meal: \(error)")
                }
                presentationMode.wrappedValue.dismiss()
            }) {
                Text("削除")
                    .foregroundColor(.red)
            }
            
            Button(action: {
                do {
                    meal.date = selectedDate
                    
                    if let selectedMenu = selectedMenu {
                        // If a menu is selected from MyMenu, set the meal's menu to the selected MyMenu entry
                        meal.menu = selectedMenu
                        meal.menuName = selectedMenu.name
                        meal.mealTag = selectedMenu.mealTag
                        // If URL is associated with selectedMenu
                        meal.menu?.referenceURL = selectedMenu.referenceURL
                    } else {
                        // Only set the meal's menuName
                        meal.menuName = menuName
                    }
                    
                    try meal.managedObjectContext?.save()
                    presentationMode.wrappedValue.dismiss()
                } catch {
                    print("Failed to update Meal: \(error)")
                }
            }) {
                Text("保存")
            }
        })

        .onAppear {
            if let menuName = meal.menu?.name {
                self.selectedMenu = self.fetchMyMenu(withName: menuName)
            }
        }
    }
}
