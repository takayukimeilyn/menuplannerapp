import SwiftUI
import Combine
import CoreData

class MenuPlanDate: ObservableObject {
    @Published var startOfWeek: Date
    @Published var endOfWeek: Date

    init() {
        var calendar = Calendar.current
        calendar.firstWeekday = 2 // 1 for Sunday, 2 for Monday, ..., 7 for Saturday
        let start = calendar.startOfDay(for: Date())
        self.startOfWeek = start
        self.endOfWeek = Calendar.current.date(byAdding: .day, value: 6, to: start)!
    }


    func nextWeek() {
        let nextWeekStart = Calendar.current.date(byAdding: .weekOfYear, value: 1, to: startOfWeek)!
        self.startOfWeek = nextWeekStart
        self.endOfWeek = Calendar.current.date(byAdding: .day, value: 6, to: nextWeekStart)!
    }

    func previousWeek() {
        let prevWeekStart = Calendar.current.date(byAdding: .weekOfYear, value: -1, to: startOfWeek)!
        self.startOfWeek = prevWeekStart
        self.endOfWeek = Calendar.current.date(byAdding: .day, value: 6, to: prevWeekStart)!
    }
    
    func thisWeek() {
        let thisWeekStart = Calendar.current.startOfDay(for: Date())
        self.startOfWeek = thisWeekStart
        self.endOfWeek = Calendar.current.date(byAdding: .day, value: 6, to: thisWeekStart)!
    }
}

class MealsByDate: ObservableObject {
    @Published var data: [Date: [Meal]] = [:]
    @Published var menuPlanDate: MenuPlanDate = MenuPlanDate()

    func computeMealsByDate(meals: FetchedResults<Meal>) {
        let mealsInWeek = meals.filter { meal in
            guard let date = meal.date else { return false }
            return date >= menuPlanDate.startOfWeek && date <= menuPlanDate.endOfWeek
        }
        
        self.data = Dictionary(grouping: mealsInWeek.sorted { meal1, meal2 in
            let order = ["朝食", "昼食", "夕食", "その他"]
            let index1 = order.firstIndex(of: meal1.mealTime ?? "") ?? Int.max
            let index2 = order.firstIndex(of: meal2.mealTime ?? "") ?? Int.max
            return index1 < index2
        }) { meal in
            guard let date = meal.date else { return Date() }
            return Calendar.current.startOfDay(for: date)
        }
    }
}

extension Date {
    func previous(_ weekday: Weekday, considerToday: Bool = false) -> Date {
        let calendar = Calendar(identifier: .gregorian)
        let components = DateComponents(weekday: weekday.rawValue)

        if considerToday && calendar.component(.weekday, from: self) == weekday.rawValue {
            return self
        }

        return calendar.nextDate(after: self, matching: components, matchingPolicy: .previousTimePreservingSmallerComponents)!
    }
}

enum Weekday: Int {
    case sunday = 1, monday, tuesday, wednesday, thursday, friday, saturday
}

struct MenuPlanList: View {
    @Environment(\.managedObjectContext) private var viewContext
    @StateObject private var mealsByDate = MealsByDate() // create an instance of MealsByDate
    @StateObject private var menuPlanDate = MenuPlanDate() // create an instance of MenuPlanDate

    @FetchRequest(
        entity: Meal.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \Meal.date, ascending: true)]
    ) private var meals: FetchedResults<Meal>

//    let dateFormatter: DateFormatter = {
//        let formatter = DateFormatter()
//        formatter.locale = Locale(identifier: "ja_JP") // set locale to Japanese
//        formatter.dateFormat = "yyyy/MM/dd (E)" // set format to include day of the week
//        return formatter
//    }()
    
    let dayOfWeekFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.dateFormat = "E"
        return formatter
    }()

    let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.dateFormat = "yyyy/MM/dd"
        return formatter
    }()
    
    func computeMealsByDate() -> [Date: [Meal]] {
        let mealsInWeek = meals.filter { meal in
            guard let date = meal.date else { return false }
            return date >= menuPlanDate.startOfWeek && date <= menuPlanDate.endOfWeek
        }
        
        return Dictionary(grouping: mealsInWeek.sorted { meal1, meal2 in
            let order = ["朝食", "昼食", "夕食", "その他"]
            let index1 = order.firstIndex(of: meal1.mealTime ?? "") ?? Int.max
            let index2 = order.firstIndex(of: meal2.mealTime ?? "") ?? Int.max
            return index1 < index2
        }) { meal in
            guard let date = meal.date else { return Date() }
            return Calendar.current.startOfDay(for: date)
        }
    }
    
    func nextWeek() {
        menuPlanDate.nextWeek()
    }
    
    func previousWeek() {
        menuPlanDate.previousWeek()
    }
    
    func thisWeek() {
        menuPlanDate.thisWeek()
            }

    var body: some View {
        NavigationView {
            ScrollView{
                VStack {
                    HStack {
                        Button(action: previousWeek) {
                            HStack{
                                Image(systemName: "chevron.left")
                                Text("前の週")
                            }
                        }
                        Spacer()
                        Button(action: thisWeek){
                            Text("今週")
                        }
                        Spacer()
                        Button(action: nextWeek) {
                            HStack{
                                Image(systemName: "chevron.right")
                                Text("次の週")
                            }
                        }
                    }
                    .padding()
                    Divider()
                    
                    MenuList(mealsByDate: mealsByDate, dayOfWeekFormatter: dayOfWeekFormatter, dateFormatter: dateFormatter, viewContext: viewContext)
                }
            }
            .navigationBarTitle("献立予定表", displayMode: .inline)
            .navigationBarItems(trailing:
                NavigationLink(destination: InputView(mealsByDate: mealsByDate)) {
                    HStack{
                        Image(systemName: "plus")
                        Text("新規追加")
                    }
                }
            )
        }
        .onAppear {
            mealsByDate.data = computeMealsByDate() // compute on appear
        }
        .onReceive(
            NotificationCenter.default.publisher(for: .NSManagedObjectContextDidSave, object: viewContext),
            perform: { _ in mealsByDate.data = computeMealsByDate() }
        )
        .onChange(of: menuPlanDate.startOfWeek) { _ in
            mealsByDate.data = computeMealsByDate()
        }
        .onChange(of: menuPlanDate.endOfWeek) { _ in
            mealsByDate.data = computeMealsByDate()
        }
    }
}

struct MenuList: View {
    @StateObject var mealsByDate: MealsByDate
    var dayOfWeekFormatter: DateFormatter
    var dateFormatter: DateFormatter
    var viewContext: NSManagedObjectContext

    var body: some View {
        if mealsByDate.data.isEmpty {
            Text("献立を追加してください")
                .font(.title)
                .padding(.top, 50)
                .foregroundColor(.gray)
        } else {
            ScrollView{
                ForEach(Array(mealsByDate.data.keys).sorted(), id: \.self) { date in
                    VStack(alignment: .leading, spacing: 20) {
                        HStack {
                            VStack(alignment: .leading) {
                                Text(dayOfWeekFormatter.string(from: date)+"曜日")
                                    .bold()
                                Text(dateFormatter.string(from: date))
                            }
                            .foregroundColor(Calendar.current.isDateInToday(date) ? .blue : .gray)
                            //                            .padding(.vertical)
                            Spacer()
                            NavigationLink(destination: InputView(date: date, mealsByDate: mealsByDate)) {
                                HStack {
                                    Image(systemName: "plus")
                                    //                                    Text("Add menu")
                                }
                            }
                        }
                        .padding(.horizontal)  // Sectionの横方向の余白に相当
                        
                        let sortedMeals = (mealsByDate.data[date]?.sorted(by: { (meal1, meal2) -> Bool in
                            let order = ["朝食", "昼食", "夕食", "その他"]
                            let index1 = order.firstIndex(of: meal1.mealTime ?? "") ?? Int.max
                            let index2 = order.firstIndex(of: meal2.mealTime ?? "") ?? Int.max
                            return index1 < index2
                        })) ?? []
                        let groupedMeals = Dictionary(grouping: sortedMeals, by: { $0.mealTime ?? "" })
                        
                        ForEach(["朝食", "昼食", "夕食", "その他"], id: \.self) { mealTime in
                            if let meals = groupedMeals[mealTime] {
                                MealTimeView(mealTime: mealTime, meals: meals, viewContext: viewContext, mealsByDate: mealsByDate)
                            }
                        }
                        .padding(.horizontal)
                        Divider()
                    }
                    //                }
                }
            }
        }
    }
}

struct MealTimeView: View {
    var mealTime: String
    var meals: [Meal]
    var viewContext: NSManagedObjectContext
    @StateObject var mealsByDate: MealsByDate

    private func mealTimeColor(_ mealTime: String) -> Color {
        switch mealTime {
        case "朝食":
            return Color.red.opacity(0.2)
        case "昼食":
            return Color.green.opacity(0.2)
        case "夕食":
            return Color.blue.opacity(0.2)
        case "その他":
            return Color.yellow.opacity(0.2)
        default:
            return Color.black
        }
    }

    func emojiForMealTag(_ mealTag: String) -> String {
        switch mealTag {
        case "主菜":
            return "🍴" // Fork and Knife Emoji
        case "副菜":
            return "🥗" // Green Salad Emoji
        case "主食":
            return "🍞" // Bread Emoji
        case "汁物":
            return "🍲" // Pot of Food Emoji
        case "デザート":
            return "🍦" // Soft Ice Cream Emoji
        default:
            return "❓" // Question Mark Emoji
        }
    }

    private func deleteMeal(at offsets: IndexSet) {
        for index in offsets {
            let meal = meals[index]
            viewContext.delete(meal)
        }
        do {
            try viewContext.save()
        } catch {
            let nsError = error as NSError
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }
    }

    var body: some View {
        Section(header:
                    HStack {
            Text(mealTime).font(.body)
            Spacer()
        }
            .padding(.horizontal)
            .background(mealTimeColor(mealTime))
            .cornerRadius(5)
        ) {
//            List{
                ForEach(meals, id: \.self) { meal in
                    NavigationLink(destination: EditView(meal: meal, mealsByDate: mealsByDate)) {
                        HStack {
                            Text(emojiForMealTag(meal.mealTag ?? ""))
                            Text(meal.menuName ?? "No menu")
                        }
                    }
                }
                .onDelete(perform: deleteMeal)
//            }
//            .onAppear {
//                for meal in meals {
//                    print("Menu Name: \(meal.menuName ?? "No menu name")")
//                }
//            }
        }
    }
}

