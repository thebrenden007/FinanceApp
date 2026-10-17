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
    @AppStorage("avatarIcon") private var avatarIcon = "bluefox.logo"
    @AppStorage("avatarColor") private var avatarColor = "blue"
    @AppStorage("monthlyIncome") private var monthlyIncome: Double = 0
    @AppStorage("startingSavings") private var startingSavings: Double = 0
    @AppStorage("appAppearance") private var appAppearance = AppAppearance.system.rawValue
    @AppStorage("blueFoxThemeEnabled") private var blueFoxThemeEnabled = true
    @Environment(\.dismiss) private var dismiss

    @Query private var goals: [Goal]

    private let avatarIcons = [
        "bluefox.logo", "pawprint.fill", "person.fill", "face.smiling", "star.fill",
        "heart.fill", "leaf.fill", "flame.fill", "bolt.fill", "moon.fill"
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

                    Toggle(isOn: $blueFoxThemeEnabled) {
                        HStack(spacing: 12) {
                            ZStack {
                                Circle()
                                    .fill(
                                        LinearGradient(
                                            colors: [BlueFoxTheme.arcticBlue, BlueFoxTheme.electricCyan],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .frame(width: 30, height: 30)
                                Image("DeveloperLogo")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 20, height: 20)
                            }

                            VStack(alignment: .leading, spacing: 2) {
                                Text("Blue Fox Theme")
                                    .font(.body)
                                Text("Arctic blue & slate fox styling")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                } header: {
                    Text("Theme & Styling")
                } footer: {
                    Text("Choose between Light, Dark, or System mode. The Blue Fox Theme adds a cool arctic gradient background.")
                }

                Section("You") {
                    TextField("Your name", text: $userName)
                }

                Section {
                    TextField("External Savings Balance", value: $startingSavings, format: .currency(code: currencyCode))
                        .keyboardType(.decimalPad)

                    HStack {
                        Text("Active Goals Balance")
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text(goalsSavingsTotal, format: .currency(code: currencyCode))
                            .foregroundStyle(.secondary)
                    }

                    HStack {
                        Text("Combined Net Savings")
                            .bold()
                        Spacer()
                        Text(combinedTotalSavings, format: .currency(code: currencyCode))
                            .bold()
                            .foregroundStyle(Color.accentColor)
                    }
                } header: {
                    Text("Savings & Net Worth")
                } footer: {
                    Text("Enter any starting or external savings you have in checking/savings accounts. This combines with your app goals for a total savings overview.")
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
                        if avatarIcon == "bluefox.logo" {
                            Image("DeveloperLogo")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 50, height: 50)
                        } else {
                            Image(systemName: avatarIcon)
                                .font(.system(size: 36))
                                .foregroundStyle(.white)
                        }
                    }
                    .frame(width: 80, height: 80)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)

                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 5), spacing: 16) {
                        ForEach(avatarIcons, id: \.self) { symbol in
                            Group {
                                if symbol == "bluefox.logo" {
                                    Image("DeveloperLogo")
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 26, height: 26)
                                } else {
                                    Image(systemName: symbol)
                                        .font(.title2)
                                }
                            }
                            .frame(width: 44, height: 44)
                            .background(avatarIcon == symbol ? Color.accentColor.opacity(0.25) : Color.clear)
                            .clipShape(Circle())
                            .contentShape(Rectangle())
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

                Section {
                    HStack(spacing: 16) {
                        Image("DeveloperLogo")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 48, height: 48)
                            .padding(6)
                            .background(
                                Circle()
                                    .fill(
                                        LinearGradient(
                                            colors: [BlueFoxTheme.arcticBlue.opacity(0.22), BlueFoxTheme.electricCyan.opacity(0.12)],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                            )

                        VStack(alignment: .leading, spacing: 3) {
                            Text("Blue Fox Finance")
                                .font(.headline)
                            Text("Designed & Developed by Brenden")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            Text("Version 1.0 • Developer Edition")
                                .font(.caption2)
                                .foregroundStyle(.tertiary)
                        }
                    }
                    .padding(.vertical, 4)
                } header: {
                    Text("About & Developer")
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
