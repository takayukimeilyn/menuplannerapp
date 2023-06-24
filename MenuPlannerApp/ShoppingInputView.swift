import SwiftUI
import CoreData

struct ShoppingInputView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.presentationMode) var presentationMode


    @State private var name = ""
    @State private var quantity = 1
    @State private var unit = "個"

    
    var body: some View {
        NavigationView{
            Form {
                
                Section(header: Text("アイテム")) {
                    TextField("アイテム", text: $name)
                }
                
                Section(header: Text("個数")) {
                    TextField("個数", value: $quantity, formatter: NumberFormatter())
                }
                
                Section(header: Text("単位")) {
                    TextField("単位", text: $unit)
                }
            }
        }
        .navigationBarItems(trailing: Button(action: {
            let shoppings = Shopping(context: viewContext)

            shoppings.name = name
            shoppings.quantity = Int16(quantity)
            shoppings.unit = unit
            
            do {
                try viewContext.save()
                presentationMode.wrappedValue.dismiss()

            } catch {
                print("Failed to save MyMenu: \(error)")
            }
        }) {
            Text("保存")
        })
    }
}
