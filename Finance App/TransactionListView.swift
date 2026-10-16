//
//  TransactionListView.swift
//  FinanceApp
//
//  Created by Brenden Smit on 10/13/26.
//

import SwiftUI
import SwiftData

enum TransactionFilter: String, CaseIterable {
    case all = "All"
    case expenses = "Expenses"
    case income = "Income"
    case recurring = "Recurring"
}

struct TransactionListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \BudgetTransaction.date, order: .reverse) private var transactions: [BudgetTransaction]
    @Query(sort: \Category.name) private var categories: [Category]

    @State private var showingAdd = false
    @State private var transactionToEdit: BudgetTransaction?
    @State private var searchText = ""
    @State private var selectedFilter: TransactionFilter = .all
    @State private var selectedCategory: Category? = nil

    @AppStorage("currencyCode") private var currencyCode = "USD"

    private var filteredTransactions: [BudgetTransaction] {
        transactions.filter { tx in
            // Search text filter (matches note or category name)
            if !searchText.isEmpty {
                let matchesNote = tx.note.localizedCaseInsensitiveContains(searchText)
                let matchesCategory = tx.category?.name.localizedCaseInsensitiveContains(searchText) ?? false
                guard matchesNote || matchesCategory else { return false }
            }

            // Type filter
            switch selectedFilter {
            case .all:
                break
            case .expenses:
                guard tx.isExpense else { return false }
            case .income:
                guard !tx.isExpense else { return false }
            case .recurring:
                guard tx.isRecurring else { return false }
            }

            // Category filter
            if let selectedCategory {
                guard tx.category?.persistentModelID == selectedCategory.persistentModelID else { return false }
            }

            return true
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Filter chips & Category selector
                VStack(spacing: 8) {
                    Picker("Filter", selection: $selectedFilter) {
                        ForEach(TransactionFilter.allCases, id: \.self) { filter in
                            Text(filter.rawValue).tag(filter)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)

                    // Category filter scroll
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            Button {
                                selectedCategory = nil
                            } label: {
                                Text("All Categories")
                                    .font(.caption2.bold())
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 5)
                                    .background(selectedCategory == nil ? Color.accentColor : Color(.secondarySystemFill))
                                    .foregroundStyle(selectedCategory == nil ? .white : .primary)
                                    .clipShape(Capsule())
                            }

                            ForEach(categories) { cat in
                                Button {
                                    selectedCategory = (selectedCategory?.persistentModelID == cat.persistentModelID) ? nil : cat
                                } label: {
                                    HStack(spacing: 4) {
                                        Image(systemName: cat.icon)
                                            .font(.caption2)
                                        Text(cat.name)
                                            .font(.caption2.bold())
                                    }
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 5)
                                    .background(selectedCategory?.persistentModelID == cat.persistentModelID ? CategoryColor.color(named: cat.colorName) : Color(.secondarySystemFill))
                                    .foregroundStyle(selectedCategory?.persistentModelID == cat.persistentModelID ? .white : .primary)
                                    .clipShape(Capsule())
                                }
                            }
                        }
                        .padding(.horizontal)
                        .padding(.vertical, 4)
                    }
                }
                .padding(.top, 4)

                List {
                    ForEach(filteredTransactions) { transaction in
                        HStack(spacing: 12) {
                            if let category = transaction.category {
                                ZStack {
                                    Circle()
                                        .fill(CategoryColor.color(named: category.colorName).opacity(0.18))
                                        .frame(width: 36, height: 36)
                                    Image(systemName: category.icon)
                                        .foregroundStyle(CategoryColor.color(named: category.colorName))
                                }
                            } else {
                                ZStack {
                                    Circle()
                                        .fill((transaction.isExpense ? Color.gray : Color.green).opacity(0.18))
                                        .frame(width: 36, height: 36)
                                    Image(systemName: transaction.isExpense ? "arrow.down" : "arrow.up")
                                        .foregroundStyle(transaction.isExpense ? Color.gray : Color.green)
                                }
                            }

                            VStack(alignment: .leading, spacing: 2) {
                                HStack(spacing: 6) {
                                    Text(transaction.note.isEmpty ? (transaction.category?.name ?? (transaction.isExpense ? "Expense" : "Income")) : transaction.note)
                                        .font(.body)
                                    if transaction.isRecurring {
                                        Image(systemName: "repeat")
                                            .font(.caption2)
                                            .foregroundStyle(.blue)
                                    }
                                }

                                HStack(spacing: 4) {
                                    if let category = transaction.category {
                                        Text(category.name)
                                        Text("•")
                                    }
                                    Text(transaction.date, style: .date)

                                    if transaction.isRecurring {
                                        Text("•")
                                        Text(transaction.recurrence.rawValue)
                                            .foregroundStyle(.blue)
                                    }
                                }
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            }
                            .contentShape(Rectangle())
                            .onTapGesture { transactionToEdit = transaction }

                            Spacer()

                            HStack(spacing: 2) {
                                Text(transaction.isExpense ? "-" : "+")
                                Text(transaction.amount, format: .currency(code: currencyCode))
                            }
                            .font(.subheadline.bold())
                            .foregroundStyle(transaction.isExpense ? Color.primary : Color.green)
                        }
                    }
                    .onDelete(perform: delete)
                }
                .overlay {
                    if filteredTransactions.isEmpty {
                        ContentUnavailableView(
                            searchText.isEmpty ? "No Transactions Found" : "No Results",
                            systemImage: searchText.isEmpty ? "creditcard" : "magnifyingglass",
                            description: Text(searchText.isEmpty ? "No transactions match the selected filter." : "No transactions match '\(searchText)'.")
                        )
                    }
                }
            }
            .searchable(text: $searchText, prompt: "Search notes or categories")
            .navigationTitle("Transactions")
            .profileButton()
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingAdd = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAdd) {
                AddTransactionView()
            }
            .sheet(item: $transactionToEdit) { transaction in
                AddTransactionView(transactionToEdit: transaction)
            }
        }
    }

    private func delete(at offsets: IndexSet) {
        for index in offsets {
            let txToDelete = filteredTransactions[index]
            modelContext.delete(txToDelete)
        }
    }
}

#Preview {
    TransactionListView()
        .modelContainer(for: [BudgetTransaction.self, Category.self], inMemory: true)
}
