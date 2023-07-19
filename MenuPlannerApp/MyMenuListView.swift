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
                            NavigationLink(destination: MyMenuEditView(menu: menu, rating: Int(menu.rating))) {
                                HStack {
                                    if let imageData = menu.image, let originalImage = UIImage(data: imageData) {
                                        if let resizedImage = resizeImage(image: originalImage, targetSize: CGSize(width: 360, height: 360)) {
                                            Image(uiImage: resizedImage)
                                                .resizable()
                                                .scaledToFit()
                                                .frame(height: 50) // ここで幅は指定せず、高さのみを指定します
                                                .clipped()
                                                .cornerRadius(5)
                                        }
                                    }
                                    VStack{
                                        HStack{
                                            Text(menu.name ?? "")
                                            Spacer()
                                        }
                                        HStack{
                                            StarRatingView(rating: .constant(Int(menu.rating)))
                                                .font(.footnote)
                                            Spacer()
                                        }
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
