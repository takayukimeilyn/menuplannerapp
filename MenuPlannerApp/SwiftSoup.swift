import SwiftUI
import SwiftSoup

struct RecipeIngredient: Identifiable {
    let id = UUID()
    let name: String
    let quantity: String
}

struct SwiftSoupView: View {
    @State private var imageAltText: String = ""
    @State private var servings: String = ""
    @State private var recipeIngredients: [RecipeIngredient] = []

    var body: some View {
        VStack {
            Text(imageAltText)
            Text(servings)
            List(recipeIngredients) { ingredient in
                VStack(alignment: .leading) {
                    Text(ingredient.name)
                    Text(ingredient.quantity)
                }
            }
        }
        .onAppear {
            fetchWebsiteData()
        }
    }

    func fetchWebsiteData() {
        let url = URL(string:"https://cookpad.com/recipe/1177944")!
        do {
            let data = try scrapeWebsiteData(url: url)
            self.imageAltText = data.imageAltText
            self.servings = data.servings
            self.recipeIngredients = data.recipeIngredients
        } catch {
            print("Failed to scrape website: \(error)")
        }
    }

    func scrapeWebsiteData(url: URL) throws -> (imageAltText: String, servings: String, recipeIngredients: [RecipeIngredient]) {
        let html = try String(contentsOf: url)
        let document = try SwiftSoup.parse(html)

        guard let imgElement = try document.select("img.photo.large_photo_clickable").first(),
              let servingsElement = try document.select("span.servings_for.yield").first() else {
            throw NSError(domain: "Required elements not found", code: 1, userInfo: nil)
        }

        let imageAltText = try imgElement.attr("alt")
        let servings = try servingsElement.text()
        
        let ingredientRows = try document.select("div#ingredients_list div.ingredient_row").array()
        var recipeIngredients: [RecipeIngredient] = []
        for ingredientRow in ingredientRows {
            guard let nameElement = try ingredientRow.select("div.ingredient_name span.name").first(),
                  let quantityElement = try ingredientRow.select("div.ingredient_quantity.amount").first() else {
                continue
            }
            let name = try nameElement.text()
            let quantity = try quantityElement.text()
            recipeIngredients.append(RecipeIngredient(name: name, quantity: quantity))
        }
        
        return (imageAltText, servings, recipeIngredients)
    }
}

// Add the following struct for preview
struct SwiftSoupView_Previews: PreviewProvider {
    static var previews: some View {
        SwiftSoupView()
    }
}
