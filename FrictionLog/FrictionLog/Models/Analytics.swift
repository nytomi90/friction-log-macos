//
//  Analytics.swift
//  FrictionLog
//
//  Generated from API contract
//

import Foundation

struct CurrentScore: Codable {
    let currentScore: Int
    let activeCount: Int

    enum CodingKeys: String, CodingKey {
        case currentScore = "current_score"
        case activeCount = "active_count"
    }
}

struct TrendDataPoint: Codable, Identifiable {
    let date: String  // ISO 8601 date string
    let score: Int

    var id: String { date }

    var dateValue: Date? {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withFullDate]
        return formatter.date(from: date)
    }
}

struct CategoryBreakdown: Codable {
    let home: Int
    let work: Int
    let digital: Int
    let health: Int
    let other: Int

    var total: Int {
        home + work + digital + health + other
    }

    func score(for category: Category) -> Int {
        switch category {
        case .home: return home
        case .work: return work
        case .digital: return digital
        case .health: return health
        case .other: return other
        }
    }
}
