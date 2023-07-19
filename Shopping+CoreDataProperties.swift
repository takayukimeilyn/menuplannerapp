//
//  Shopping+CoreDataProperties.swift
//  
//
//  Created by 橋本隆之 on 2023/07/08.
//
//

import Foundation
import CoreData


extension Shopping {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Shopping> {
        return NSFetchRequest<Shopping>(entityName: "Shopping")
    }

    @NSManaged public var isChecked: Bool
    @NSManaged public var name: String?
    @NSManaged public var order: Int16
    @NSManaged public var quantity: Int16
    @NSManaged public var unit: String?
    @NSManaged public var ingredient: Ingredient?

}
