//
//  ProfileView.swift
//  FinanceApp
//
//  Created by Brenden Smit on 10/15/26.
//

import SwiftUI
import SwiftData

struct ProfileView: View {
    @AppStorage("userName") private var userName = ""
    @AppStorage("currencyCode") private var currencyCode = "USD"
    @AppStorage("avatarIcon") private var avatarIcon = "person.fill"
    @AppStorage("avatarColor") private var avatarColor = "amber"
    @AppStorage("monthlyIncome") private var monthlyIncome: Double = 0
    @AppStorage("startingSavings") private var startingSavings: Double = 0
    @AppStorage("appAppearance") private var appAppearance = AppAppearance.system.rawValue
    @AppStorage("beeThemeEnabled") private var beeThemeEnabled = true
    @Environment(\.dismiss) private var dismiss

    @Query private var goals: [Goal]

    private let avatarIcons = [
        "person.fill", "face.smiling", "star.fill", "heart.fill", "leaf.fill",
        "flame.fill", "bolt.fill", "pawprint.fill", "moon.fill", "sun.max.fill"
    ]

    private var goalsSavingsTotal: Decimal {
        goals.reduce(Decimal.zero) { $0 + $1.savedAmount }
    }

    private var combinedTotalSavings: Decimal {
        Decimal(startingSavings) + goalsSavingsTotal
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Picker("Theme Mode", selection: $appAppearance) {
                        ForEach(AppAppearance.allCases) { appearance in
                            Label(appearance.rawValue, systemImage: appearance.icon)
                                .tag(appearance.rawValue)
                        }
                    }
                    .pickerStyle(.segmented)

                    Toggle(isOn: $beeThemeEnabled) {
                        HStack(spacing: 12) {
                            ZStack {
                                Circle()
                                    .fill(
                                        LinearGradient(
                                            colors: [BeeTheme.honeyGold, BeeTheme.amberGold],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .frame(width: 30, height: 30)
                                Text("🐝")
                                    .font(.caption)
                            }

                            VStack(alignment: .leading, spacing: 2) {
                                Text("Bee Yellow Gradient")
                                    .font(.body)
                                Text("Bumblebee gold & charcoal styling")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                } header: {
                    Text("Theme & Styling")
                } footer: {
                    Text("Choose between Light, Dark, or System mode. The Bee Theme adds a warm honey-gold gradient background.")
                }

                Section("You") {
                    TextField("Your name", text: $userName)
                }

                Section {
                    TextField("Baseline Savings (Emergency fund, bank, etc.)", value: $startingSavings, format: .currency(code: currencyCode))
                        .keyboardType(.decimalPad)

                    HStack {
                        Text("Combined Total Savings")
                            .font(.subheadline)
                        Spacer()
                        Text(combinedTotalSavings, format: .currency(code: currencyCode))
                            .font(.subheadline.bold())
                            .foregroundStyle(.green)
                    }
                } header: {
                    Text("Total Savings & Net Worth")
                } footer: {
                    Text("Baseline savings includes external bank accounts or rainy day funds. Goals savings (\(goalsSavingsTotal, format: .currency(code: currencyCode).precision(.fractionLength(0)))) are added automatically.")
                }

                Section {
                    TextField("Expected Monthly Income", value: $monthlyIncome, format: .currency(code: currencyCode))
                        .keyboardType(.decimalPad)
                } header: {
                    Text("Baseline Income")
                } footer: {
                    Text("Used for zero-based budget planning and cash flow targets on your dashboard.")
                }

                Section("Avatar") {
                    ZStack {
                        Circle()
                            .fill(CategoryColor.color(named: avatarColor))
                        Image(systemName: avatarIcon)
                            .font(.system(size: 36))
                            .foregroundStyle(.white)
                    }
                    .frame(width: 80, height: 80)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)

                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 5), spacing: 16) {
                        ForEach(avatarIcons, id: \.self) { symbol in
                            Image(systemName: symbol)
                                .font(.title2)
                                .frame(width: 44, height: 44)
                                .background(avatarIcon == symbol ? Color.accentColor.opacity(0.25) : Color.clear)
                                .clipShape(Circle())
                                .onTapGesture { avatarIcon = symbol }
                        }
                    }
                    .padding(.vertical, 8)

                    // Color grid
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 5), spacing: 16) {
                        ForEach(CategoryColor.options, id: \.name) { option in
                            Circle()
                                .fill(option.color)
                                .frame(width: 36, height: 36)
                                .overlay(
                                    Circle()
                                        .stroke(Color.primary, lineWidth: avatarColor == option.name ? 3 : 0)
                                        .padding(-4)
                                )
                                .onTapGesture { avatarColor = option.name }
                        }
                    }
                    .padding(.vertical, 8)
                }

                Section {
                    Picker("Currency", selection: $currencyCode) {
                        ForEach(Locale.commonISOCurrencyCodes, id: \.self) { code in
                            Text("\(code) – \(Locale.current.localizedString(forCurrencyCode: code) ?? code)")
                                .tag(code)
                        }
                    }
                    .pickerStyle(.navigationLink)
                } header: {
                    Text("Currency")
                } footer: {
                    Text("Changing currency only changes the symbol. Existing amounts are not converted.")
                }
            }
            .navigationTitle("Profile")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

#Preview {
    ProfileView()
        .modelContainer(for: [Goal.self], inMemory: true)
}
