import SwiftUI
import CoreData
import Combine

struct MyMenuEditView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.presentationMode) var presentationMode

    @ObservedObject var menu: MyMenu
    @State private var menuName = ""
    @State private var mealTag: String
    @State private var ingredients: [Ingredient]
    @State private var referenceURL = ""
    @State private var memo = ""
    @State private var cookTime = ""
    @State private var instruction = ""
    @State private var servings = ""
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var rating: Int
    @State private var imageData: Data?
    @State private var showingInputView = false // <- Add this state variable
    @State private var ingredientAddedToList: [Bool]
    @State private var resizedImage: UIImage?  // resizedImageをViewのプロパティにする

    @FetchRequest(
        entity: Shopping.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \Shopping.name, ascending: true)]
    ) private var shoppingItems: FetchedResults<Shopping>
    
    init(menu: MyMenu) {
        self.menu = menu
        self._rating = State(initialValue: Int(menu.rating))
        self._imageData = State(initialValue: menu.image)
        self._mealTag = State(initialValue: menu.mealTag ?? "主菜")
        
        // ingredientsをorder属性でソート
        let initialIngredients = (menu.ingredients?.allObjects as? [Ingredient])?.sorted(by: { $0.order < $1.order }) ?? []
        
        self._ingredients = State(initialValue: initialIngredients)
        self._ingredientAddedToList = State(initialValue: Array(repeating: false, count: initialIngredients.count))
        if let imageData = menu.image, let originalImage = UIImage(data: imageData) {
            _resizedImage = State(initialValue: resizeImage(image: originalImage, targetSize: CGSize(width: 360, height: 360)))
        }
    }

    
    var mealTags = ["主菜", "副菜", "主食", "汁物", "デザート", "その他"]

    var body: some View {
        Form {
            Section(header: Text("メニュー")) {
                HStack {
                    if let imageData = menu.image, let originalImage = UIImage(data: imageData) {
                        if let resizedImage = resizeImage(image: originalImage, targetSize: CGSize(width: 360, height: 360)) {
                            Image(uiImage: resizedImage)
                                .resizable()
                                .scaledToFit()
                                .frame(height: 60) // ここで幅は指定せず、高さのみを指定します
                                .clipped()
                                .cornerRadius(5)
                        }
                    }
                    VStack{  // VStackにspacingパラメータを設定
                        HStack{
                            Text(menuName)
                            Spacer()
                        }
                        if let url = menu.referenceURL, let host = url.host {
                            HStack{
                                Text("From")
                                Link(destination: url) {
                                    Text(host)
                                }
                                Link(destination: url) {
                                    Image(systemName: "arrow.right.circle") // 囲った矢印アイコン
                                }
                                Spacer()
                            }
                            .font(.footnote) // アイコンのサイズを小さくします
                        }
                    }

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
            
            Section(header: Text("調理時間")) {
                if !cookTime.isEmpty {
                    TextField("調理時間", text: $cookTime)
                        .onAppear {
                            cookTime = cookTime.replacingOccurrences(of: "PT", with: "")
                            cookTime = cookTime.replacingOccurrences(of: "M", with: "分")
                        }
                } else {
                    TextField("何分？", text: $cookTime)
                }
            }

            
            Section(header: Text("何人分")) {
                if !ingredients.isEmpty {
                    TextField("何人分", text: Binding(
                        get: { self.ingredients[0].servings ?? "" },
                        set: { self.ingredients[0].servings = $0 }
                    ))
                } else {
                    TextField("何人分？", text: $servings)
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
                    ingredientAddedToList.remove(atOffsets: indexSet)  // <- Add this line
                    ingredients = ingredients.map { $0 }
                }
                
                Button("材料を追加") {
                    let newIngredient = Ingredient(context: viewContext)
                    newIngredient.name = ""
                    newIngredient.quantity = 0
                    newIngredient.unit = ""
                    ingredients.append(newIngredient)
                    ingredientAddedToList.append(false)  // <- Add this line
                }
            }
            
            Section(header: Text("調理手順")) {
                TextEditor(text: $instruction)
                    .frame(height: 200) // ここで好みの高さを指定します
            }

            Section(header: Text("メモ")) {
                TextField("メモ", text: $memo)
            }
        }
        .alert(isPresented: $showingAlert) {
            Alert(title: Text("Error"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
        }
        .navigationBarTitle(Text(menuName), displayMode: .inline)
        .navigationBarItems(trailing:
            HStack{
                Button(action: {
                    menu.image = resizedImage?.jpegData(compressionQuality: 1.0)
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
                    menu.cookTime = cookTime
                    menu.instruction = instruction
                    menu.memo = memo
                    let filteredIngredients = ingredients.filter { ingredient in
                        return !(ingredient.name ?? "").isEmpty
                    }
                    menu.ingredients = NSSet(array: filteredIngredients)
                    if let ingredientSet = menu.ingredients as? Set<Ingredient> {
                        for ingredient in ingredientSet {
                            ingredient.servings = servings
                        }
                    }

                    for index in ingredients.indices where ingredientAddedToList[index] {
                        let newShopping = Shopping(context: viewContext)
                        newShopping.name = ingredients[index].name
                        newShopping.unit = ingredients[index].unit
                    }
                    
                    do {
                        try viewContext.save()
//                        presentationMode.wrappedValue.dismiss()
                    } catch {
                        alertMessage = "Failed to save MyMenu: \(error)"
                        showingAlert = true
                    }
                    showingInputView = true
                }) {
                    Text("献立追加")
                }
                .sheet(isPresented: $showingInputView) {
                    // Pass the menu object to InputView
                    InputView(date: Date(), mealsByDate: MealsByDate(), existingMenu: menu)
                        .environment(\.managedObjectContext, self.viewContext)
                }

                Button(action: {
                    menu.image = resizedImage?.jpegData(compressionQuality: 1.0)
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
                    menu.cookTime = cookTime
                    menu.instruction = instruction
                    menu.memo = memo
                    let filteredIngredients = ingredients.filter { ingredient in
                        return !(ingredient.name ?? "").isEmpty
                    }
                    menu.ingredients = NSSet(array: filteredIngredients)
                    if let ingredientSet = menu.ingredients as? Set<Ingredient> {
                        for ingredient in ingredientSet {
                            ingredient.servings = servings
                        }
                    }
                    
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
            referenceURL = menu.referenceURL?.absoluteString ?? ""
            memo = menu.memo ?? ""
            cookTime = menu.cookTime ?? ""
            instruction = menu.instruction ?? ""
        }

    }
    
    func resizeImage(image: UIImage, targetSize: CGSize) -> UIImage? {
        let imageView = UIImageView(frame: CGRect(origin: .zero, size: targetSize))
        imageView.contentMode = .scaleAspectFill
        imageView.image = image
        UIGraphicsBeginImageContextWithOptions(targetSize, false, 1.0)
        imageView.layer.render(in: UIGraphicsGetCurrentContext()!)
        let result = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return result
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

