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
    @AppStorage("hasSeededIncomeCategories") private var hasSeededIncome = false
    @AppStorage("userName") private var userName = ""
    @AppStorage("appAppearance") private var appAppearance = AppAppearance.system.rawValue
    @AppStorage("beeThemeEnabled") private var beeThemeEnabled = true

    private var currentColorScheme: ColorScheme? {
        (AppAppearance(rawValue: appAppearance) ?? .system).colorScheme
    }
    
    var body: some View {
        Group {
            if userName.isEmpty {
                WelcomeView()
            } else {
                TabView {
                    DashboardView()
                        .tabItem {
                            Label("Dashboard", systemImage: "chart.pie.fill")
                        }
                    TransactionListView()
                        .tabItem {
                            Label("Transactions", systemImage: "list.bullet")
                        }
                    GoalsView()
                        .tabItem {
                            Label("Goals", systemImage: "target")
                        }
                    CategoryListView()
                        .tabItem {
                            Label("Categories", systemImage: "square.grid.2x2")
                        }
                }
                .onAppear(perform: seedCategoriesIfNeeded)
            }
        }
        .preferredColorScheme(currentColorScheme)
        .tint(beeThemeEnabled ? BeeTheme.amberGold : Color.accentColor)
    }

    private func seedCategoriesIfNeeded() {
        if !hasSeeded {
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
                    modelContext.insert(Category(name: item.name, icon: item.icon, monthlyLimit: item.limit, colorName: item.color, isIncome: false))
                }
            }
            hasSeeded = true
        }

        if !hasSeededIncome {
            let incomeDescriptor = FetchDescriptor<Category>(predicate: #Predicate { $0.isIncome })
            let existingIncome = (try? modelContext.fetchCount(incomeDescriptor)) ?? 0
            if existingIncome == 0 {
                let incomeDefaults: [(name: String, icon: String, limit: Decimal, color: String)] = [
                    ("Salary", "banknote.fill", 0, "green"),
                    ("Freelance", "laptopcomputer", 0, "blue"),
                    ("Investments", "chart.line.uptrend.xyaxis", 0, "indigo")
                ]
                for item in incomeDefaults {
                    modelContext.insert(Category(name: item.name, icon: item.icon, monthlyLimit: item.limit, colorName: item.color, isIncome: true))
                }
            }
            hasSeededIncome = true
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [BudgetTransaction.self, Category.self, Goal.self], inMemory: true)
}
