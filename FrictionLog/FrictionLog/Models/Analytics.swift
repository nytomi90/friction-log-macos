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
    let itemsOverLimit: Int
    let totalEncountersToday: Int
    let weightedEncountersToday: Int
    let globalDailyLimit: Int?
    let globalLimitPercentage: Int?

    enum CodingKeys: String, CodingKey {
        case currentScore = "current_score"
        case activeCount = "active_count"
        case itemsOverLimit = "items_over_limit"
        case totalEncountersToday = "total_encounters_today"
        case weightedEncountersToday = "weighted_encounters_today"
        case globalDailyLimit = "global_daily_limit"
        case globalLimitPercentage = "global_limit_percentage"
    }

    /// Returns emoji indicator based on global limit percentage
    /// 😊 under 50%, 😐 50-75%, 😰 75-100%, 🔴 over 100%
    var statusEmoji: String {
        guard let percentage = globalLimitPercentage else {
            return "😊" // No limit set, default to happy
        }

        if percentage < 50 {
            return "😊"
        } else if percentage < 75 {
            return "😐"
        } else if percentage < 100 {
            return "😰"
        } else {
            return "🔴"
        }
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

struct MostAnnoyingItem: Codable, Identifiable {
    let id: Int
    let title: String
    let annoyanceLevel: Int
    let encounterCount: Int
    let impact: Int
    let category: String

    enum CodingKeys: String, CodingKey {
        case id
        case title
        case annoyanceLevel = "annoyance_level"
        case encounterCount = "encounter_count"
        case impact
        case category
    }

    var categoryEnum: Category? {
        Category(rawValue: category)
    }
}
