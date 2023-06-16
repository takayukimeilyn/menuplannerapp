import SwiftUI
import CoreData

struct ShoppingEditView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.presentationMode) var presentationMode

    @ObservedObject var shopping: Shopping

    @State private var name: String
    @State private var quantity: Int16
    @State private var unit: String



    init(shopping: Shopping) {
        self.shopping = shopping
        self._name = State(initialValue: shopping.name ?? "")
        self._quantity = State(initialValue: shopping.quantity )
        self._unit = State(initialValue: shopping.unit ?? "")

    }

    var body: some View {
        Form {
            Section(header: Text("アイテム")) {
                TextField("Shopping Item", text: $name)
            }
            
            Section(header: Text("個数")) {
                TextField("Shopping Item", value: $quantity, formatter: NumberFormatter())
            }
            
            Section(header: Text("単位")) {
                TextField("単位", text: $unit)
            }
            
            Button(action: {
                shopping.name = name
                shopping.quantity = quantity
                shopping.unit = unit

                
                do {
                    try viewContext.save()
                    presentationMode.wrappedValue.dismiss()
                } catch {
                    print("Failed to save MyMenu: \(error)")
                }
            }) {
                Text("Save")
            }
        }
    }
}
