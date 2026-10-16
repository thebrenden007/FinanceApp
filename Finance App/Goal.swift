//
//  Goal.swift
//  FinanceApp
//
//  Created by Brenden Smit on 10/16/26.
//

import Foundation
import SwiftData

@Model
final class Goal{
    var name: String
    var icon: String
    var colorName: String
    var targetAmount: Decimal
    var targetDate: Date?
    var monthlyContribution: Decimal
    var savedAmount: Decimal
    var createdDate: Date
    
    init(name: String, icon: String, colorName: String = "blue", targetAmount: Decimal, targetDate: Date? = nil, monthlyContribution: Decimal, savedAmount: Decimal, createdDate: Date) {
        self.name = name
        self.icon = icon
        self.colorName = colorName
        self.targetAmount = targetAmount
        self.targetDate = targetDate
        self.monthlyContribution = monthlyContribution
        self.savedAmount = savedAmount
        self.createdDate = createdDate
    }
}
