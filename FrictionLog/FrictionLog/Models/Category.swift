//
//  Category.swift
//  FrictionLog
//
//  Generated from API contract
//

import Foundation

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
}
