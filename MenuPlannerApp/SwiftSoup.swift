//import SwiftUI
//import SwiftSoup
//
//struct SwiftSoupView: View {
//    @State private var description: String = ""
//
//    var body: some View {
//        Text(description)
//            .onAppear {
//                fetchDescription()
//            }
//    }
//
//    func fetchDescription() {
//        let url = URL(string:"https://en.wikipedia.org/wiki/Aglaonema")!
//        do {
//            self.description = try scrapeHouseplantSpecies(url: url)
//        } catch {
//            print("Failed to scrape website: \(error)")
//        }
//    }
//
//    func scrapeHouseplantSpecies(url: URL) throws -> String {
//        let html = try String(contentsOf: url)
//        let document = try SwiftSoup.parse(html)
//
//        var element : Element?
//
//        let span = try document.select("#Description").first()
//            ?? document.select("#Description_and_biology").first()
//            ?? document.select("#Name_and_description").first()
//            ?? document.select("#Plant_care").first()
//
//        if span != nil {
//            let h2 = span!.parent()!
//            element = try h2.nextElementSibling()
//        } else {
//            // Start collecting text from the beginning of the web page.
//            let div = try document.select(".mw-parser-output")
//            element = div.first()?.children()[3]
//        }
//
//        var description = ""
//        while element != nil {
//            // Stop at the next "h" tag. (h2, h3, whatever.)
//            if element!.tagName().starts(with: "h") {
//                break
//            }
//            description += try element!.text()
//            element = try element!.nextElementSibling()
//        }
//        return description
//    }
//}
