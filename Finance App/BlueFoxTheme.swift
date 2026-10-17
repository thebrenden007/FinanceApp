//
//  BlueFoxTheme.swift
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

struct BlueFoxTheme {
    // MARK: - Blue Fox Color Palette

    static let arcticBlue = Color(red: 0.20, green: 0.58, blue: 0.98) // #3394FA
    static let electricCyan = Color(red: 0.15, green: 0.75, blue: 0.96) // #26C0F5
    static let glacialMist = Color(red: 0.92, green: 0.96, blue: 1.0) // #EBF5FF
    static let iceSilver = Color(red: 0.84, green: 0.90, blue: 0.98) // #D6E6FA

    // Dark Mode Arctic Navy & Slate Fox Tones
    static let polarNight = Color(red: 0.04, green: 0.06, blue: 0.12) // #0A101F
    static let slateFox = Color(red: 0.09, green: 0.14, blue: 0.23) // #17243B
    static let auroraGlow = Color(red: 0.10, green: 0.25, blue: 0.44) // #1A4070

    // MARK: - Blue Fox Gradient Background

    static func backgroundGradient(for colorScheme: ColorScheme) -> LinearGradient {
        if colorScheme == .dark {
            return LinearGradient(
                colors: [
                    Color(red: 0.09, green: 0.22, blue: 0.40), // Glowing northern aurora at top
                    Color(red: 0.07, green: 0.12, blue: 0.22), // Midnight slate fox
                    Color(red: 0.04, green: 0.06, blue: 0.12)  // Deep polar night
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        } else {
            return LinearGradient(
                colors: [
                    Color(red: 0.32, green: 0.65, blue: 0.98), // Vibrant arctic sky blue
                    Color(red: 0.62, green: 0.82, blue: 0.99), // Soft glacial mist
                    Color(red: 0.93, green: 0.96, blue: 1.0)   // Pure crisp ice frost
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
                    .fill(Color(red: 0.09, green: 0.13, blue: 0.22).opacity(0.85))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(electricCyan.opacity(0.24), lineWidth: 1)
                    )
            } else {
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white.opacity(0.88))
                    .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 3)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(arcticBlue.opacity(0.30), lineWidth: 1)
                    )
            }
        }
    }
}

// MARK: - View Modifiers

struct BlueFoxBackgroundModifier: ViewModifier {
    @Environment(\.colorScheme) private var colorScheme
    @AppStorage("blueFoxThemeEnabled") private var blueFoxThemeEnabled = true

    func body(content: Content) -> some View {
        ZStack {
            if blueFoxThemeEnabled {
                BlueFoxTheme.backgroundGradient(for: colorScheme)
                    .ignoresSafeArea()
            }
            content
        }
    }
}

struct BlueFoxCardModifier: ViewModifier {
    @Environment(\.colorScheme) private var colorScheme
    @AppStorage("blueFoxThemeEnabled") private var blueFoxThemeEnabled = true
    var cornerRadius: CGFloat = 16

    func body(content: Content) -> some View {
        if blueFoxThemeEnabled {
            content
                .background(
                    BlueFoxTheme.cardFill(for: colorScheme)
                )
        } else {
            content
                .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: cornerRadius))
        }
    }
}

struct BlueFoxRowBackground: View {
    @Environment(\.colorScheme) private var colorScheme
    @AppStorage("blueFoxThemeEnabled") private var blueFoxThemeEnabled = true

    var body: some View {
        if blueFoxThemeEnabled {
            if colorScheme == .dark {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(red: 0.09, green: 0.13, blue: 0.22).opacity(0.85))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(BlueFoxTheme.electricCyan.opacity(0.22), lineWidth: 1)
                    )
                    .padding(.vertical, 2)
            } else {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white.opacity(0.88))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(BlueFoxTheme.arcticBlue.opacity(0.25), lineWidth: 1)
                    )
                    .padding(.vertical, 2)
            }
        } else {
            Color(.secondarySystemGroupedBackground)
        }
    }
}

extension View {
    func blueFoxBackground() -> some View {
        self.modifier(BlueFoxBackgroundModifier())
    }

    func blueFoxCard(cornerRadius: CGFloat = 16) -> some View {
        self.modifier(BlueFoxCardModifier(cornerRadius: cornerRadius))
    }

    func blueFoxRowStyle() -> some View {
        self.listRowBackground(BlueFoxRowBackground())
    }
}
