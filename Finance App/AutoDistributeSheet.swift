//
//  AutoDistributeSheet.swift
//  FinanceApp
//
//  Created by Brenden Smit on 10/16/26.
//

import SwiftUI
import SwiftData

struct AutoDistributeSheet: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage("currencyCode") private var currencyCode = "USD"

    let goals: [Goal]
    let availableSurplus: Decimal

    @State private var distributeAmountText: String
    @State private var allocations: [PersistentIdentifier: Decimal] = [:]

    private var distributeAmount: Decimal {
        Decimal(string: distributeAmountText) ?? 0
    }

    private var incompleteGoals: [Goal] {
        goals.filter { $0.remainingAmount > 0 }
    }

    private var totalPlannedContributions: Decimal {
        incompleteGoals.reduce(Decimal.zero) { $0 + max(0, $1.monthlyContribution) }
    }

    private var totalRemainingNeeded: Decimal {
        incompleteGoals.reduce(Decimal.zero) { $0 + $1.remainingAmount }
    }

    init(goals: [Goal], availableSurplus: Decimal) {
        self.goals = goals
        self.availableSurplus = availableSurplus
        _distributeAmountText = State(initialValue: availableSurplus > 0 ? "\(availableSurplus)" : "")
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Available Cash Surplus")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text(availableSurplus, format: .currency(code: currencyCode))
                                .font(.title3.bold())
                                .foregroundStyle(availableSurplus > 0 ? .green : .secondary)
                        }
                        Spacer()
                    }

                    TextField("Amount to Distribute", text: $distributeAmountText)
                        .keyboardType(.decimalPad)
                        .font(.headline)
                        .onChange(of: distributeAmountText) { _, _ in
                            recalculateProportional()
                        }
                } header: {
                    Text("Funding Source")
                } footer: {
                    Text("Distribute your monthly cash surplus across all your active savings goals.")
                }

                Section("Distribution Strategies") {
                    Button {
                        applyStrategyProportionalToMonthly()
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Proportional to Monthly Targets")
                                    .font(.subheadline.bold())
                                Text("Allocates based on each goal's planned monthly contribution")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Image(systemName: "percent")
                                .foregroundStyle(.blue)
                        }
                    }

                    Button {
                        applyStrategyEqual()
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Split Equally")
                                    .font(.subheadline.bold())
                                Text("Splits the amount evenly across \(incompleteGoals.count) active goals")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Image(systemName: "equal.circle")
                                .foregroundStyle(.blue)
                        }
                    }

                    Button {
                        applyStrategySoonestDeadline()
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Prioritize Closest Deadline")
                                    .font(.subheadline.bold())
                                Text("Funds the goal with the nearest target date first")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Image(systemName: "calendar.badge.clock")
                                .foregroundStyle(.blue)
                        }
                    }
                }

                Section("Allocations Preview") {
                    if incompleteGoals.isEmpty {
                        Text("All goals are already 100% funded! 🎉")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(incompleteGoals) { goal in
                            let allocated = allocations[goal.persistentModelID] ?? 0
                            HStack(spacing: 12) {
                                ZStack {
                                    Circle()
                                        .fill(CategoryColor.color(named: goal.colorName).opacity(0.18))
                                        .frame(width: 32, height: 32)
                                    Image(systemName: goal.icon)
                                        .font(.caption)
                                        .foregroundStyle(CategoryColor.color(named: goal.colorName))
                                }

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(goal.name)
                                        .font(.subheadline.bold())
                                    Text("\(goal.savedAmount, format: .currency(code: currencyCode).precision(.fractionLength(0))) → \((goal.savedAmount + allocated), format: .currency(code: currencyCode).precision(.fractionLength(0)))")
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                }

                                Spacer()

                                Text("+\(allocated, format: .currency(code: currencyCode).precision(.fractionLength(0)))")
                                    .font(.subheadline.bold())
                                    .foregroundStyle(.green)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Distribute Surplus")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Distribute") {
                        executeDistribution()
                        dismiss()
                    }
                    .disabled(distributeAmount <= 0 || incompleteGoals.isEmpty)
                }
            }
            .onAppear {
                recalculateProportional()
            }
        }
    }

    private func roundDecimal(_ value: Decimal) -> Decimal {
        var result = Decimal()
        var mutable = value
        NSDecimalRound(&result, &mutable, 0, .plain)
        return result
    }

    private func recalculateProportional() {
        applyStrategyProportionalToMonthly()
    }

    private func applyStrategyProportionalToMonthly() {
        guard distributeAmount > 0, !incompleteGoals.isEmpty else {
            allocations.removeAll()
            return
        }

        if totalPlannedContributions > 0 {
            var newAllocations: [PersistentIdentifier: Decimal] = [:]
            for goal in incompleteGoals {
                let proportion = goal.monthlyContribution / totalPlannedContributions
                let rawShare = distributeAmount * proportion
                let share = min(goal.remainingAmount, roundDecimal(rawShare))
                newAllocations[goal.persistentModelID] = share
            }
            allocations = newAllocations
        } else {
            applyStrategyEqual()
        }
    }

    private func applyStrategyEqual() {
        guard distributeAmount > 0, !incompleteGoals.isEmpty else {
            allocations.removeAll()
            return
        }
        let rawPerGoal = min(distributeAmount / Decimal(incompleteGoals.count), totalRemainingNeeded)
        let perGoal = roundDecimal(rawPerGoal)
        var newAllocations: [PersistentIdentifier: Decimal] = [:]
        for goal in incompleteGoals {
            newAllocations[goal.persistentModelID] = min(goal.remainingAmount, perGoal)
        }
        allocations = newAllocations
    }

    private func applyStrategySoonestDeadline() {
        guard distributeAmount > 0, !incompleteGoals.isEmpty else {
            allocations.removeAll()
            return
        }
        let sorted = incompleteGoals.sorted {
            ($0.targetDate ?? .distantFuture) < ($1.targetDate ?? .distantFuture)
        }

        var remainingPool = distributeAmount
        var newAllocations: [PersistentIdentifier: Decimal] = [:]

        for goal in sorted {
            guard remainingPool > 0 else {
                newAllocations[goal.persistentModelID] = 0
                continue
            }
            let alloc = min(remainingPool, goal.remainingAmount)
            newAllocations[goal.persistentModelID] = alloc
            remainingPool -= alloc
        }
        allocations = newAllocations
    }

    private func executeDistribution() {
        for goal in incompleteGoals {
            if let alloc = allocations[goal.persistentModelID], alloc > 0 {
                goal.savedAmount += alloc
            }
        }
    }
}
