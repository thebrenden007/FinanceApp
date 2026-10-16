//
//  CategoryColor.swift
//  FinanceApp
//
//  Created by Brenden Smit on 10/14/26.
//

import SwiftUI

enum CategoryColor {
    static let options: [(name: String, color: Color)] = [
        // Reds and pinks
        ("red", .red),
        ("crimson", Color(red: 0.86, green: 0.08, blue: 0.24)),
        ("coral", Color(red: 1.00, green: 0.45, blue: 0.40)),
        ("pink", .pink),
        ("hotpink", Color(red: 1.00, green: 0.30, blue: 0.65)),

        // Oranges and yellows
        ("orange", .orange),
        ("amber", Color(red: 1.00, green: 0.75, blue: 0.00)),
        ("yellow", .yellow),

        // Greens
        ("lime", Color(red: 0.65, green: 0.85, blue: 0.20)),
        ("green", .green),
        ("mint", .mint),
        ("forest", Color(red: 0.10, green: 0.50, blue: 0.30)),

        // Blues and teals
        ("teal", .teal),
        ("cyan", .cyan),
        ("sky", Color(red: 0.35, green: 0.70, blue: 1.00)),
        ("blue", .blue),

        // Purples and neutrals
        ("indigo", .indigo),
        ("purple", .purple),
        ("brown", .brown),
        ("slate", Color(red: 0.40, green: 0.45, blue: 0.55))
    ]

    static func color(named name: String) -> Color {
        options.first { $0.name == name }?.color ?? .blue
    }
}
