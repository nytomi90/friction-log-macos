//
//  FrictionItem.swift
//  FrictionLog
//
//  Generated from API contract
//

import Foundation

// MARK: - Request/Response Models

struct FrictionItemCreate: Codable {
    let title: String
    let description: String?
    let annoyanceLevel: Int
    let category: Category
    let encounterLimit: Int?

    enum CodingKeys: String, CodingKey {
        case title
        case description
        case annoyanceLevel = "annoyance_level"
        case category
        case encounterLimit = "encounter_limit"
    }
}

struct FrictionItemUpdate: Codable {
    let title: String?
    let description: String?
    let annoyanceLevel: Int?
    let category: Category?
    let status: Status?
    let encounterLimit: Int?

    enum CodingKeys: String, CodingKey {
        case title
        case description
        case annoyanceLevel = "annoyance_level"
        case category
        case status
        case encounterLimit = "encounter_limit"
    }
}

struct FrictionItemResponse: Codable, Identifiable {
    let id: Int
    let title: String
    let description: String?
    let annoyanceLevel: Int
    let category: Category
    let status: Status
    let createdAt: Date
    let updatedAt: Date
    let fixedAt: Date?
    let encounterCount: Int
    let encounterLimit: Int?
    let lastEncounterDate: String?
    let isLimitExceeded: Bool

    enum CodingKeys: String, CodingKey {
        case id
        case title
        case description
        case annoyanceLevel = "annoyance_level"
        case category
        case status
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case fixedAt = "fixed_at"
        case encounterCount = "encounter_count"
        case encounterLimit = "encounter_limit"
        case lastEncounterDate = "last_encounter_date"
        case isLimitExceeded = "is_limit_exceeded"
    }
}
