//
//  GoalsView.swift
//  FinanceApp
//
//  Created by Brenden Smit on 10/16/26.
//

import SwiftUI
import SwiftData

struct GoalsView: View {
    @Environment(\.modelContext) private var modelContext
    @AppStorage("currencyCode") private var currencyCode = "USD"
    @AppStorage("startingSavings") private var startingSavings: Double = 0

    @Query(sort: \Goal.createdDate) private var goals: [Goal]
    @Query private var transactions: [BudgetTransaction]

    @State private var showingAddGoal = false
    @State private var goalToDetail: Goal?
    @State private var goalToContribute: Goal?
    @State private var showingAutoDistribute = false

    // MARK: - Current Month Net Cash Flow

    private var currentMonthCashFlow: Decimal {
        guard let interval = Calendar.current.dateInterval(of: .month, for: .now) else { return 0 }
        let currentTransactions = transactions.filter { $0.date >= interval.start && $0.date < interval.end }
        let income = currentTransactions.filter { !$0.isExpense }.reduce(Decimal.zero) { $0 + $1.amount }
        let spent = currentTransactions.filter { $0.isExpense }.reduce(Decimal.zero) { $0 + $1.amount }
        return income - spent
    }

    // MARK: - Total Savings Metrics

    private var goalsSavedTotal: Decimal {
        goals.reduce(Decimal.zero) { $0 + $1.savedAmount }
    }

    private var totalTargetAmount: Decimal {
        goals.reduce(Decimal.zero) { $0 + $1.targetAmount }
    }

    private var grandTotalSavings: Decimal {
        Decimal(startingSavings) + goalsSavedTotal
    }

    private var overallProgress: Double {
        guard totalTargetAmount > 0 else { return 0 }
        return NSDecimalNumber(decimal: min(goalsSavedTotal / totalTargetAmount, 1)).doubleValue
    }

    private var totalMonthlyContributionTarget: Decimal {
        goals.reduce(Decimal.zero) { $0 + $1.monthlyContribution }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // MARK: - Grand Total Savings Hero Card
                    totalSavingsCard

                    // MARK: - Quick Actions Bar
                    quickActionsBar

                    // MARK: - Active Goals List
                    goalsListSection
                }
                .padding()
            }
            .navigationTitle("Savings & Goals")
            .profileButton()
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingAddGoal = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddGoal) {
                GoalFormView()
            }
            .sheet(item: $goalToDetail) { goal in
                NavigationStack {
                    GoalDetailView(goal: goal, netCashFlow: currentMonthCashFlow)
                }
            }
            .sheet(item: $goalToContribute) { goal in
                GoalContributeSheet(goal: goal, netCashFlow: currentMonthCashFlow)
            }
            .sheet(isPresented: $showingAutoDistribute) {
                AutoDistributeSheet(goals: goals, availableSurplus: max(0, currentMonthCashFlow))
            }
        }
    }

    // MARK: - Hero Total Savings Card

    private var totalSavingsCard: some View {
        VStack(spacing: 16) {
            VStack(spacing: 6) {
                Text("TOTAL SAVINGS TRACKER")
                    .font(.caption2.bold())
                    .foregroundStyle(.secondary)
                    .tracking(1.2)

                Text(grandTotalSavings, format: .currency(code: currencyCode).precision(.fractionLength(0)))
                    .font(.system(size: 38, weight: .bold, design: .rounded))
                    .foregroundStyle(.primary)

                if startingSavings > 0 {
                    Text("\(Decimal(startingSavings), format: .currency(code: currencyCode).precision(.fractionLength(0))) baseline + \(goalsSavedTotal, format: .currency(code: currencyCode).precision(.fractionLength(0))) in goals")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.top, 4)

            // Progress across all goals
            if totalTargetAmount > 0 {
                VStack(spacing: 6) {
                    ProgressView(value: overallProgress)
                        .tint(.green)

                    HStack {
                        Text("\(Int((overallProgress * 100).rounded()))% of all goals funded")
                            .font(.caption2.bold())
                            .foregroundStyle(.green)
                        Spacer()
                        Text("Target: \(totalTargetAmount, format: .currency(code: currencyCode).precision(.fractionLength(0)))")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Divider()

            // 3-way KPI Breakdown
            HStack {
                VStack(spacing: 2) {
                    Text("In Goals")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Text(goalsSavedTotal, format: .currency(code: currencyCode).precision(.fractionLength(0)))
                        .font(.subheadline.bold())
                }
                .frame(maxWidth: .infinity)

                Divider().frame(height: 28)

                VStack(spacing: 2) {
                    Text("Monthly Pace")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Text("\(totalMonthlyContributionTarget, format: .currency(code: currencyCode).precision(.fractionLength(0)))/mo")
                        .font(.subheadline.bold())
                }
                .frame(maxWidth: .infinity)

                Divider().frame(height: 28)

                VStack(spacing: 2) {
                    Text("Cash Surplus")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Text(currentMonthCashFlow, format: .currency(code: currencyCode).precision(.fractionLength(0)))
                        .font(.subheadline.bold())
                        .foregroundStyle(currentMonthCashFlow >= 0 ? .green : .red)
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 20))
    }

    // MARK: - Quick Actions Bar

    private var quickActionsBar: some View {
        HStack(spacing: 12) {
            Button {
                showingAutoDistribute = true
            } label: {
                Label("Distribute Surplus", systemImage: "sparkles")
                    .font(.caption.bold())
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
            }
            .buttonStyle(.borderedProminent)
            .tint(.blue)
            .disabled(currentMonthCashFlow <= 0 || goals.isEmpty)

            Button {
                showingAddGoal = true
            } label: {
                Label("New Goal", systemImage: "plus")
                    .font(.caption.bold())
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
            }
            .buttonStyle(.bordered)
        }
    }

    // MARK: - Goals List Section

    private var goalsListSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Active Goals (\(goals.count))")
                .font(.headline)

            if goals.isEmpty {
                VStack(spacing: 10) {
                    Image(systemName: "flag.checkered.circle")
                        .font(.system(size: 44))
                        .foregroundStyle(.secondary)
                        .padding(.top, 8)

                    Text("No Savings Goals Yet")
                        .font(.headline)
                    Text("Create a goal for an emergency fund, travel, buying a car, or investing.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)

                    Button("Create First Goal") {
                        showingAddGoal = true
                    }
                    .font(.caption.bold())
                    .buttonStyle(.borderedProminent)
                    .padding(.top, 4)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 16))
            } else {
                ForEach(goals) { goal in
                    GoalRowView(
                        goal: goal,
                        netCashFlow: currentMonthCashFlow,
                        onContribute: {
                            goalToContribute = goal
                        },
                        onEdit: {
                            goalToDetail = goal
                        }
                    )
                }
            }
        }
    }
}

#Preview {
    GoalsView()
        .modelContainer(for: [Goal.self, BudgetTransaction.self], inMemory: true)
}
