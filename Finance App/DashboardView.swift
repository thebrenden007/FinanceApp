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

struct DashboardView: View {
    @AppStorage("userName") private var userName = ""
    @AppStorage("currencyCode") private var currencyCode = "USD"

    @Query(sort: \Category.name) private var categories: [Category]
    @Query private var transactions: [BudgetTransaction]

    @State private var period: Period = .month
    @State private var selectedDate = Date.now

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 16), count: 3)

    // MARK: - Period logic

    private var calendarComponent: Calendar.Component {
        period == .month ? .month : .year
    }

    private var periodTransactions: [BudgetTransaction] {
        guard let interval = Calendar.current.dateInterval(of: calendarComponent, for: selectedDate) else { return [] }
        return transactions.filter { $0.date >= interval.start && $0.date < interval.end }
    }

    // Category limits are monthly, so a year compares against 12 months of budget
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

    // MARK: - Totals

    private var totalSpent: Decimal {
        periodTransactions.filter { $0.isExpense }.reduce(0) { $0 + $1.amount }
    }

    private var totalIncome: Decimal {
        periodTransactions.filter { !$0.isExpense }.reduce(0) { $0 + $1.amount }
    }

    private var uncategorizedSpent: Decimal {
        periodTransactions
            .filter { $0.isExpense && $0.category == nil }
            .reduce(0) { $0 + $1.amount }
    }

    private func spent(in category: Category) -> Decimal {
        periodTransactions
            .filter { $0.isExpense && $0.category === category }
            .reduce(0) { $0 + $1.amount }
    }

    private var totalLimit: Decimal {
        categories.reduce(Decimal.zero) { $0 + $1.monthlyLimit } * limitMultiplier
    }

    private var totalProgress: Double {
        guard totalLimit > 0 else { return 0 }
        return NSDecimalNumber(decimal: totalSpent / totalLimit).doubleValue
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
                    heroRing
                    summaryCard

                    LazyVGrid(columns: columns, spacing: 24) {
                        ForEach(categories) { category in
                            CategoryRingCell(
                                name: category.name,
                                icon: category.icon,
                                spent: spent(in: category),
                                limit: category.monthlyLimit * limitMultiplier,
                                color: CategoryColor.color(named: category.colorName)
                            )
                        }
                    }
                    .padding(.vertical, 8)

                    if uncategorizedSpent > 0 {
                        HStack {
                            Image(systemName: "questionmark.circle")
                            Text("Uncategorized")
                            Spacer()
                            Text(uncategorizedSpent, format: .currency(code: currencyCode))
                                .bold()
                        }
                        .padding()
                        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 16))
                    }
                }
                .padding()
            }
            .navigationTitle("Dashboard")
            .profileButton()
            .onChange(of: period) { _, _ in
                selectedDate = .now
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

    private var heroRing: some View {
        let remaining = totalLimit - totalSpent
        let isOver = totalLimit > 0 && remaining < 0

        return VStack(spacing: 8) {
            ZStack {
                RingView(progress: totalProgress,
                         color: isOver ? .red : .purple,
                         lineWidth: 22,
                         gradient: isOver ? nil : [.blue, .purple, .pink])

                VStack(spacing: 2) {
                    if totalLimit > 0 {
                        Text(abs(remaining), format: .currency(code: currencyCode).precision(.fractionLength(0)))
                            .font(.title.bold())
                            .foregroundStyle(isOver ? .red : .primary)
                        Text(isOver ? "over budget" : "left")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    } else {
                        Text("No limits set")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .frame(width: 220, height: 220)

            if totalLimit > 0 {
                Text("\(totalSpent, format: .currency(code: currencyCode).precision(.fractionLength(0))) of \(totalLimit, format: .currency(code: currencyCode).precision(.fractionLength(0)))")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 8)
    }

    private var summaryCard: some View {
        HStack {
            SummaryItem(title: "Spent", amount: totalSpent, color: .red)
            Divider().frame(height: 40)
            SummaryItem(title: "Income", amount: totalIncome, color: .green)
            Divider().frame(height: 40)
            SummaryItem(title: "Net", amount: totalIncome - totalSpent,
                        color: totalIncome >= totalSpent ? .green : .red)
        }
        .padding()
        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 16))
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

    private var hasLimit: Bool { limit > 0 }
    private var isOver: Bool { hasLimit && spent > limit }

    // Not clamped: 1.25 means 125% of the limit, and the ring wraps past full
    private var progress: Double {
        guard hasLimit else { return 0 }
        return NSDecimalNumber(decimal: spent / limit).doubleValue
    }

    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                RingView(progress: progress, color: color, lineWidth: 12)
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundStyle(color)
            }
            .frame(width: 84, height: 84)

            Text(name)
                .font(.caption.bold())
                .lineLimit(1)

            Text(spent, format: .currency(code: currencyCode).precision(.fractionLength(0)))
                .font(.caption2)
                .foregroundStyle(isOver ? .red : .secondary)
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
        .modelContainer(for: [BudgetTransaction.self, Category.self], inMemory: true)
}
