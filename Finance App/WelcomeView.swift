//
//  WelcomeView.swift
//  FinanceApp
//
//  Created by Brenden Smit on 10/16/26.
//

import SwiftUI

struct WelcomeView: View {
    @AppStorage("userName") private var userName = ""
    @AppStorage("avatarIcon") private var avatarIcon = "bluefox.logo"
    @AppStorage("avatarColor") private var avatarColor = "blue"
    @AppStorage("currencyCode") private var currencyCode = "USD"

    @State private var step = 0
    @State private var typedName = ""
    @State private var greetingIndex = 0
    @FocusState private var nameFocused: Bool

    private let lastStep = 3

    private let greetings = [
        "hello", "hola", "bonjour", "hallo", "ciao", "olá",
        "こんにちは", "안녕하세요", "你好", "नमस्ते", "مرحبا", "привет"
    ]

    private let avatarIcons = [
        "bluefox.logo", "pawprint.fill", "person.fill", "face.smiling", "star.fill",
        "heart.fill", "leaf.fill", "flame.fill", "bolt.fill", "moon.fill"
    ]

    private var trimmedName: String {
        typedName.trimmingCharacters(in: .whitespaces)
    }

    private var canContinue: Bool {
        step == 1 ? !trimmedName.isEmpty : true
    }

    var body: some View {
        VStack(spacing: 0) {
            // Page dots
            HStack(spacing: 8) {
                ForEach(0...lastStep, id: \.self) { index in
                    Circle()
                        .fill(index == step ? Color.accentColor : Color.secondary.opacity(0.3))
                        .frame(width: 8, height: 8)
                }
            }
            .padding(.top, 16)

            Group {
                switch step {
                case 0: helloStep
                case 1: nameStep
                case 2: avatarStep
                default: currencyStep
                }
            }
            .id(step)
            .transition(.asymmetric(
                insertion: .move(edge: .trailing).combined(with: .opacity),
                removal: .move(edge: .leading).combined(with: .opacity)
            ))
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            // Bottom buttons
            VStack(spacing: 12) {
                Button {
                    advance()
                } label: {
                    Text(step == 0 ? "Continue" : (step == lastStep ? "Get Started" : "Next"))
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .disabled(!canContinue)

                if step > 0 {
                    Button("Back") { goBack() }
                        .foregroundStyle(.secondary)
                } else {
                    // Keeps the layout from jumping between steps
                    Text(" ").font(.body)
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 24)
        }
        .blueFoxBackground()
    }

    // MARK: - Steps

    private var helloStep: some View {
        VStack {
            Spacer()

            Image("DeveloperLogo")
                .resizable()
                .scaledToFit()
                .frame(width: 90, height: 90)
                .padding(.bottom, 8)

            ZStack {
                Text(greetings[greetingIndex])
                    .id(greetingIndex)
                    .transition(.opacity)
            }
            .font(.system(size: 64, weight: .bold, design: .rounded))
            .foregroundStyle(
                LinearGradient(colors: [BlueFoxTheme.arcticBlue, BlueFoxTheme.electricCyan],
                               startPoint: .leading, endPoint: .trailing)
            )
            .frame(height: 90)
            .minimumScaleFactor(0.5)
            .lineLimit(1)
            .padding(.horizontal)

            Text("Let's set up your budget.")
                .font(.title3)
                .foregroundStyle(.secondary)
                .padding(.top, 8)
            Spacer()
        }
        .task {
            // Cycles the greeting until this step leaves the screen
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(2))
                if Task.isCancelled { break }
                withAnimation(.easeInOut(duration: 0.6)) {
                    greetingIndex = (greetingIndex + 1) % greetings.count
                }
            }
        }
    }

    private var nameStep: some View {
        VStack(spacing: 24) {
            Spacer()
            Text("What's your name?")
                .font(.largeTitle.bold())
            Text("We'll use it to greet you on your dashboard.")
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            TextField("Your name", text: $typedName)
                .font(.title2)
                .multilineTextAlignment(.center)
                .textFieldStyle(.roundedBorder)
                .focused($nameFocused)
                .submitLabel(.next)
                .onSubmit { if canContinue { advance() } }
                .padding(.horizontal, 32)
            Spacer()
            Spacer()
        }
        .padding(.horizontal)
        .onAppear { nameFocused = true }
    }

    private var avatarStep: some View {
        ScrollView {
            VStack(spacing: 24) {
                Text("Pick your look")
                    .font(.largeTitle.bold())
                    .padding(.top, 24)

                ZStack {
                    Circle().fill(CategoryColor.color(named: avatarColor))
                    if avatarIcon == "bluefox.logo" {
                        Image("DeveloperLogo")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 60, height: 60)
                    } else {
                        Image(systemName: avatarIcon)
                            .font(.system(size: 44))
                            .foregroundStyle(.white)
                    }
                }
                .frame(width: 100, height: 100)

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
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 16)
        }
    }

    private var currencyStep: some View {
        VStack(spacing: 24) {
            Spacer()
            Text("Your currency")
                .font(.largeTitle.bold())

            Text(1234.5, format: .currency(code: currencyCode))
                .font(.system(size: 40, weight: .semibold, design: .rounded))

            Picker("Currency", selection: $currencyCode) {
                ForEach(Locale.commonISOCurrencyCodes, id: \.self) { code in
                    Text("\(code) – \(Locale.current.localizedString(forCurrencyCode: code) ?? code)")
                        .tag(code)
                }
            }
            .pickerStyle(.menu)

            Text("You can change this anytime in your profile.")
                .font(.footnote)
                .foregroundStyle(.secondary)
            Spacer()
            Spacer()
        }
        .padding(.horizontal)
    }

    // MARK: - Navigation

    private func advance() {
        if step == lastStep {
            // Saving the name last makes ContentView switch to the tabs
            userName = trimmedName
        } else {
            nameFocused = false
            withAnimation(.easeInOut(duration: 0.35)) { step += 1 }
        }
    }

    private func goBack() {
        nameFocused = false
        withAnimation(.easeInOut(duration: 0.35)) { step -= 1 }
    }
}

#Preview {
    WelcomeView()
}
