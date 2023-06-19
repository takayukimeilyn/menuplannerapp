import SwiftUI
import CoreData
import GoogleMobileAds


struct ShoppingListView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(
        entity: Shopping.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \Shopping.order, ascending: true)]
    ) private var shoppings: FetchedResults<Shopping>
    
    init() {
        // Start Google Mobile Ads
        GADMobileAds.sharedInstance().start(completionHandler: nil)
    }

    
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
                AdBannerView(adUnitID: "ca-app-pub-9878109464323588/1202416085") // Replace with your ad unit ID
                    .frame(height: 50)
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

// UIViewRepresentable wrapper for AdMob banner view
struct AdBannerView: UIViewRepresentable {
    let adUnitID: String

    func makeUIView(context: Context) -> GADBannerView {
        let bannerView = GADBannerView(adSize: GADAdSizeFromCGSize(CGSize(width: 320, height: 50))) // Set your desired banner ad size
        bannerView.adUnitID = adUnitID
        bannerView.rootViewController = UIApplication.shared.windows.first?.rootViewController
        bannerView.load(GADRequest())
        return bannerView
    }
    
    func updateUIView(_ uiView: GADBannerView, context: Context) {}
}

