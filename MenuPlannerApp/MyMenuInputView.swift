import SwiftUI
import CoreData
import SwiftSoup

struct MyMenuInputView: View {
    @AppStorage("isFirstLaunch") var isFirstLaunch = true
    @State var showTutorial: Bool

    init() {
        let isFirstLaunch = UserDefaults.standard.object(forKey: "isFirstLaunch") as? Bool
        _showTutorial = State(initialValue: isFirstLaunch ?? true)
    }
    
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.presentationMode) var presentationMode

    @State private var menuName = ""
    @State private var referenceURL = ""
    @State private var mealTag = "主菜"
    @State private var memo = ""
    @State private var showingImagePicker = false
    @State private var image: UIImage?
    @State private var rating: Int = 0
    @State private var ingredients: [(name: String, quantity: Double?, unit: String)] = [(name: "", quantity: nil, unit: "")]

    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var servings = ""

    struct RecipeIngredient: Identifiable {
        let id = UUID()
        let name: String
        let unit: String
    }
    
    @State private var recipeIngredients: [RecipeIngredient] = []
    
    private func getSharedURL() -> String {
        let defaults = UserDefaults(suiteName: "group.takayuki.hashimoto.menuplannerapp.batch")
        defaults?.synchronize()
        return defaults?.string(forKey: "url") ?? ""
    }


    func scrapeWebsiteData() async {
        guard let url = URL(string: referenceURL), referenceURL.contains("cookpad.com") else {
            return
        }
        
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let html = String(decoding: data, as: UTF8.self)
            let document = try SwiftSoup.parse(html)

            guard let imgElement = try document.select("img.photo.large_photo_clickable").first(),
                  let servingsElement = try document.select("span.servings_for.yield").first() else {
                throw NSError(domain: "Required elements not found", code: 1, userInfo: nil)
            }

            let imageAltText = try imgElement.attr("alt")
            let servings = try servingsElement.text()
            
            let ingredientRows = try document.select("div#ingredients_list div.ingredient_row").array()
            var recipeIngredients: [RecipeIngredient] = []
            for ingredientRow in ingredientRows {
                guard let nameElement = try ingredientRow.select("div.ingredient_name span.name").first(),
                      let quantityElement = try ingredientRow.select("div.ingredient_quantity.amount").first() else {
                    continue
                }
                let name = try nameElement.text()
                let unit = try quantityElement.text()
                recipeIngredients.append(RecipeIngredient(name: name, unit: unit))
            }
            
            let ingredients = recipeIngredients.map { (name: $0.name, quantity: nil as Double?, unit: $0.unit) }
            DispatchQueue.main.async {
                self.menuName = imageAltText
                self.servings = servings
                self.ingredients = ingredients
            }

            
        } catch {
            print("Failed to scrape website: \(error)")
        }
    }
    
    var mealTags = ["主菜", "副菜", "主食", "汁物", "デザート", "その他"]
    
    var body: some View {
        if showTutorial {
            TutorialView(showTutorial: $showTutorial)
                .onDisappear {
                    isFirstLaunch = false
                }
        } else {
            Form {
                Section(header: Text("参考レシピサイト")) {
                    TextField("URL", text: $referenceURL)
                    Button(action: {
                        Task {
                            await scrapeWebsiteData()
                        }
                    }) {
                        Text("データ取得(cookpadのみ)")
                    }
                }
                
                Section(header: Text("メニュー名")) {
                    TextField("メニュー名", text: $menuName)
                }
                
                Section(header: Text("種類")){
                    Picker("種類", selection: $mealTag){
                        ForEach(mealTags, id: \.self) {
                            Text($0)
                        }
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
                
                Section(header: Text("メモ")) {
                    TextField("Memo", text: $memo)
                }
                
                Section(header: Text("何人分")) {
                    TextField("何人分", text: $servings)
                }
                
                Section(header: Text("材料")) {
                    ForEach(0..<ingredients.count, id: \.self) { index in
                        HStack {
                            TextField("材料名", text: $ingredients[index].name)
                            Spacer()
                            TextField("数量", text: $ingredients[index].unit)
                        }
                    }
                    .onDelete { indexSet in
                        ingredients.remove(atOffsets: indexSet)
                    }
                    Button("材料を追加") {
                        ingredients.append((name: "", quantity: nil, unit: ""))
                    }
                }
            }
            .onAppear {
                referenceURL = getSharedURL()
                Task {
                    await scrapeWebsiteData()
                }
            }
            .navigationBarTitle("新メニュー")
            .navigationBarItems(trailing: Button(action: {
                if isValidURL(referenceURL) {
                    let newMenu = MyMenu(context: viewContext)
                    newMenu.referenceURL = URL(string: referenceURL)
                    newMenu.name = menuName
                    newMenu.mealTag = mealTag
                    newMenu.rating = Int16(rating)
                    newMenu.memo = memo
                    if let inputImage = image {
                        newMenu.image = inputImage.pngData()
                    }
                    
                    for ingredient in ingredients {
                        if !ingredient.name.isEmpty {
                            let newIngredient = Ingredient(context: viewContext)
                            newIngredient.servings = self.servings
                            newIngredient.name = ingredient.name
                            newIngredient.quantity = ingredient.quantity ?? 0
                            newIngredient.unit = ingredient.unit
                            newMenu.addToIngredients(newIngredient)
                        }
                    }
                    
                    do {
                        try viewContext.save()
                        presentationMode.wrappedValue.dismiss()
                    } catch {
                        alertMessage = "Failed to save MyMenu: \(error)"
                        showingAlert = true
                    }
                    
                } else {
                    alertMessage = "Invalid URL"
                    showingAlert = true
                    return
                }
            }) {
                Text("保存")
            })
            .alert(isPresented: $showingAlert) {
                Alert(title: Text("Error"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
            }
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
