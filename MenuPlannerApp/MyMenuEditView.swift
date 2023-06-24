import SwiftUI
import CoreData

struct MyMenuEditView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.presentationMode) var presentationMode

    @ObservedObject var menu: MyMenu

    @State private var menuName = ""
    @State private var mealTag = ""
    @State private var ingredients: [Ingredient] = []
    @State private var referenceURL = ""
    @State private var memo = ""
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var rating: Int
    @State private var imageData: Data?
    @State private var showingInputView = false // <- Add this state variable

    
    init(menu: MyMenu, rating: Int) {
        self.menu = menu
        self._rating = State(initialValue: rating)
        self._imageData = State(initialValue: menu.image)
        self._ingredients = State(initialValue: (menu.ingredients?.allObjects as? [Ingredient]) ?? [])

    }
    
    var mealTags = ["主菜", "副菜", "主食", "汁物", "デザート", "その他"]

    var body: some View {
        Form {
            Section(header: Text("メニュー")) {
                HStack {
                    if let imageData = imageData, let uiImage = UIImage(data: imageData) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 100, height: 100)
                    }
                    TextField("メニュー名", text: $menuName)
                }
                Picker("種類", selection: $mealTag){
                    ForEach(mealTags, id: \.self) {
                        Text($0)
                    }
                }
                Picker("評価", selection: $rating) {
                    ForEach(0..<6) { i in
                        Text("\(i)").tag(i)
                    }
                }
                .pickerStyle(MenuPickerStyle())

            }
            
            Section(header: Text("参考レシピサイト")) {
                HStack{
                    TextField("URL", text: $referenceURL)
                    if let url = menu.referenceURL {
                        Link(destination: url) {
                            Image(systemName: "paperplane")
                        }
                    }
                }
            }
                        
            Section(header: Text("メモ")) {
                TextField("メモ", text: $memo)
            }
            
            Section(header: Text("材料名")) {
                ForEach(ingredients, id: \.self) { ingredient in
                    HStack {
                        TextField("材料名", text: Binding(
                            get: { ingredient.name ?? "" },
                            set: { ingredient.name = $0 }
                        ))
                        .frame(minWidth: 0, idealWidth: 100, maxWidth: .infinity) // Give it a flexible width

                        Spacer().frame(width: 20) // Fixed spacing of 20
                        TextField("数量", text: Binding(
                            get: {
                                if floor(ingredient.quantity) == ingredient.quantity {
                                    return String(format: "%.0f", ingredient.quantity) // 整数の場合
                                } else {
                                    return String(ingredient.quantity) // 小数の場合
                                }
                            },
                            set: { newValue in
                                if newValue.isEmpty {
                                    ingredient.quantity = 0
                                } else if let doubleValue = Double(newValue) {
                                    ingredient.quantity = doubleValue
                                }
                            }
                        ))
                        .keyboardType(.decimalPad)
                        .frame(width: 50) // Fixed width of 50
                        .toolbar {
                            ToolbarItem(placement: .keyboard) {
                                HStack {
                                    Spacer()
                                    Button("閉じる") {
                                        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                                    }
                                }
                            }
                        }
                        Spacer().frame(width: 20) // Fixed spacing of 20

                        TextField("単位", text: Binding(
                            get: { ingredient.unit ?? "" },
                            set: { ingredient.unit = $0 }
                        ))
                        .frame(width: 50) // Fixed width of 50

                    }
                }
                .onDelete { indexSet in
                    ingredients.remove(atOffsets: indexSet)
                }
                
                Button("材料を追加") {
                    let newIngredient = Ingredient(context: viewContext)
                    newIngredient.name = ""
                    newIngredient.quantity = 0
                    newIngredient.unit = ""
                    ingredients.append(newIngredient)
                }
            }

        }
        .alert(isPresented: $showingAlert) {
            Alert(title: Text("Error"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
        }
        .navigationBarTitle(Text(menuName), displayMode: .inline)
        .navigationBarItems(trailing:
            HStack{
                Button(action: {
                    showingInputView = true // <- Open InputView as a sheet
                }) {
                    Text("予定追加")
                }
                .sheet(isPresented: $showingInputView) {
                    // Pass the menu object to InputView
                    InputView(date: Date(), mealsByDate: MealsByDate(), existingMenu: menu)
                        .environment(\.managedObjectContext, self.viewContext)
                }

                Button(action: {
                    menu.name = menuName
                    menu.mealTag = mealTag
                    menu.rating = Int16(rating)
                    if isValidURL(referenceURL) {
                        menu.referenceURL = URL(string: referenceURL)
                    } else {
                        alertMessage = "Invalid URL"
                        showingAlert = true
                        return
                    }
                    menu.memo = memo
                    let filteredIngredients = ingredients.filter { ingredient in
                        return !(ingredient.name ?? "").isEmpty
                    }
                    menu.ingredients = NSSet(array: filteredIngredients)
                    
                    
                    do {
                        try viewContext.save()
                        presentationMode.wrappedValue.dismiss()
                    } catch {
                        alertMessage = "Failed to save MyMenu: \(error)"
                        showingAlert = true
                    }
                }) {
                    Text("更新")
                }
            }
        )
        .onAppear {
            menuName = menu.name ?? ""
            mealTag = menu.mealTag ?? ""
            referenceURL = menu.referenceURL?.absoluteString ?? ""
            referenceURL = menu.referenceURL?.absoluteString ?? ""
            memo = menu.memo ?? ""
        }
    }

    func isValidURL(_ urlString: String) -> Bool {
        if urlString.isEmpty {
            return true
        }

        let urlRegEx = "(https?://(?:www\\.|(?!www))[a-zA-Z0-9][a-zA-Z0-9-]+[a-zA-Z0-9]\\.[^\\s]{2,}|www\\.[a-zA-Z0-9][a-zA-Z0-9-]+[a-zA-Z0-9]\\.[^\\s]{2,}|https?://(?:www\\.|(?!www))[a-zA-Z0-9]+\\.[^\\s]{2,}|www\\.[a-zA-Z0-9]+\\.[^\\s]{2,})"
        let urlTest = NSPredicate(format:"SELF MATCHES %@", urlRegEx)
        return urlTest.evaluate(with: urlString)
    }
}
