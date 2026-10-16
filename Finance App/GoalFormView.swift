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

    @Query private var categories: [Category]
    @AppStorage("currencyCode") private var currencyCode = "USD"
    @AppStorage("monthlyIncome") private var baselineMonthlyIncome: Double = 0

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

    private var remainingToSave: Decimal {
        max(0, targetAmount - savedAmount)
    }

    // MARK: - Cash Flow & Feasibility Calculations

    private var monthlyIncomeEstimate: Decimal {
        let incomeFromCategories = categories.filter { $0.isIncome }.reduce(Decimal.zero) { $0 + $1.monthlyLimit }
        if incomeFromCategories > 0 {
            return incomeFromCategories
        }
        return Decimal(baselineMonthlyIncome)
    }

    private var monthlyExpenseBudget: Decimal {
        categories.filter { !$0.isIncome }.reduce(Decimal.zero) { $0 + $1.monthlyLimit }
    }

    private var availableMonthlySurplus: Decimal {
        max(0, monthlyIncomeEstimate - monthlyExpenseBudget)
    }

    private var monthsRemaining: Int {
        let comps = Calendar.current.dateComponents([.month, .day], from: .now, to: targetDate)
        let months = comps.month ?? 0
        let days = comps.day ?? 0
        return max(1, months + (days > 0 ? 1 : 0))
    }

    private var calculatedRequiredMonthly: Decimal {
        guard monthsRemaining > 0 else { return 0 }
        return remainingToSave / Decimal(monthsRemaining)
    }

    private var projectedMonthsNeeded: Int? {
        guard monthlyContribution > 0, remainingToSave > 0 else { return nil }
        return max(1, Int(ceil(NSDecimalNumber(decimal: remainingToSave / monthlyContribution).doubleValue)))
    }

    private var projectedDate: Date? {
        guard let months = projectedMonthsNeeded else { return nil }
        return Calendar.current.date(byAdding: .month, value: months, to: .now)
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
                    TextField("Goal Name (e.g. Vacation, House, Car)", text: $name)
                    TextField("Target Amount", text: $targetAmountText)
                        .keyboardType(.decimalPad)
                    TextField("Currently Saved", text: $savedAmountText)
                        .keyboardType(.decimalPad)
                }

                Section("Timeline & Target Date") {
                    Toggle("Target Completion Date", isOn: $hasTargetDate)
                    if hasTargetDate {
                        DatePicker("Target Date", selection: $targetDate, in: Date.now..., displayedComponents: .date)

                        if targetAmount > 0 {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("\(monthsRemaining) months to save \(remainingToSave, format: .currency(code: currencyCode).precision(.fractionLength(0)))")
                                        .font(.subheadline.bold())
                                    Text("Requires \(calculatedRequiredMonthly, format: .currency(code: currencyCode).precision(.fractionLength(0))) / month")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                                Button("Apply") {
                                    monthlyContributionText = "\(calculatedRequiredMonthly)"
                                }
                                .buttonStyle(.borderedProminent)
                                .controlSize(.small)
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }

                Section("Monthly Contribution") {
                    TextField("Planned Monthly Contribution", text: $monthlyContributionText)
                        .keyboardType(.decimalPad)

                    if monthlyContribution > 0 {
                        if !hasTargetDate, let date = projectedDate, let months = projectedMonthsNeeded {
                            Text("At this rate, you'll reach your goal in \(months) months (\(date.formatted(.dateTime.month().year()))).")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                // MARK: - Smart Income & Budget Feasibility Section
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Monthly Income")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                                Text(monthlyIncomeEstimate, format: .currency(code: currencyCode).precision(.fractionLength(0)))
                                    .font(.caption.bold())
                            }
                            Spacer()
                            Text("−")
                                .foregroundStyle(.secondary)
                            Spacer()
                            VStack(alignment: .center, spacing: 2) {
                                Text("Monthly Spending")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                                Text(monthlyExpenseBudget, format: .currency(code: currencyCode).precision(.fractionLength(0)))
                                    .font(.caption.bold())
                            }
                            Spacer()
                            Text("=")
                                .foregroundStyle(.secondary)
                            Spacer()
                            VStack(alignment: .trailing, spacing: 2) {
                                Text("Available to Save")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                                Text(availableMonthlySurplus, format: .currency(code: currencyCode).precision(.fractionLength(0)))
                                    .font(.caption.bold())
                                    .foregroundStyle(.green)
                            }
                        }

                        Divider()

                        let contributionToCompare = monthlyContribution > 0 ? monthlyContribution : (hasTargetDate ? calculatedRequiredMonthly : 0)

                        if contributionToCompare > 0 {
                            if availableMonthlySurplus >= contributionToCompare {
                                let cushion = availableMonthlySurplus - contributionToCompare
                                HStack(alignment: .top, spacing: 6) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(.green)
                                    Text("Fits your monthly cash flow! You will still have \(cushion, format: .currency(code: currencyCode).precision(.fractionLength(0))) cushion each month.")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            } else {
                                let deficit = contributionToCompare - availableMonthlySurplus
                                HStack(alignment: .top, spacing: 6) {
                                    Image(systemName: "exclamationmark.triangle.fill")
                                        .foregroundStyle(.orange)
                                    Text("Requires \(deficit, format: .currency(code: currencyCode).precision(.fractionLength(0))) more than your current monthly surplus (\(availableMonthlySurplus, format: .currency(code: currencyCode).precision(.fractionLength(0))). Consider extending your target date or trimming category budgets.")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }

                        if availableMonthlySurplus > 0 && monthlyContribution != availableMonthlySurplus {
                            Button("Match Available Monthly Surplus (\(availableMonthlySurplus, format: .currency(code: currencyCode).precision(.fractionLength(0))))") {
                                monthlyContributionText = "\(availableMonthlySurplus)"
                            }
                            .font(.caption.bold())
                            .padding(.top, 2)
                        }
                    }
                    .padding(.vertical, 4)
                } header: {
                    Text("Cash Flow & Feasibility")
                } footer: {
                    Text("Calculated automatically from your income and category expense limits.")
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
        let resolvedContribution = monthlyContribution > 0 ? monthlyContribution : (hasTargetDate ? calculatedRequiredMonthly : 0)

        if let goal = goalToEdit {
            goal.name = trimmed
            goal.targetAmount = targetAmount
            goal.savedAmount = savedAmount
            goal.monthlyContribution = resolvedContribution
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
                monthlyContribution: resolvedContribution,
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
        .modelContainer(for: [Goal.self, Category.self], inMemory: true)
}
