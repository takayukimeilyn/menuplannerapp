import SwiftUI
import CoreData

struct MyMenuListView: View {
    @Environment(\.managedObjectContext) private var viewContext

    @State private var refreshTrigger = false

    @FetchRequest(
        entity: MyMenu.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \MyMenu.name, ascending: true)]
    ) private var myMenus: FetchedResults<MyMenu>

    @State private var searchText = ""

    var body: some View {
        NavigationView {
            VStack {
                TextField("検索...", text: $searchText)
                    .padding(7)
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                    .padding(.horizontal)

                List {
                    ForEach(myMenus.filter {
                        self.searchText.isEmpty ? true : $0.name!.contains(self.searchText)
                    }) { menu in
                        HStack {
                            NavigationLink(destination: MyMenuEditView(menu: menu, rating: Int(menu.rating))) {
                                HStack {
                                    Text(menu.name ?? "")
                                    Spacer()
                                    StarRatingView(rating: .constant(Int(menu.rating)))
                                }
                            }
                        }
                    }
                    .onDelete(perform: deleteMenu)
                }
                .navigationBarTitle("マイメニュー", displayMode: .inline)
                .navigationBarItems(trailing:
                    NavigationLink(destination: MyMenuInputView()) {
                        Image(systemName: "plus")
                    }
                )
            }
            .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
                self.refreshData()
            }
        }
    }

    private func refreshData() {
        self.refreshTrigger.toggle()
    }

    private func deleteMenu(at offsets: IndexSet) {
        for index in offsets {
            let menu = myMenus[index]
            viewContext.delete(menu)
        }
        
        do {
            try viewContext.save()
        } catch {
            print("Failed to delete MyMenu: \(error)")
        }
    }
}



struct StarRatingView: View {
    @Binding var rating: Int

    var body: some View {
        HStack(spacing: 0) {  // ここでスペーシングをゼロに設定します
            ForEach(1..<6) { i in
                Image(systemName: i <= rating ? "star.fill" : "star")
                    .foregroundColor(i <= rating ? .yellow : .gray) // ここで色を設定します
                    .onTapGesture {
                        rating = i
                    }
            }
        }
    }
}

//class FetchedResultsControllerDelegate: NSObject, NSFetchedResultsControllerDelegate {
//    let didChangeContent: () -> Void
//
//    init(didChangeContent: @escaping () -> Void) {
//        self.didChangeContent = didChangeContent
//    }
//
//    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
//        didChangeContent()
//    }
//}
