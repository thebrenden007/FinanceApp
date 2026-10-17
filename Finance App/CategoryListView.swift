//
//  CategoryListView.swift
//  FinanceApp
//
//  Created by Brenden Smit on 10/13/26.
//

import SwiftUI
import SwiftData

struct CategoryListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Category.name) private var categories: [Category]
    @State private var showingForm = false
    @State private var categoryToEdit: Category?
    @State private var showingIncome = false
    @AppStorage("currencyCode") private var currencyCode = "USD"
    @AppStorage("blueFoxThemeEnabled") private var blueFoxThemeEnabled = true

    private var filteredCategories: [Category] {
        categories.filter { $0.isIncome == showingIncome }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Picker("Category Type", selection: $showingIncome) {
                    Text("Expenses").tag(false)
                    Text("Income").tag(true)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                .padding(.vertical, 8)

                List {
                    ForEach(filteredCategories) { category in
                        HStack(spacing: 12) {
                            ZStack {
                                Circle()
                                    .fill(CategoryColor.color(named: category.colorName).opacity(0.18))
                                    .frame(width: 36, height: 36)
                                Image(systemName: category.icon)
                                    .foregroundStyle(CategoryColor.color(named: category.colorName))
                            }

                            Text(category.name)
                                .font(.body)

                            Spacer()

                            VStack(alignment: .trailing, spacing: 2) {
                                Text(category.monthlyLimit, format: .currency(code: currencyCode))
                                    .bold()
                                Text(showingIncome ? "Target" : "Limit")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .contentShape(Rectangle())
                        .onTapGesture { categoryToEdit = category }
                        .blueFoxRowStyle()
                    }
                    .onDelete(perform: delete)
                }
                .scrollContentBackground(blueFoxThemeEnabled ? .hidden : .automatic)
                .overlay {
                    if filteredCategories.isEmpty {
                        ContentUnavailableView(
                            showingIncome ? "No Income Categories" : "No Expense Categories",
                            systemImage: showingIncome ? "banknote" : "tag",
                            description: Text(showingIncome ? "Add categories like Salary, Freelance, or Investments." : "Add categories to budget your expenses.")
                        )
                    }
                }
            }
            .blueFoxBackground()
            .navigationTitle("Categories")
            .profileButton()
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingForm = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingForm) {
                CategoryFormView(defaultIsIncome: showingIncome)
            }
            .sheet(item: $categoryToEdit) { category in
                CategoryFormView(categoryToEdit: category, defaultIsIncome: category.isIncome)
            }
        }
    }

    private func delete(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(filteredCategories[index])
        }
    }
}

#Preview {
    CategoryListView()
        .modelContainer(for: [BudgetTransaction.self, Category.self], inMemory: true)
}
