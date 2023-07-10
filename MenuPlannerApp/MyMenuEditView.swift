import SwiftUI
import CoreData
import Combine

struct MyMenuEditView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.presentationMode) var presentationMode

    @ObservedObject var menu: MyMenu
    @State private var menuName = ""
    @State private var mealTag = "主菜"
    @State private var ingredients: [Ingredient]
    @State private var referenceURL = ""
    @State private var memo = ""
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var rating: Int
    @State private var imageData: Data?
    @State private var showingInputView = false // <- Add this state variable
    @State private var ingredientAddedToList: [Bool]
//    @State private var shoppingListChange: Bool = false

    
    @FetchRequest(
        entity: Shopping.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \Shopping.name, ascending: true)]
    ) private var shoppingItems: FetchedResults<Shopping>
    
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
                    if let imageData = menu.image, let uiImage = UIImage(data: imageData) {
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
            
            Section(header: Text("何人分")) {
                if !ingredients.isEmpty {
                    TextField("何人分", text: Binding(
                        get: { self.ingredients[0].servings ?? "" },
                        set: { self.ingredients[0].servings = $0 }
                    ))
                } else {
                    Text("材料がありません")
                }
            }
            
            Section(header: Text("材料")) {
                ForEach(ingredients.indices, id: \.self) { index in
                    HStack {
                        Button(action: {
                            ingredients[index].isInShoppingList.toggle()
                            if ingredients[index].isInShoppingList {
                                addToShoppingList(index: index)
                            } else {
                                removeFromShoppingList(name: ingredients[index].name)
                            }
                            self.ingredients = self.ingredients.map { $0 }

                        }) {
                            Image(systemName: "cart.fill")
                                .resizable()
                                .frame(width: 20, height: 20)
                                .foregroundColor(isIngredientInShoppingList(name: ingredients[index].name) ? .blue : .gray)
                        }

                        .padding(.trailing, 10)
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
                    for index in indexSet {
                        let ingredient = ingredients[index]
                        viewContext.delete(ingredient)
                    }
                    ingredients.remove(atOffsets: indexSet)
                    ingredients = ingredients.map { $0 }
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
                    showingInputView = true
                }) {
                    Text("献立追加")
                }
                .sheet(isPresented: $showingInputView) {
                    // Pass the menu object to InputView
                    InputView(date: Date(), mealsByDate: MealsByDate(), existingMenu: menu, mealTag: mealTag)
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
            memo = menu.memo ?? ""
        }
//        .onReceive(viewContext.didSavePublisher) { _ in
//            shoppingListChange.toggle()
//        }
    }
    
    func isIngredientInShoppingList(name: String?) -> Bool {
        guard let name = name else {
            return false
        }
        
        for shoppingItem in shoppingItems {
            if shoppingItem.name == name {
                return true
            }
        }
        return false
    }

    func addToShoppingList(index: Int) {
        let ingredient = ingredients[index]
        let newShopping = Shopping(context: viewContext)
        newShopping.name = ingredient.name
        newShopping.unit = ingredient.unit
        newShopping.ingredient = ingredient  // <-- Set the relationship
        ingredient.addToShopping(newShopping)  // <-- Set the inverse relationship
        do {
            try viewContext.save()
        } catch {
            alertMessage = "Failed to save to Shopping List: \(error)"
            showingAlert = true
        }
    }

    func removeFromShoppingList(name: String?) {
        guard let name = name else {
            return
        }

        let fetchRequest: NSFetchRequest<Shopping> = Shopping.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "name == %@", name)

        do {
            let fetchedShoppingItems = try viewContext.fetch(fetchRequest)
            if let shoppingItem = fetchedShoppingItems.first {
                shoppingItem.ingredient?.removeFromShopping(shoppingItem)  // <-- Clear the inverse relationship
                viewContext.delete(shoppingItem)
                try viewContext.save()

                self.ingredients = self.ingredients.map { $0 } // Add this line
            }
        } catch {
            alertMessage = "Failed to remove from Shopping List: \(error)"
            showingAlert = true
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

extension NSManagedObjectContext {
    var didSavePublisher: AnyPublisher<Notification, Never> {
        NotificationCenter.default
            .publisher(for: .NSManagedObjectContextDidSave, object: self)
            .eraseToAnyPublisher()
    }
}

