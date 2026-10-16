//
//  ContentView.swift
//  FinanceApp
//
//  Created by Brenden Smit on 10/13/26.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @AppStorage("hasSeededCategories") private var hasSeeded = false
    @AppStorage("userName") private var userName = ""
    
    var body: some View {
        if userName.isEmpty{
            WelcomeView()
        } else{
            TabView {
                DashboardView()
                    .tabItem {
                        Label("Dashboard", systemImage: "chart.pie.fill")
                    }
                TransactionListView()
                    .tabItem {
                        Label("Transactions", systemImage: "list.bullet")
                    }
                
                CategoryListView()
                    .tabItem {
                        Label("Categories", systemImage: "square.grid.2x2")
                    }
            }
            .onAppear(perform: seedCategoriesIfNeeded)
        }
    }
    private func seedCategoriesIfNeeded() {
        guard !hasSeeded else { return }

        let existing = (try? modelContext.fetchCount(FetchDescriptor<Category>())) ?? 0
        if existing == 0 {
            let defaults: [(name: String, icon: String, limit: Decimal, color: String)] = [
                ("Groceries", "cart.fill", 0, "green"),
                ("Rent", "house.fill", 0, "indigo"),
                ("Transport", "car.fill", 0, "orange"),
                ("Dining", "fork.knife", 0, "red"),
                ("Utilities", "bolt.fill", 0, "yellow"),
                ("Health", "cross.case.fill", 0, "pink"),
                ("Entertainment", "tv.fill", 0, "purple"),
                ("Shopping", "tag.fill", 0, "teal")
            ]
            for item in defaults {
                modelContext.insert(Category(name: item.name, icon: item.icon, monthlyLimit: item.limit, colorName: item.color))
            }
        }
        hasSeeded = true
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [BudgetTransaction.self, Category.self], inMemory: true)
}
