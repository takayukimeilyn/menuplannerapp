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
    @State private var ingredientAddedToList: [Bool]

    
    init(menu: MyMenu, rating: Int) {
        self.menu = menu
        self._rating = State(initialValue: rating)
        self._imageData = State(initialValue: menu.image)
        
        let initialIngredients = (menu.ingredients?.allObjects as? [Ingredient]) ?? []
        self._ingredients = State(initialValue: initialIngredients)
        
        self._ingredientAddedToList = State(initialValue: Array(repeating: false, count: initialIngredients.count))
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
            
            Section(header: Text("材料")) {
                ForEach(ingredients.indices, id: \.self) { index in
                    HStack {
                        Toggle("", isOn: $ingredientAddedToList[index])
                        TextField("材料名", text: Binding(
                            get: { ingredients[index].name ?? "" },
                            set: { ingredients[index].name = $0 }
                        ))
                        .frame(minWidth: 0, idealWidth: 100, maxWidth: .infinity) // Add this line
                        Spacer() // Push the rest of the content to the left
                        TextField("単位", text: Binding(
                            get: { self.ingredients[index].unit ?? "" },
                            set: { self.ingredients[index].unit = $0 }
                        ))
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
                    
                    for index in ingredients.indices where ingredientAddedToList[index] {
                        let newShopping = Shopping(context: viewContext)
                        newShopping.name = ingredients[index].name
                        newShopping.unit = ingredients[index].unit
                    }
                    
                    
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
