//
//  Status.swift
//  FrictionLog
//
//  Generated from API contract
//

import Foundation

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
}
