//
//  GoalDetailView.swift
//  FinanceApp
//
//  Created by Brenden Smit on 10/16/26.
//

import SwiftUI
import SwiftData

struct GoalDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @Bindable var goal: Goal
    let netCashFlow: Decimal

    @AppStorage("currencyCode") private var currencyCode = "USD"
    @State private var showingEdit = false
    @State private var showingContribute = false
    @State private var showingDeleteAlert = false

    private var progressPercent: Int {
        Int((goal.progress * 100).rounded())
    }

    private var milestones: [(percent: Int, title: String, reached: Bool)] {
        [
            (25, "Getting Started", goal.progress >= 0.25),
            (50, "Halfway There!", goal.progress >= 0.50),
            (75, "The Home Stretch", goal.progress >= 0.75),
            (100, "Goal Achieved! 🎉", goal.progress >= 1.0)
        ]
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // MARK: - Hero Header
                VStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(CategoryColor.color(named: goal.colorName).opacity(0.18))
                            .frame(width: 90, height: 90)
                        Image(systemName: goal.icon)
                            .font(.system(size: 40))
                            .foregroundStyle(CategoryColor.color(named: goal.colorName))
                    }

                    Text(goal.name)
                        .font(.title2.bold())

                    Text("\(goal.savedAmount, format: .currency(code: currencyCode)) of \(goal.targetAmount, format: .currency(code: currencyCode))")
                        .font(.headline)
                        .foregroundStyle(.secondary)

                    // Big Circular or Bar Progress
                    VStack(spacing: 8) {
                        ProgressView(value: goal.progress)
                            .tint(CategoryColor.color(named: goal.colorName))
                            .scaleEffect(x: 1, y: 2, anchor: .center)
                            .padding(.horizontal)

                        HStack {
                            Text("\(progressPercent)% complete")
                                .font(.caption.bold())
                                .foregroundStyle(CategoryColor.color(named: goal.colorName))
                            Spacer()
                            Text("\(goal.remainingAmount, format: .currency(code: currencyCode)) remaining")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.horizontal)
                    }
                }
                .padding()
                .blueFoxCard(cornerRadius: 20)

                // MARK: - Action Buttons
                HStack(spacing: 16) {
                    Button {
                        showingContribute = true
                    } label: {
                        Label("Add Money", systemImage: "plus.circle.fill")
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 4)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(CategoryColor.color(named: goal.colorName))

                    Button {
                        showingEdit = true
                    } label: {
                        Label("Edit", systemImage: "pencil")
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 4)
                    }
                    .buttonStyle(.bordered)
                }

                // MARK: - Milestones Card
                VStack(alignment: .leading, spacing: 14) {
                    Label("Milestones", systemImage: "trophy.fill")
                        .font(.headline)

                    ForEach(milestones, id: \.percent) { milestone in
                        HStack(spacing: 12) {
                            ZStack {
                                Circle()
                                    .fill(milestone.reached ? CategoryColor.color(named: goal.colorName) : Color(.tertiarySystemFill))
                                    .frame(width: 32, height: 32)
                                if milestone.reached {
                                    Image(systemName: "checkmark")
                                        .font(.caption.bold())
                                        .foregroundStyle(.white)
                                } else {
                                    Text("\(milestone.percent)%")
                                        .font(.caption2.bold())
                                        .foregroundStyle(.secondary)
                                }
                            }

                            VStack(alignment: .leading, spacing: 2) {
                                Text(milestone.title)
                                    .font(.subheadline.bold())
                                    .foregroundStyle(milestone.reached ? .primary : .secondary)
                                Text("\(milestone.percent)% of target (\((goal.targetAmount * Decimal(milestone.percent) / 100), format: .currency(code: currencyCode).precision(.fractionLength(0))))")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }

                            Spacer()

                            if milestone.reached {
                                Text("Achieved")
                                    .font(.caption2.bold())
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 3)
                                    .background(Color.green.opacity(0.18))
                                    .foregroundStyle(.green)
                                    .clipShape(Capsule())
                            }
                        }
                    }
                }
                .padding()
                .blueFoxCard(cornerRadius: 16)

                // MARK: - Timeline & Pace Card
                VStack(alignment: .leading, spacing: 12) {
                    Label("Timeline & Pace", systemImage: "calendar")
                        .font(.headline)

                    if let targetDate = goal.targetDate, let months = goal.monthsRemaining {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Target Date")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Text(targetDate, style: .date)
                                    .font(.subheadline.bold())
                            }
                            Spacer()
                            VStack(alignment: .trailing, spacing: 2) {
                                Text("Months Left")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Text("\(months) month\(months == 1 ? "" : "s")")
                                    .font(.subheadline.bold())
                            }
                        }

                        if let required = goal.requiredMonthlyContribution {
                            Divider()
                            HStack {
                                Text("Required Pace")
                                    .font(.subheadline)
                                Spacer()
                                Text("\(required, format: .currency(code: currencyCode).precision(.fractionLength(0))) / month")
                                    .font(.subheadline.bold())
                                    .foregroundStyle(.blue)
                            }
                        }
                    } else if let projected = goal.projectedCompletionDate {
                        HStack {
                            Text("Projected Completion")
                                .font(.subheadline)
                            Spacer()
                            Text(projected.formatted(.dateTime.month().year()))
                                .font(.subheadline.bold())
                                .foregroundStyle(.blue)
                        }
                    }

                    if goal.monthlyContribution > 0 {
                        Divider()
                        HStack {
                            Text("Planned Monthly Contribution")
                                .font(.subheadline)
                            Spacer()
                            Text("\(goal.monthlyContribution, format: .currency(code: currencyCode).precision(.fractionLength(0))) / month")
                                .font(.subheadline.bold())
                        }
                    }
                }
                .padding()
                .blueFoxCard(cornerRadius: 16)

                // MARK: - Danger Zone
                Button(role: .destructive) {
                    showingDeleteAlert = true
                } label: {
                    Label("Delete Goal", systemImage: "trash")
                        .font(.subheadline)
                }
                .padding(.top, 8)
            }
            .padding()
        }
        .blueFoxBackground()
        .navigationTitle("Goal Details")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("Edit") { showingEdit = true }
            }
        }
        .sheet(isPresented: $showingEdit) {
            GoalFormView(goalToEdit: goal)
        }
        .sheet(isPresented: $showingContribute) {
            GoalContributeSheet(goal: goal, netCashFlow: netCashFlow)
        }
        .alert("Delete Goal?", isPresented: $showingDeleteAlert) {
            Button("Delete", role: .destructive) {
                modelContext.delete(goal)
                dismiss()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Are you sure you want to delete '\(goal.name)'? This action cannot be undone.")
        }
    }
}
