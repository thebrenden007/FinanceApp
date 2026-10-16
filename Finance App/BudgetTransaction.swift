//
//  BudgetTransaction.swift
//  FinanceApp
//
//  Created by Brenden Smit on 10/13/26.
//

import Foundation
import SwiftData

enum RecurrenceFrequency: String, Codable, CaseIterable {
    case none = "One-Time"
    case weekly = "Weekly"
    case biweekly = "Bi-Weekly"
    case monthly = "Monthly"
    case yearly = "Yearly"
}

@Model
final class BudgetTransaction {
    var amount: Decimal
    var date: Date
    var note: String
    var isExpense: Bool
    var category: Category?
    var isRecurring: Bool = false
    var recurrenceRaw: String = RecurrenceFrequency.none.rawValue

    var recurrence: RecurrenceFrequency {
        get { RecurrenceFrequency(rawValue: recurrenceRaw) ?? .none }
        set { recurrenceRaw = newValue.rawValue }
    }

    init(amount: Decimal, date: Date = .now, note: String = "",
         isExpense: Bool = true, category: Category? = nil,
         isRecurring: Bool = false, recurrence: RecurrenceFrequency = .none) {
        self.amount = amount
        self.date = date
        self.note = note
        self.isExpense = isExpense
        self.category = category
        self.isRecurring = isRecurring
        self.recurrenceRaw = recurrence.rawValue
    }
}
