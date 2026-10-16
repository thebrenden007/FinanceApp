//
//  CategoryFormView.swift
//  FinanceApp
//
//  Created by Brenden Smit on 10/13/26.
//

import SwiftUI
import SwiftData

struct CategoryFormView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    var categoryToEdit: Category?

    @State private var name: String
    @State private var limitText: String
    @State private var icon: String
    @State private var colorName: String
    
    private let icons = [
        "cart.fill", "house.fill", "car.fill", "fork.knife", "heart.fill",
        "gift.fill", "bolt.fill", "tv.fill", "airplane", "book.fill",
        "pawprint.fill", "figure.run", "cross.case.fill", "graduationcap.fill",
        "tshirt.fill", "wrench.and.screwdriver.fill", "creditcard.fill",
        "banknote.fill", "tag.fill", "star.fill"
    ]

    private var monthlyLimit: Decimal {
        Decimal(string: limitText) ?? 0
    }

    private var isValid: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty && monthlyLimit >= 0
    }

    init(categoryToEdit: Category? = nil) {
        self.categoryToEdit = categoryToEdit
        _name = State(initialValue: categoryToEdit?.name ?? "")
        _limitText = State(initialValue: categoryToEdit.map { "\($0.monthlyLimit)" } ?? "")
        _icon = State(initialValue: categoryToEdit?.icon ?? "tag.fill")
        _colorName = State(initialValue: categoryToEdit?.colorName ?? "blue")
    }

    var body: some View {
        NavigationStack {
            Form {
                TextField("Name", text: $name)
                TextField("Monthly limit", text: $limitText)
                    .keyboardType(.decimalPad)

                Section("Icon") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 5), spacing: 16) {
                        ForEach(icons, id: \.self) { symbol in
                            Image(systemName: symbol)
                                .font(.title2)
                                .frame(width: 44, height: 44)
                                .background(icon == symbol ? Color.accentColor.opacity(0.25) : Color.clear)
                                .clipShape(Circle())
                                .onTapGesture { icon = symbol }
                        }
                    }
                    .padding(.vertical, 8)
                }
                Section("Color") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 5), spacing: 16) {
                        ForEach(CategoryColor.options, id: \.name) { option in
                            Circle()
                                .fill(option.color)
                                .frame(width: 36, height: 36)
                                .overlay(
                                    Circle()
                                        .stroke(Color.primary, lineWidth: colorName == option.name ? 3 : 0)
                                        .padding(-4)
                                )
                                .onTapGesture { colorName = option.name }
                        }
                    }
                    .padding(.vertical, 8)
                }
            }
            .navigationTitle(categoryToEdit == nil ? "New Category" : "Edit Category")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(!isValid)
                }
            }
        }
    }

    private func save() {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        if let category = categoryToEdit {
            category.name = trimmed
            category.icon = icon
            category.monthlyLimit = monthlyLimit
            category.colorName = colorName
        } else {
            let category = Category(name: trimmed, icon: icon,
                                    monthlyLimit: monthlyLimit, colorName: colorName)
            modelContext.insert(category)
        }
        dismiss()
    }
}

#Preview {
    CategoryFormView()
        .modelContainer(for: [BudgetTransaction.self, Category.self], inMemory: true)
}
