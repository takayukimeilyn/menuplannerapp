import SwiftUI
import CoreData

struct ShoppingListView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(
        entity: Shopping.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \Shopping.order, ascending: true)]
    ) private var shoppings: FetchedResults<Shopping>
    
    var body: some View {
        NavigationView {
            List {
                ForEach(shoppings) { shopping in
                    NavigationLink(destination: ShoppingEditView(shopping: shopping)) {
                        HStack {
                            // Checkbox representation
                            Image(systemName: shopping.isChecked ? "checkmark.square" : "square")
                                .foregroundColor(.blue)
                                .onTapGesture {
                                    shopping.isChecked.toggle()
                                    do {
                                        try viewContext.save()
                                    } catch {
                                        print("Failed to update Shopping Item: \(error)")
                                    }
                                }
                            // Shopping name with strikethrough when checked
                            Text(shopping.name ?? "")
                                .strikethrough(shopping.isChecked, color: .gray)
                                .foregroundColor(shopping.isChecked ? .gray : .primary)
                            Spacer()
                            Text("\(shopping.quantity) \(shopping.unit ?? "")  ")
                        }
                    }
                }
                .onDelete(perform: deleteShopping)
                .onMove(perform: moveShopping) // Handles drag and drop feature
            }
//            .navigationBarTitle("Shopping List")
            .navigationBarItems(
                leading: Button(action: {
                            deleteAllCompleted()
                            }) {
                                HStack {
                                    Image(systemName: "trash")
                                    Text("チェック済削除")
                                }

                            },
                trailing:HStack{
                    NavigationLink(destination: ShoppingInputView()) {
                        Image(systemName: "plus")
                    }
                }
            )
        }
    }
    
    private func deleteShopping(at offsets: IndexSet) {
        for index in offsets {
            let shopping = shoppings[index]
            viewContext.delete(shopping)
        }

        do {
            try viewContext.save()
        } catch {
            print("Failed to delete Shopping Item: \(error)")
        }
    }
    
    private func moveShopping(from source: IndexSet, to destination: Int) {
        // Handles the logic for moving Shopping item.
        var revisedItems: [Shopping] = shoppings.map { $0 }

        revisedItems.move(fromOffsets: source, toOffset: destination)

        for reverseIndex in stride(from: revisedItems.count - 1, through: 0, by: -1) {
            revisedItems[reverseIndex].order = Int16(reverseIndex)
        }
        
        do {
            try viewContext.save()
        } catch {
            print("Failed to reorder Shopping Items: \(error)")
        }
    }
    
    private func deleteAllCompleted() {
        for shopping in shoppings where shopping.isChecked {
            viewContext.delete(shopping)
        }
        
        do {
            try viewContext.save()
        } catch {
            print("Failed to delete completed Shopping Items: \(error)")
        }
    }
}
