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
    @AppStorage("currencyCode") private var currencyCode = "USD"
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(categories) { category in
                    HStack {
                        Image(systemName: category.icon)
                        Text(category.name)
                        Spacer()
                        Text(category.monthlyLimit, format: .currency(code: currencyCode))
                            .foregroundStyle(.secondary)
                    }
                    .contentShape(Rectangle())
                    .onTapGesture { categoryToEdit = category }
                }
                .onDelete(perform: delete)
            }
            .navigationTitle("Categories")
            .profileButton()
            .toolbar {
                Button {
                    showingForm = true
                } label: {
                    Image(systemName: "plus")
                }
            }
            .sheet(isPresented: $showingForm) {
                CategoryFormView()
            }
            .sheet(item: $categoryToEdit) { category in
                CategoryFormView(categoryToEdit: category)
            }
        }
    }

    private func delete(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(categories[index])
        }
    }
}

#Preview {
    CategoryListView()
        .modelContainer(for: [BudgetTransaction.self, Category.self], inMemory: true)
}
