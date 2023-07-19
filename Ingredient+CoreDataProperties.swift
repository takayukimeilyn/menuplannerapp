//
//  Ingredient+CoreDataProperties.swift
//  
//
//  Created by 橋本隆之 on 2023/07/08.
//
//

import Foundation
import CoreData


extension Ingredient {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Ingredient> {
        return NSFetchRequest<Ingredient>(entityName: "Ingredient")
    }

    @NSManaged public var isInShoppingList: Bool
    @NSManaged public var name: String?
    @NSManaged public var quantity: Double
    @NSManaged public var servings: String?
    @NSManaged public var unit: String?
    @NSManaged public var myMenu: MyMenu?
    @NSManaged public var shopping: NSSet?

}

// MARK: Generated accessors for shopping
extension Ingredient {

    @objc(addShoppingObject:)
    @NSManaged public func addToShopping(_ value: Shopping)

    @objc(removeShoppingObject:)
    @NSManaged public func removeFromShopping(_ value: Shopping)

    @objc(addShopping:)
    @NSManaged public func addToShopping(_ values: NSSet)

    @objc(removeShopping:)
    @NSManaged public func removeFromShopping(_ values: NSSet)

}
