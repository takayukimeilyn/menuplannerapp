import SwiftUI
import CoreData

struct MyMenuEditView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.presentationMode) var presentationMode

    @ObservedObject var menu: MyMenu

    @State private var menuName = ""
    @State private var ingredients: [Ingredient] = []
    @State private var referenceURL = ""
    @State private var memo = ""
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var rating: Int
    @State private var imageData: Data?
    
    init(menu: MyMenu, rating: Int) {
        self.menu = menu
        self._rating = State(initialValue: rating)
        self._imageData = State(initialValue: menu.image)
        self._ingredients = State(initialValue: (menu.ingredients?.allObjects as? [Ingredient]) ?? [])

    }

    var body: some View {
        Form {
            Section(header: Text("メニュー名")) {
                HStack {
                    if let imageData = imageData, let uiImage = UIImage(data: imageData) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 100, height: 100)
                    }
                    TextField("メニュー名", text: $menuName)
                }
            }
            
            Section(header: Text("評価")) {
                Picker("評価", selection: $rating) {
                    ForEach(0..<6) { i in
                        Text("\(i)").tag(i)
                    }
                }
                .pickerStyle(MenuPickerStyle())
            }
            
            Section(header: Text("参考レシピサイト")) {
                TextField("URL", text: $referenceURL)
            }
            if let url = menu.referenceURL {
                Link("レシピサイト", destination: url)
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
                        Spacer()
                        TextField("数量", text: Binding(
                            get: { String(ingredient.quantity) },
                            set: { newValue in
                                if let doubleValue = Double(newValue) {
                                    ingredient.quantity = doubleValue
                                }
                            }
                        ))
                        .keyboardType(.decimalPad)
                        .toolbar {
                            ToolbarItem(placement: .keyboard) {
                                Button("閉じる") {
                                    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                                }
                            }
                        }
                        TextField("単位", text: Binding(
                            get: { ingredient.unit ?? "" },
                            set: { ingredient.unit = $0 }
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
            Button(action: {
                menu.name = menuName
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
        )
        .onAppear {
            menuName = menu.name ?? ""
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
