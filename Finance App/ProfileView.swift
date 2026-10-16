//
//  ProfileView.swift
//  FinanceApp
//
//  Created by Brenden Smit on 10/15/26.
//

import SwiftUI

struct ProfileView: View {
    @AppStorage("userName") private var userName = ""
    @AppStorage("currencyCode") private var currencyCode = "USD"
    @AppStorage("avatarIcon") private var avatarIcon = "person.fill"
    @AppStorage("avatarColor") private var avatarColor = "blue"
    @Environment(\.dismiss) private var dismiss
    
    private let avatarIcons = [
        "person.fill", "face.smiling", "star.fill", "heart.fill", "leaf.fill", "flame.fill", "bolt.fill", "pawprint.fill", "moon.fill", "sun.max.fill"
    ]
    
    var body: some View {
        NavigationStack{
            Form{
                Section("You"){
                    TextField("Your name", text: $userName)
                }
                Section("Avatar"){
                    ZStack{
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
}
