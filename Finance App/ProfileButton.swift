//
//  ProfileButton.swift
//  FinanceApp
//
//  Created by Brenden Smit on 10/15/26.
//

import SwiftUI

struct ProfileButtonModifier: ViewModifier {
    @AppStorage("avatarIcon") private var avatarIcon = "person.fill"
    @AppStorage("avatarColor") private var avatarColor = "blue"
    @State private var showingProfile = false

    func body(content: Content) -> some View {
        content
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingProfile = true
                    } label: {
                        ZStack {
                            Circle()
                                .fill(CategoryColor.color(named: avatarColor))
                            Image(systemName: avatarIcon)
                                .font(.system(size: 14))
                                .foregroundStyle(.white)
                        }
                        .frame(width: 30, height: 30)
                    }
                }
            }
            .sheet(isPresented: $showingProfile) {
                ProfileView()
            }
    }
}

extension View {
    func profileButton() -> some View {
        modifier(ProfileButtonModifier())
    }
}
