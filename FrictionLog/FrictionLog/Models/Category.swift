//
//  Category.swift
//  FrictionLog
//
//  Generated from API contract
//

import Foundation
import SwiftUI

enum Category: String, Codable, CaseIterable, Identifiable {
    case home
    case work
    case digital
    case health
    case other

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .home: return "Home"
        case .work: return "Work"
        case .digital: return "Digital"
        case .health: return "Health"
        case .other: return "Other"
        }
    }

    var emoji: String {
        switch self {
        case .home: return "🏠"
        case .work: return "💼"
        case .digital: return "💻"
        case .health: return "❤️"
        case .other: return "📦"
        }
    }

    var icon: String {
        switch self {
        case .home: return "house.fill"
        case .work: return "briefcase.fill"
        case .digital: return "laptopcomputer"
        case .health: return "heart.fill"
        case .other: return "cube.fill"
        }
    }

    var color: Color {
        switch self {
        case .home: return .blue
        case .work: return .purple
        case .digital: return .orange
        case .health: return .pink
        case .other: return .gray
        }
    }

    var gradient: LinearGradient {
        switch self {
        case .home:
            return LinearGradient(colors: [.blue.opacity(0.8), .cyan.opacity(0.6)], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .work:
            return LinearGradient(colors: [.purple.opacity(0.8), .indigo.opacity(0.6)], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .digital:
            return LinearGradient(colors: [.orange.opacity(0.8), .yellow.opacity(0.6)], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .health:
            return LinearGradient(colors: [.pink.opacity(0.8), .red.opacity(0.6)], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .other:
            return LinearGradient(colors: [.gray.opacity(0.8), .secondary.opacity(0.6)], startPoint: .topLeading, endPoint: .bottomTrailing)
        }
    }
}
