//
//  Status.swift
//  FrictionLog
//
//  Generated from API contract
//

import Foundation
import SwiftUI

enum Status: String, Codable, CaseIterable {
    case notFixed = "not_fixed"
    case inProgress = "in_progress"
    case fixed

    var displayName: String {
        switch self {
        case .notFixed: return "Not Fixed"
        case .inProgress: return "In Progress"
        case .fixed: return "Fixed"
        }
    }

    var emoji: String {
        switch self {
        case .notFixed: return "🔴"
        case .inProgress: return "🟡"
        case .fixed: return "✅"
        }
    }

    var icon: String {
        switch self {
        case .notFixed: return "exclamationmark.circle.fill"
        case .inProgress: return "hourglass"
        case .fixed: return "checkmark.circle.fill"
        }
    }

    var color: Color {
        switch self {
        case .notFixed: return .red
        case .inProgress: return .orange
        case .fixed: return .green
        }
    }
}
