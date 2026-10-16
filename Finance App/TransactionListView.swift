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
                    HStack {
                        VStack(alignment: .leading) {
                            Text(transaction.category?.name ?? "Uncategorized")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text(transaction.note.isEmpty ? "No note" : transaction.note)
                            Text(transaction.date, style: .date)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .contentShape(Rectangle())
                        .onTapGesture { transactionToEdit = transaction }
                        Spacer()
                        Text(transaction.amount, format: .currency(code: currencyCode))
                            .foregroundStyle(transaction.isExpense ? .red : .green)
                    }
                }
                .onDelete(perform: delete)
            }
            .navigationTitle("Transactions")
            .profileButton()
            .toolbar {
                Button {
                    showingAdd = true
                } label: {
                    Image(systemName: "plus")
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
