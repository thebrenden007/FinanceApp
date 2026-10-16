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
    var isIncome: Bool = false
    
    @Relationship(deleteRule: .nullify, inverse: \BudgetTransaction.category)
    var transactions: [BudgetTransaction] = []
    
    init(name: String, icon: String, monthlyLimit: Decimal, colorName: String = "blue", isIncome: Bool = false) {
        self.name = name
        self.icon = icon
        self.monthlyLimit = monthlyLimit
        self.colorName = colorName
        self.isIncome = isIncome
    }
}
