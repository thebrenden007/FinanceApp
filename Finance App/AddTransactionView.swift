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
    @State private var isRecurring: Bool
    @State private var recurrence: RecurrenceFrequency

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
        _isRecurring = State(initialValue: transactionToEdit?.isRecurring ?? false)
        _recurrence = State(initialValue: transactionToEdit?.recurrence ?? .monthly)
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

                Section("Recurrence") {
                    Toggle(isExpense ? "Recurring Bill / Subscription" : "Recurring Paycheck / Income", isOn: $isRecurring)
                    if isRecurring {
                        Picker("Frequency", selection: $recurrence) {
                            ForEach(RecurrenceFrequency.allCases.filter { $0 != .none }, id: \.self) { freq in
                                Text(freq.rawValue).tag(freq)
                            }
                        }
                    }
                }
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
        let finalRecurrence = isRecurring ? recurrence : .none

        if let transaction = transactionToEdit {
            transaction.amount = amount
            transaction.date = date
            transaction.note = note
            transaction.isExpense = isExpense
            transaction.category = category
            transaction.isRecurring = isRecurring
            transaction.recurrence = finalRecurrence
        } else {
            let transaction = BudgetTransaction(
                amount: amount,
                date: date,
                note: note,
                isExpense: isExpense,
                category: category,
                isRecurring: isRecurring,
                recurrence: finalRecurrence
            )
            modelContext.insert(transaction)
        }
        dismiss()
    }
}

#Preview {
    AddTransactionView()
        .modelContainer(for: [BudgetTransaction.self, Category.self], inMemory: true)
}
