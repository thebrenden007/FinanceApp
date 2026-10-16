//
//  DashboardView.swift
//  FinanceApp
//
//  Created by Brenden Smit on 10/14/26.
//

import SwiftUI
import SwiftData

enum Period: String, CaseIterable {
    case month = "Month"
    case year = "Year"
}

enum CategoryType: String, CaseIterable {
    case expense = "Expenses"
    case income = "Income"
}

struct DashboardView: View {
    @AppStorage("userName") private var userName = ""
    @AppStorage("currencyCode") private var currencyCode = "USD"
    @AppStorage("monthlyIncome") private var monthlyIncome: Double = 0

    @Query(sort: \Category.name) private var categories: [Category]
    @Query private var transactions: [BudgetTransaction]
    @Query(sort: \Goal.createdDate) private var goals: [Goal]

    @State private var period: Period = .month
    @State private var selectedDate = Date.now
    @State private var categorySection: CategoryType = .expense
    @State private var showingAddGoal = false
    @State private var goalToEdit: Goal?
    @State private var goalToContribute: Goal?

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 16), count: 3)

    // MARK: - Period logic

    private var calendarComponent: Calendar.Component {
        period == .month ? .month : .year
    }

    private var periodTransactions: [BudgetTransaction] {
        guard let interval = Calendar.current.dateInterval(of: calendarComponent, for: selectedDate) else { return [] }
        return transactions.filter { $0.date >= interval.start && $0.date < interval.end }
    }

    private var limitMultiplier: Decimal { period == .year ? 12 : 1 }

    private var isCurrentPeriod: Bool {
        Calendar.current.isDate(selectedDate, equalTo: .now, toGranularity: calendarComponent)
    }

    private var periodTitle: String {
        period == .month
            ? selectedDate.formatted(.dateTime.month(.wide).year())
            : selectedDate.formatted(.dateTime.year())
    }

    private func shift(by value: Int) {
        if let newDate = Calendar.current.date(byAdding: calendarComponent, value: value, to: selectedDate) {
            selectedDate = newDate
        }
    }

    // MARK: - Filtered Categories

    private var expenseCategories: [Category] {
        categories.filter { !$0.isIncome }
    }

    private var incomeCategories: [Category] {
        categories.filter { $0.isIncome }
    }

    // MARK: - Totals & Calculations

    private var totalSpent: Decimal {
        periodTransactions.filter { $0.isExpense }.reduce(0) { $0 + $1.amount }
    }

    private var totalIncome: Decimal {
        periodTransactions.filter { !$0.isExpense }.reduce(0) { $0 + $1.amount }
    }

    private var netCashFlow: Decimal {
        totalIncome - totalSpent
    }

    private var savingsRate: Double? {
        guard totalIncome > 0 else { return nil }
        return NSDecimalNumber(decimal: (netCashFlow / totalIncome) * 100).doubleValue
    }

    private var totalLimit: Decimal {
        expenseCategories.reduce(Decimal.zero) { $0 + $1.monthlyLimit } * limitMultiplier
    }

    private var totalIncomeTarget: Decimal {
        let categoryTargets = incomeCategories.reduce(Decimal.zero) { $0 + $1.monthlyLimit } * limitMultiplier
        if categoryTargets > 0 {
            return categoryTargets
        }
        return Decimal(monthlyIncome) * limitMultiplier
    }

    private var expenseProgress: Double {
        guard totalLimit > 0 else {
            if totalIncome > 0 {
                return NSDecimalNumber(decimal: totalSpent / totalIncome).doubleValue
            }
            return 0
        }
        return NSDecimalNumber(decimal: totalSpent / totalLimit).doubleValue
    }

    private var incomeProgress: Double {
        guard totalIncomeTarget > 0 else {
            return totalIncome > 0 ? 1.0 : 0
        }
        return NSDecimalNumber(decimal: totalIncome / totalIncomeTarget).doubleValue
    }

    private var uncategorizedSpent: Decimal {
        periodTransactions
            .filter { $0.isExpense && $0.category == nil }
            .reduce(0) { $0 + $1.amount }
    }

    private var uncategorizedIncome: Decimal {
        periodTransactions
            .filter { !$0.isExpense && $0.category == nil }
            .reduce(0) { $0 + $1.amount }
    }

    private func spent(in category: Category) -> Decimal {
        periodTransactions
            .filter { $0.isExpense && $0.category === category }
            .reduce(0) { $0 + $1.amount }
    }

    private func earned(in category: Category) -> Decimal {
        periodTransactions
            .filter { !$0.isExpense && $0.category === category }
            .reduce(0) { $0 + $1.amount }
    }

    private var greeting: String {
        switch Calendar.current.component(.hour, from: .now) {
        case 0..<12: return "Good morning"
        case 12..<17: return "Good afternoon"
        default: return "Good evening"
        }
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    Text("\(greeting), \(userName)")
                        .font(.title2.bold())
                        .frame(maxWidth: .infinity, alignment: .leading)

                    periodPicker
                    heroDualRing
                    summaryCard
                    zeroBasedBudgetCard
                    categorySectionView
                    goalsSectionView
                }
                .padding()
            }
            .navigationTitle("Dashboard")
            .profileButton()
            .onChange(of: period) { _, _ in
                selectedDate = .now
            }
            .sheet(isPresented: $showingAddGoal) {
                GoalFormView()
            }
            .sheet(item: $goalToEdit) { goal in
                GoalFormView(goalToEdit: goal)
            }
            .sheet(item: $goalToContribute) { goal in
                GoalContributeSheet(goal: goal, netCashFlow: netCashFlow)
            }
        }
    }

    // MARK: - Pieces

    private var periodPicker: some View {
        VStack(spacing: 12) {
            Picker("Period", selection: $period) {
                ForEach(Period.allCases, id: \.self) { Text($0.rawValue) }
            }
            .pickerStyle(.segmented)

            HStack {
                Button { shift(by: -1) } label: {
                    Image(systemName: "chevron.left")
                }
                Spacer()
                Text(periodTitle)
                    .font(.headline)
                Spacer()
                Button { shift(by: 1) } label: {
                    Image(systemName: "chevron.right")
                }
                .disabled(isCurrentPeriod)
            }
        }
    }

    private var heroDualRing: some View {
        let isDeficit = netCashFlow < 0
        let isOverBudget = totalLimit > 0 && totalSpent > totalLimit

        return VStack(spacing: 12) {
            ZStack {
                // Outer ring: Income vs Target (Teal/Green)
                RingView(
                    progress: incomeProgress,
                    color: .green,
                    lineWidth: 18,
                    gradient: [.teal, .green, .mint]
                )
                .frame(width: 220, height: 220)

                // Inner ring: Expenses vs Budget (Purple/Blue, or Red if over)
                RingView(
                    progress: expenseProgress,
                    color: isOverBudget ? .red : .purple,
                    lineWidth: 18,
                    gradient: isOverBudget ? nil : [.blue, .purple, .pink]
                )
                .frame(width: 172, height: 172)

                // Center metrics: Net Cash Flow + Savings Rate
                VStack(spacing: 4) {
                    Text(netCashFlow >= 0 ? "+\(netCashFlow.formatted(.currency(code: currencyCode).precision(.fractionLength(0))))" : netCashFlow.formatted(.currency(code: currencyCode).precision(.fractionLength(0))))
                        .font(.title2.bold())
                        .foregroundStyle(isDeficit ? .red : .green)
                        .minimumScaleFactor(0.7)
                        .lineLimit(1)

                    if let rate = savingsRate {
                        Text("\(Int(rate.rounded()))% saved")
                            .font(.caption.bold())
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(rate >= 0 ? Color.green.opacity(0.18) : Color.red.opacity(0.18))
                            .foregroundStyle(rate >= 0 ? .green : .red)
                            .clipShape(Capsule())
                    } else {
                        Text("Net cash flow")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.horizontal, 24)
            }
            .frame(width: 220, height: 220)
            .padding(.top, 4)

            // Ring legend
            HStack(spacing: 20) {
                HStack(spacing: 6) {
                    Circle()
                        .fill(LinearGradient(colors: [.teal, .green], startPoint: .leading, endPoint: .trailing))
                        .frame(width: 10, height: 10)
                    Text("Income: \(totalIncome, format: .currency(code: currencyCode).precision(.fractionLength(0)))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                HStack(spacing: 6) {
                    Circle()
                        .fill(LinearGradient(colors: [.purple, .pink], startPoint: .leading, endPoint: .trailing))
                        .frame(width: 10, height: 10)
                    Text("Spent: \(totalSpent, format: .currency(code: currencyCode).precision(.fractionLength(0)))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.vertical, 8)
    }

    private var summaryCard: some View {
        HStack {
            SummaryItem(title: "Income", amount: totalIncome, color: .green)
            Divider().frame(height: 40)
            SummaryItem(title: "Spent", amount: totalSpent, color: .red)
            Divider().frame(height: 40)
            SummaryItem(title: "Net", amount: netCashFlow,
                        color: netCashFlow >= 0 ? .green : .red)
            if let rate = savingsRate {
                Divider().frame(height: 40)
                VStack(spacing: 4) {
                    Text("Saved")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("\(Int(rate.rounded()))%")
                        .font(.headline)
                        .foregroundStyle(rate >= 0 ? .green : .red)
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 16))
    }

    private var zeroBasedBudgetCard: some View {
        let unallocated = totalIncomeTarget - totalLimit
        let isBalanced = totalIncomeTarget > 0 && unallocated == 0
        let isOverBudget = totalIncomeTarget > 0 && unallocated < 0

        return VStack(alignment: .leading, spacing: 10) {
            HStack {
                Label("Zero-Based Budget", systemImage: "scalemass.fill")
                    .font(.subheadline.bold())
                Spacer()
                if totalIncomeTarget > 0 {
                    Text(isBalanced ? "Balanced" : (isOverBudget ? "Over Target" : "Surplus"))
                        .font(.caption2.bold())
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(isBalanced ? Color.blue.opacity(0.15) : (isOverBudget ? Color.red.opacity(0.15) : Color.green.opacity(0.15)))
                        .foregroundStyle(isBalanced ? .blue : (isOverBudget ? .red : .green))
                        .clipShape(Capsule())
                }
            }

            if totalIncomeTarget > 0 {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Target Income")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        Text(totalIncomeTarget, format: .currency(code: currencyCode).precision(.fractionLength(0)))
                            .font(.subheadline.bold())
                    }
                    Spacer()
                    Image(systemName: "minus")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Spacer()
                    VStack(alignment: .center, spacing: 2) {
                        Text("Allocated")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        Text(totalLimit, format: .currency(code: currencyCode).precision(.fractionLength(0)))
                            .font(.subheadline.bold())
                    }
                    Spacer()
                    Image(systemName: "equal")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Spacer()
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(isOverBudget ? "Deficit" : "Unallocated")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        Text(abs(unallocated), format: .currency(code: currencyCode).precision(.fractionLength(0)))
                            .font(.subheadline.bold())
                            .foregroundStyle(isOverBudget ? .red : .green)
                    }
                }

                Text(isOverBudget
                     ? "Budget limits exceed expected income by \(abs(unallocated), format: .currency(code: currencyCode).precision(.fractionLength(0)))."
                     : (isBalanced
                        ? "Every dollar has a job! 100% of expected income is budgeted."
                        : "You have \(unallocated, format: .currency(code: currencyCode).precision(.fractionLength(0))) unassigned. Allocate it to categories or savings goals!"))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            } else {
                Text("Set your baseline monthly income in Profile or create income categories to plan your zero-based budget.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 16))
    }

    private var categorySectionView: some View {
        VStack(spacing: 16) {
            Picker("Categories", selection: $categorySection) {
                ForEach(CategoryType.allCases, id: \.self) { type in
                    Text(type.rawValue).tag(type)
                }
            }
            .pickerStyle(.segmented)

            if categorySection == .expense {
                if expenseCategories.isEmpty {
                    Text("No expense categories found.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(.vertical, 8)
                } else {
                    LazyVGrid(columns: columns, spacing: 24) {
                        ForEach(expenseCategories) { category in
                            CategoryRingCell(
                                name: category.name,
                                icon: category.icon,
                                spent: spent(in: category),
                                limit: category.monthlyLimit * limitMultiplier,
                                color: CategoryColor.color(named: category.colorName),
                                isIncome: false
                            )
                        }
                    }
                    .padding(.vertical, 8)
                }

                if uncategorizedSpent > 0 {
                    HStack {
                        Image(systemName: "questionmark.circle")
                        Text("Uncategorized Spent")
                        Spacer()
                        Text(uncategorizedSpent, format: .currency(code: currencyCode))
                            .bold()
                    }
                    .padding()
                    .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 16))
                }
            } else {
                if incomeCategories.isEmpty {
                    Text("No income categories yet. Add them in Categories tab!")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(.vertical, 8)
                } else {
                    LazyVGrid(columns: columns, spacing: 24) {
                        ForEach(incomeCategories) { category in
                            CategoryRingCell(
                                name: category.name,
                                icon: category.icon,
                                spent: earned(in: category),
                                limit: category.monthlyLimit * limitMultiplier,
                                color: CategoryColor.color(named: category.colorName),
                                isIncome: true
                            )
                        }
                    }
                    .padding(.vertical, 8)
                }

                if uncategorizedIncome > 0 {
                    HStack {
                        Image(systemName: "questionmark.circle")
                        Text("Uncategorized Income")
                        Spacer()
                        Text(uncategorizedIncome, format: .currency(code: currencyCode))
                            .bold()
                            .foregroundStyle(.green)
                    }
                    .padding()
                    .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 16))
                }
            }
        }
    }

    private var goalsSectionView: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Savings Goals", systemImage: "target")
                    .font(.headline)
                Spacer()
                Button {
                    showingAddGoal = true
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.title3)
                }
            }

            if goals.isEmpty {
                VStack(spacing: 8) {
                    Text("No savings goals yet.")
                        .font(.subheadline.bold())
                    Text("Track emergency funds, vacations, or major purchases funded by your income surplus.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                    Button("Create Goal") {
                        showingAddGoal = true
                    }
                    .font(.caption.bold())
                    .buttonStyle(.bordered)
                    .padding(.top, 4)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 16))
            } else {
                ForEach(goals) { goal in
                    GoalRowView(
                        goal: goal,
                        netCashFlow: netCashFlow,
                        onContribute: {
                            goalToContribute = goal
                        },
                        onEdit: {
                            goalToEdit = goal
                        }
                    )
                }
            }
        }
    }
}

// MARK: - Goal Row View

struct GoalRowView: View {
    @AppStorage("currencyCode") private var currencyCode = "USD"
    let goal: Goal
    let netCashFlow: Decimal
    let onContribute: () -> Void
    let onEdit: () -> Void

    private var isMonthlyFunded: Bool {
        goal.monthlyContribution > 0 && netCashFlow >= goal.monthlyContribution
    }

    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(CategoryColor.color(named: goal.colorName).opacity(0.18))
                        .frame(width: 40, height: 40)
                    Image(systemName: goal.icon)
                        .font(.title3)
                        .foregroundStyle(CategoryColor.color(named: goal.colorName))
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(goal.name)
                        .font(.subheadline.bold())

                    if let targetDate = goal.targetDate, let months = goal.monthsRemaining {
                        Text("Target: \(targetDate.formatted(.dateTime.month().year())) • \(months) mo\(months == 1 ? "" : "s") left")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    } else if let projected = goal.projectedCompletionDate {
                        Text("Projected: \(projected.formatted(.dateTime.month().year()))")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()

                Button {
                    onContribute()
                } label: {
                    Label("Add", systemImage: "plus")
                        .font(.caption.bold())
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
                .tint(CategoryColor.color(named: goal.colorName))
            }

            ProgressView(value: goal.progress)
                .tint(CategoryColor.color(named: goal.colorName))

            HStack {
                Text("\(goal.savedAmount, format: .currency(code: currencyCode).precision(.fractionLength(0))) of \(goal.targetAmount, format: .currency(code: currencyCode).precision(.fractionLength(0))) (\(Int(goal.progress * 100))%)")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Spacer()

                if goal.monthlyContribution > 0 {
                    HStack(spacing: 4) {
                        Text("+\(goal.monthlyContribution, format: .currency(code: currencyCode).precision(.fractionLength(0)))/mo")
                            .font(.caption.bold())
                        if isMonthlyFunded {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.caption2)
                                .foregroundStyle(.green)
                        }
                    }
                    .foregroundStyle(isMonthlyFunded ? .green : .secondary)
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 16))
        .contentShape(Rectangle())
        .onTapGesture {
            onEdit()
        }
    }
}

// MARK: - Goal Contribute Sheet

struct GoalContributeSheet: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage("currencyCode") private var currencyCode = "USD"
    let goal: Goal
    let netCashFlow: Decimal

    @State private var amountText = ""

    private var amount: Decimal {
        Decimal(string: amountText) ?? 0
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Goal") {
                    HStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(CategoryColor.color(named: goal.colorName).opacity(0.18))
                                .frame(width: 44, height: 44)
                            Image(systemName: goal.icon)
                                .font(.title3)
                                .foregroundStyle(CategoryColor.color(named: goal.colorName))
                        }

                        VStack(alignment: .leading, spacing: 4) {
                            Text(goal.name)
                                .font(.headline)
                            Text("\(goal.savedAmount, format: .currency(code: currencyCode).precision(.fractionLength(0))) saved of \(goal.targetAmount, format: .currency(code: currencyCode).precision(.fractionLength(0)))")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                Section("Amount to Add") {
                    TextField("Amount", text: $amountText)
                        .keyboardType(.decimalPad)
                        .font(.title3.bold())

                    HStack {
                        if goal.monthlyContribution > 0 {
                            Button("Monthly Target (\(goal.monthlyContribution, format: .currency(code: currencyCode).precision(.fractionLength(0))))") {
                                amountText = "\(goal.monthlyContribution)"
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                        }

                        if netCashFlow > 0 {
                            Button("Current Surplus (\(netCashFlow, format: .currency(code: currencyCode).precision(.fractionLength(0))))") {
                                amountText = "\(netCashFlow)"
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                        }
                    }
                }

                if amount > 0 {
                    Section {
                        let newTotal = goal.savedAmount + amount
                        let newProgress = goal.targetAmount > 0 ? NSDecimalNumber(decimal: min(newTotal / goal.targetAmount, 1)).doubleValue : 0
                        VStack(alignment: .leading, spacing: 6) {
                            Text("New Total: \(newTotal, format: .currency(code: currencyCode).precision(.fractionLength(0))) (\(Int(newProgress * 100))%)")
                                .font(.subheadline.bold())
                            ProgressView(value: newProgress)
                                .tint(CategoryColor.color(named: goal.colorName))
                        }
                        .padding(.vertical, 4)
                    } header: {
                        Text("Updated Progress")
                    }
                }
            }
            .navigationTitle("Add to Goal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add Funds") {
                        goal.savedAmount += amount
                        dismiss()
                    }
                    .disabled(amount <= 0)
                }
            }
        }
    }
}

// MARK: - Helper views

struct SummaryItem: View {
    @AppStorage("currencyCode") private var currencyCode = "USD"

    let title: String
    let amount: Decimal
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(amount, format: .currency(code: currencyCode).precision(.fractionLength(0)))
                .font(.headline)
                .foregroundStyle(color)
        }
        .frame(maxWidth: .infinity)
    }
}

struct CategoryRingCell: View {
    @AppStorage("currencyCode") private var currencyCode = "USD"

    let name: String
    let icon: String
    let spent: Decimal
    let limit: Decimal
    let color: Color
    var isIncome: Bool = false

    private var hasLimit: Bool { limit > 0 }
    private var isOver: Bool { !isIncome && hasLimit && spent > limit }
    private var isMet: Bool { isIncome && hasLimit && spent >= limit }

    private var progress: Double {
        guard hasLimit else { return spent > 0 ? 1 : 0 }
        return NSDecimalNumber(decimal: spent / limit).doubleValue
    }

    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                RingView(
                    progress: progress,
                    color: isIncome ? (isMet ? .green : color) : (isOver ? .red : color),
                    lineWidth: 12,
                    gradient: isIncome ? (isMet ? [.teal, .green] : nil) : nil
                )
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundStyle(isIncome ? (isMet ? .green : color) : color)
            }
            .frame(width: 84, height: 84)

            Text(name)
                .font(.caption.bold())
                .lineLimit(1)

            Text(spent, format: .currency(code: currencyCode).precision(.fractionLength(0)))
                .font(.caption2)
                .foregroundStyle(isIncome ? (isMet ? .green : .secondary) : (isOver ? .red : .secondary))
        }
    }
}

struct RingView: View {
    let progress: Double
    let color: Color
    let lineWidth: CGFloat
    var gradient: [Color]? = nil

    @State private var animated: Double = 0

    private var strokeStyle: AnyShapeStyle {
        if let gradient {
            return AnyShapeStyle(AngularGradient(colors: gradient, center: .center))
        } else {
            return AnyShapeStyle(color)
        }
    }

    var body: some View {
        ZStack {
            // Faint track behind the ring
            Circle()
                .stroke(color.opacity(0.2), lineWidth: lineWidth)

            // First lap
            Circle()
                .trim(from: 0, to: min(animated, 1))
                .stroke(strokeStyle, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))

            // Second lap, drawn over the first with a shadow
            if animated > 1 {
                Circle()
                    .trim(from: 0, to: min(animated - 1, 1))
                    .stroke(strokeStyle, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .shadow(color: .black.opacity(0.35), radius: 3)
            }
        }
        .task(id: progress) {
            animated = 0
            try? await Task.sleep(for: .milliseconds(80))
            withAnimation(.easeOut(duration: 1.1)) {
                animated = progress
            }
        }
    }
}

#Preview {
    DashboardView()
        .modelContainer(for: [BudgetTransaction.self, Category.self, Goal.self], inMemory: true)
}
