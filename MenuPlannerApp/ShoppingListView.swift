import SwiftUI
import CoreData
import GoogleMobileAds


struct ShoppingListView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(
        entity: Shopping.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \Shopping.order, ascending: true)]
    ) private var shoppings: FetchedResults<Shopping>
     
    var body: some View {
        NavigationView {
            VStack{
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
                                Text(shopping.name ?? "")
                                    .strikethrough(shopping.isChecked, color: .gray)
                                    .foregroundColor(shopping.isChecked ? .gray : .primary)
                                Spacer()
                                Text("\(shopping.unit ?? "")  ")
                            }
                        }
                    }
                    .onDelete(perform: deleteShopping)
                    .onMove(perform: moveShopping)
                }
            }
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
    
    func getIngredient(name: String) -> Ingredient? {
        let fetchRequest: NSFetchRequest<Ingredient> = Ingredient.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "name == %@", name)
        
        do {
            let ingredients = try viewContext.fetch(fetchRequest)
            return ingredients.first
        } catch {
            print("Failed to fetch Ingredient: \(error)")
            return nil
        }
    }

    private func deleteShopping(at offsets: IndexSet) {
        for index in offsets {
            let shopping = shoppings[index]
            shopping.ingredient?.isInShoppingList = false
            shopping.ingredient?.shopping = nil  // <-- Clear the inverse relationship
            viewContext.delete(shopping)
        }

        do {
            try viewContext.save()
        } catch {
            print("Failed to delete Shopping Item: \(error)")
        }
    }

    private func deleteAllCompleted() {
        for shopping in shoppings where shopping.isChecked {
            shopping.ingredient?.isInShoppingList = false
            shopping.ingredient?.shopping = nil  // <-- Clear the inverse relationship
            viewContext.delete(shopping)
        }
        do {
            try viewContext.save()
        } catch {
            print("Failed to delete completed Shopping Items: \(error)")
        }
    }
    
    private func moveShopping(from source: IndexSet, to destination: Int) {
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
}



