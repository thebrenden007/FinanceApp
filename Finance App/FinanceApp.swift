//
//  FinanceApp.swift
//  FinanceApp
//
//  Created by Brenden Smit on 10/13/26.
//

import SwiftUI
import SwiftData

@main
struct FinanceApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .modelContainer(for: [BudgetTransaction.self, Category.self, Goal.self])
        }
    }
}
