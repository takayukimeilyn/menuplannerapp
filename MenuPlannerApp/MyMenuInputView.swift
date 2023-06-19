import SwiftUI
import CoreData

struct MyMenuInputView: View {
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
    
    var mealTags = ["主菜", "副菜", "主食", "汁物", "デザート", "その他"]
    
    var body: some View {
        Form {
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
            
            Section(header: Text("参考レシピサイト")) {
                TextField("URL", text: $referenceURL)
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
            
            Section(header: Text("材料")) {
                ForEach(0..<ingredients.count, id: \.self) { index in
                    HStack {
                        TextField("材料名", text: $ingredients[index].name)
                        Spacer()
                        TextField("数量", text: Binding(
                            get: { ingredients[index].quantity.map { String($0) } ?? "" },
                            set: { newValue in
                                if let doubleValue = Double(newValue) {
                                    ingredients[index].quantity = doubleValue
                                } else {
                                    ingredients[index].quantity = nil
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

                        TextField("単位", text: $ingredients[index].unit)
                    }
                }
                .onDelete { indexSet in
                    ingredients.remove(atOffsets: indexSet)
                }
                Button("材料を追加") {
                    ingredients.append((name: "", quantity: nil, unit: ""))
                }
            }
            
//            Section(header: Text("Image")) {
//                if let inputImage = image {
//                    Image(uiImage: inputImage)
//                        .resizable()
//                        .scaledToFit()
//                }
//                Button(action: {
//                    self.showingImagePicker = true
//                }) {
//                    Text("Select Image")
//                }
//            }
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
//        .sheet(isPresented: $showingImagePicker, onDismiss: loadImage) {
//            ImagePicker(image: $image)
//        }
    }
    
//    func loadImage() {
//        guard let inputImage = image else { return }
//        self.image = inputImage
//    }
    
    func isValidURL(_ urlString: String) -> Bool {
        if urlString.isEmpty {
            return true
        }

        let urlRegEx = "(https?://(?:www\\.|(?!www))[a-zA-Z0-9][a-zA-Z0-9-]+[a-zA-Z0-9]\\.[^\\s]{2,}|www\\.[a-zA-Z0-9][a-zA-Z0-9-]+[a-zA-Z0-9]\\.[^\\s]{2,}|https?://(?:www\\.|(?!www))[a-zA-Z0-9]+\\.[^\\s]{2,}|www\\.[a-zA-Z0-9]+\\.[^\\s]{2,})"
        let urlTest = NSPredicate(format:"SELF MATCHES %@", urlRegEx)
        return urlTest.evaluate(with: urlString)
    }
}

//struct ImagePicker: UIViewControllerRepresentable {
//    @Environment(\.presentationMode) var presentationMode
//    @Binding var image: UIImage?
//    
//    func makeUIViewController(context: UIViewControllerRepresentableContext<ImagePicker>) -> UIImagePickerController {
//        let picker = UIImagePickerController()
//        picker.delegate = context.coordinator
//        return picker
//    }
//    
//    func updateUIViewController(_ uiViewController: UIImagePickerController, context: UIViewControllerRepresentableContext<ImagePicker>) {
//    }
//    
//    func makeCoordinator() -> Coordinator {
//        Coordinator(self)
//    }
//    
//    class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
//        let parent: ImagePicker
//        
//        init(_ parent: ImagePicker) {
//            self.parent = parent
//        }
//        
//        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
//            if let uiImage = info[.originalImage] as? UIImage {
//                parent.image = uiImage
//            }
//            
//            parent.presentationMode.wrappedValue.dismiss()
//        }
//    }
//}
