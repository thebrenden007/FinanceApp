//
//  AddTransactionView.swift
//  FinanceApp
//
//  Created by Brenden Smit on 10/13/26.
//

import SwiftUI
import SwiftData

struct AddTransactionView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Category.name) private var categories: [Category]

    var transactionToEdit: BudgetTransaction?

    @State private var amountText: String
    @State private var date: Date
    @State private var note: String
    @State private var isExpense: Bool
    @State private var category: Category?

    private var amount: Decimal {
        Decimal(string: amountText) ?? 0
    }

    private var filteredCategories: [Category] {
        categories.filter { $0.isIncome == !isExpense }
    }

    init(transactionToEdit: BudgetTransaction? = nil) {
        self.transactionToEdit = transactionToEdit
        _amountText = State(initialValue: transactionToEdit.map { "\($0.amount)" } ?? "")
        _date = State(initialValue: transactionToEdit?.date ?? .now)
        _note = State(initialValue: transactionToEdit?.note ?? "")
        _isExpense = State(initialValue: transactionToEdit?.isExpense ?? true)
        _category = State(initialValue: transactionToEdit?.category)
    }

    var body: some View {
        NavigationStack {
            Form {
                Picker("Type", selection: $isExpense) {
                    Text("Expense").tag(true)
                    Text("Income").tag(false)
                }
                .pickerStyle(.segmented)
                .onChange(of: isExpense) { _, newValue in
                    if let cat = category, cat.isIncome == newValue {
                        category = nil
                    }
                }

                TextField("Amount", text: $amountText)
                    .keyboardType(.decimalPad)

                Picker("Category", selection: $category) {
                    Text("None").tag(Category?.none)
                    ForEach(filteredCategories) { category in
                        Text(category.name).tag(Category?.some(category))
                    }
                }

                DatePicker("Date", selection: $date, displayedComponents: .date)
                TextField("Note", text: $note)
            }
            .navigationTitle(transactionToEdit == nil ? "New Transaction" : "Edit Transaction")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(amount <= 0)
                }
            }
        }
    }

    private func save() {
        if let transaction = transactionToEdit {
            transaction.amount = amount
            transaction.date = date
            transaction.note = note
            transaction.isExpense = isExpense
            transaction.category = category
        } else {
            let transaction = BudgetTransaction(amount: amount, date: date, note: note,
                                                isExpense: isExpense, category: category)
            modelContext.insert(transaction)
        }
        dismiss()
    }
}

#Preview {
    AddTransactionView()
        .modelContainer(for: [BudgetTransaction.self, Category.self], inMemory: true)
}
