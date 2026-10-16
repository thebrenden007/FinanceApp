//
//  Goal.swift
//  FinanceApp
//
//  Created by Brenden Smit on 10/16/26.
//

import Foundation
import SwiftData

@Model
final class Goal {
    var name: String
    var icon: String
    var colorName: String
    var targetAmount: Decimal
    var targetDate: Date?
    var monthlyContribution: Decimal
    var savedAmount: Decimal
    var createdDate: Date
    
    init(name: String, icon: String, colorName: String = "blue", targetAmount: Decimal, targetDate: Date? = nil, monthlyContribution: Decimal = 0, savedAmount: Decimal = 0, createdDate: Date = .now) {
        self.name = name
        self.icon = icon
        self.colorName = colorName
        self.targetAmount = targetAmount
        self.targetDate = targetDate
        self.monthlyContribution = monthlyContribution
        self.savedAmount = savedAmount
        self.createdDate = createdDate
    }

    /// Number of months remaining from current date until target date (minimum 1)
    var monthsRemaining: Int? {
        guard let targetDate else { return nil }
        let calendar = Calendar.current
        let components = calendar.dateComponents([.month, .day], from: .now, to: targetDate)
        let months = components.month ?? 0
        let days = components.day ?? 0
        let total = months + (days > 0 ? 1 : 0)
        return max(1, total)
    }

    /// Remaining amount needed to hit target
    var remainingAmount: Decimal {
        max(0, targetAmount - savedAmount)
    }

    /// Calculated monthly contribution needed to reach target by targetDate
    var requiredMonthlyContribution: Decimal? {
        guard let months = monthsRemaining, months > 0 else { return nil }
        return remainingAmount / Decimal(months)
    }

    /// Projected completion date if contributing the current monthlyContribution
    var projectedCompletionDate: Date? {
        guard monthlyContribution > 0, remainingAmount > 0 else { return nil }
        let monthsNeeded = Int(ceil(NSDecimalNumber(decimal: remainingAmount / monthlyContribution).doubleValue))
        guard monthsNeeded > 0 else { return .now }
        return Calendar.current.date(byAdding: .month, value: monthsNeeded, to: .now)
    }

    /// Progress percentage towards the goal (0.0 to 1.0)
    var progress: Double {
        guard targetAmount > 0 else { return 0 }
        return NSDecimalNumber(decimal: min(savedAmount / targetAmount, 1)).doubleValue
    }
}
