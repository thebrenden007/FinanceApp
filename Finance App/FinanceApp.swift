//
//  FinanceApp.swift
//  FinanceApp
//
//  Created by Brenden Smit on 10/13/26.
//

import SwiftUI
import SwiftData

@main
struct FinanceApp: App {
    @AppStorage("appAppearance") private var appAppearance = AppAppearance.system.rawValue
    @AppStorage("beeThemeEnabled") private var beeThemeEnabled = true

    private var currentColorScheme: ColorScheme? {
        (AppAppearance(rawValue: appAppearance) ?? .system).colorScheme
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(currentColorScheme)
                .tint(beeThemeEnabled ? BeeTheme.amberGold : Color.accentColor)
                .modelContainer(for: [BudgetTransaction.self, Category.self, Goal.self])
        }
    }
}
