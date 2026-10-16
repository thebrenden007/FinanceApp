//
//  TransactionListView.swift
//  FinanceApp
//
//  Created by Brenden Smit on 10/13/26.
//

import SwiftUI
import SwiftData

struct TransactionListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \BudgetTransaction.date, order: .reverse) private var transactions: [BudgetTransaction]
    @State private var showingAdd = false
    @State private var transactionToEdit: BudgetTransaction?
    @AppStorage("currencyCode") private var currencyCode = "USD"
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(transactions) { transaction in
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
                            Text(transaction.note.isEmpty ? (transaction.category?.name ?? (transaction.isExpense ? "Expense" : "Income")) : transaction.note)
                                .font(.body)
                            HStack(spacing: 4) {
                                if let category = transaction.category {
                                    Text(category.name)
                                    Text("•")
                                }
                                Text(transaction.date, style: .date)
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
                if transactions.isEmpty {
                    ContentUnavailableView(
                        "No Transactions",
                        systemImage: "creditcard",
                        description: Text("Tap + to log your income and expenses.")
                    )
                }
            }
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
            modelContext.delete(transactions[index])
        }
    }
}

#Preview {
    TransactionListView()
        .modelContainer(for: [BudgetTransaction.self, Category.self], inMemory: true)
}
