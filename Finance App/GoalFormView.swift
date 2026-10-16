//
//  GoalFormView.swift
//  FinanceApp
//
//  Created by Brenden Smit on 10/16/26.
//

import SwiftUI
import SwiftData

struct GoalFormView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    var goalToEdit: Goal?

    @State private var name: String
    @State private var targetAmountText: String
    @State private var savedAmountText: String
    @State private var monthlyContributionText: String
    @State private var hasTargetDate: Bool
    @State private var targetDate: Date
    @State private var icon: String
    @State private var colorName: String

    private let icons = [
        "flag.fill", "star.fill", "heart.fill", "house.fill", "car.fill",
        "airplane", "graduationcap.fill", "briefcase.fill", "banknote.fill",
        "shield.fill", "cross.case.fill", "gift.fill", "sparkles"
    ]

    private var targetAmount: Decimal {
        Decimal(string: targetAmountText) ?? 0
    }

    private var savedAmount: Decimal {
        Decimal(string: savedAmountText) ?? 0
    }

    private var monthlyContribution: Decimal {
        Decimal(string: monthlyContributionText) ?? 0
    }

    private var isValid: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty && targetAmount > 0
    }

    init(goalToEdit: Goal? = nil) {
        self.goalToEdit = goalToEdit
        _name = State(initialValue: goalToEdit?.name ?? "")
        _targetAmountText = State(initialValue: goalToEdit.map { "\($0.targetAmount)" } ?? "")
        _savedAmountText = State(initialValue: goalToEdit.map { "\($0.savedAmount)" } ?? "")
        _monthlyContributionText = State(initialValue: goalToEdit.map { "\($0.monthlyContribution)" } ?? "")
        _hasTargetDate = State(initialValue: goalToEdit?.targetDate != nil)
        _targetDate = State(initialValue: goalToEdit?.targetDate ?? Calendar.current.date(byAdding: .year, value: 1, to: .now)!)
        _icon = State(initialValue: goalToEdit?.icon ?? "flag.fill")
        _colorName = State(initialValue: goalToEdit?.colorName ?? "green")
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Goal Details") {
                    TextField("Goal Name (e.g. Emergency Fund)", text: $name)
                    TextField("Target Amount", text: $targetAmountText)
                        .keyboardType(.decimalPad)
                    TextField("Currently Saved", text: $savedAmountText)
                        .keyboardType(.decimalPad)
                    TextField("Monthly Contribution Target", text: $monthlyContributionText)
                        .keyboardType(.decimalPad)
                }

                Section("Timeline") {
                    Toggle("Set Target Date", isOn: $hasTargetDate)
                    if hasTargetDate {
                        DatePicker("Target Date", selection: $targetDate, displayedComponents: .date)
                    }
                }

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
            .navigationTitle(goalToEdit == nil ? "New Goal" : "Edit Goal")
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
        let resolvedTargetDate = hasTargetDate ? targetDate : nil
        if let goal = goalToEdit {
            goal.name = trimmed
            goal.targetAmount = targetAmount
            goal.savedAmount = savedAmount
            goal.monthlyContribution = monthlyContribution
            goal.targetDate = resolvedTargetDate
            goal.icon = icon
            goal.colorName = colorName
        } else {
            let goal = Goal(
                name: trimmed,
                icon: icon,
                colorName: colorName,
                targetAmount: targetAmount,
                targetDate: resolvedTargetDate,
                monthlyContribution: monthlyContribution,
                savedAmount: savedAmount,
                createdDate: .now
            )
            modelContext.insert(goal)
        }
        dismiss()
    }
}

#Preview {
    GoalFormView()
        .modelContainer(for: [Goal.self], inMemory: true)
}
