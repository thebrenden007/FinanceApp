//
//  Transaction.swift
//  FinanceApp
//
//  Created by Brenden Smit on 10/13/26.
//
import Foundation
import SwiftData

@Model
final class BudgetTransaction {
    var amount: Decimal
    var date: Date
    var note: String
    var isExpense: Bool
    var category: Category?

    init(amount: Decimal, date: Date = .now, note: String = "",
         isExpense: Bool = true, category: Category? = nil) {
        self.amount = amount
        self.date = date
        self.note = note
        self.isExpense = isExpense
        self.category = category
    }
}
