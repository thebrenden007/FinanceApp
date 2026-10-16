//
//  Category.swift
//  FinanceApp
//
//  Created by Brenden Smit on 10/13/26.
//

import Foundation
import SwiftData

@Model
final class Category {
    var name: String
    var icon: String
    var monthlyLimit: Decimal
    var colorName: String = "blue"
    
    @Relationship(deleteRule: .nullify, inverse: \BudgetTransaction.category)
    var transactions: [BudgetTransaction] = []
    
    init(name: String, icon: String, monthlyLimit: Decimal, colorName: String = "blue") {
        self.name = name
        self.icon = icon
        self.monthlyLimit = monthlyLimit
        self.colorName = colorName
    }
}
