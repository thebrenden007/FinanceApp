//
//  BeeTheme.swift
//  FinanceApp
//
//  Created by Brenden Smit on 10/17/26.
//

import SwiftUI

enum AppAppearance: String, CaseIterable, Identifiable {
    case system = "System"
    case light = "Light"
    case dark = "Dark"

    var id: String { rawValue }

    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }

    var icon: String {
        switch self {
        case .system: return "circle.lefthalf.filled"
        case .light: return "sun.max.fill"
        case .dark: return "moon.fill"
        }
    }
}

struct BeeTheme {
    // MARK: - Honey & Bee Color Palette

    static let honeyGold = Color(red: 1.0, green: 0.76, blue: 0.03) // #FFC207
    static let amberGold = Color(red: 0.96, green: 0.62, blue: 0.0) // #F59E00
    static let pollenYellow = Color(red: 1.0, green: 0.88, blue: 0.35) // #FFE059
    static let butterCream = Color(red: 0.99, green: 0.96, blue: 0.84) // #FDF5D6

    // Dark Mode Bee Tones
    static let beeOnyx = Color(red: 0.08, green: 0.08, blue: 0.08) // Midnight Bee Black
    static let beeDarkCharcoal = Color(red: 0.15, green: 0.13, blue: 0.09) // Deep Honey Charcoal
    static let beeDarkGlow = Color(red: 0.30, green: 0.22, blue: 0.04) // Dark Honey Glow

    // MARK: - Bee Gradient Background

    static func backgroundGradient(for colorScheme: ColorScheme) -> LinearGradient {
        if colorScheme == .dark {
            return LinearGradient(
                colors: [
                    Color(red: 0.28, green: 0.21, blue: 0.04), // Warm glowing honey amber at top
                    Color(red: 0.12, green: 0.11, blue: 0.08), // Dark honeycomb charcoal
                    Color(red: 0.06, green: 0.06, blue: 0.07)  // Pure deep bee onyx
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        } else {
            return LinearGradient(
                colors: [
                    Color(red: 1.0, green: 0.80, blue: 0.18), // Vibrant warm bumblebee yellow
                    Color(red: 1.0, green: 0.89, blue: 0.44), // Sweet honey gold
                    Color(red: 0.99, green: 0.96, blue: 0.84)  // Soft warm honeycomb cream
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        }
    }

    // MARK: - Card Surface Background

    static func cardFill(for colorScheme: ColorScheme) -> some View {
        Group {
            if colorScheme == .dark {
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(red: 0.14, green: 0.13, blue: 0.10).opacity(0.85))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(honeyGold.opacity(0.22), lineWidth: 1)
                    )
            } else {
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white.opacity(0.86))
                    .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 3)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color(red: 0.95, green: 0.75, blue: 0.20).opacity(0.35), lineWidth: 1)
                    )
            }
        }
    }
}

// MARK: - View Modifiers

struct BeeBackgroundModifier: ViewModifier {
    @Environment(\.colorScheme) private var colorScheme
    @AppStorage("beeThemeEnabled") private var beeThemeEnabled = true

    func body(content: Content) -> some View {
        ZStack {
            if beeThemeEnabled {
                BeeTheme.backgroundGradient(for: colorScheme)
                    .ignoresSafeArea()
            }
            content
        }
    }
}

struct BeeCardModifier: ViewModifier {
    @Environment(\.colorScheme) private var colorScheme
    @AppStorage("beeThemeEnabled") private var beeThemeEnabled = true
    var cornerRadius: CGFloat = 16

    func body(content: Content) -> some View {
        if beeThemeEnabled {
            content
                .background(
                    BeeTheme.cardFill(for: colorScheme)
                )
        } else {
            content
                .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: cornerRadius))
        }
    }
}

struct BeeRowBackground: View {
    @Environment(\.colorScheme) private var colorScheme
    @AppStorage("beeThemeEnabled") private var beeThemeEnabled = true

    var body: some View {
        if beeThemeEnabled {
            if colorScheme == .dark {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(red: 0.14, green: 0.13, blue: 0.10).opacity(0.85))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(BeeTheme.honeyGold.opacity(0.20), lineWidth: 1)
                    )
                    .padding(.vertical, 2)
            } else {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white.opacity(0.88))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(BeeTheme.amberGold.opacity(0.25), lineWidth: 1)
                    )
                    .padding(.vertical, 2)
            }
        } else {
            Color(.secondarySystemGroupedBackground)
        }
    }
}

extension View {
    func beeBackground() -> some View {
        self.modifier(BeeBackgroundModifier())
    }

    func beeCard(cornerRadius: CGFloat = 16) -> some View {
        self.modifier(BeeCardModifier(cornerRadius: cornerRadius))
    }

    func beeRowStyle() -> some View {
        self.listRowBackground(BeeRowBackground())
    }
}
