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

    enum CodingKeys: String, CodingKey {
        case title
        case description
        case annoyanceLevel = "annoyance_level"
        case category
    }
}

struct FrictionItemUpdate: Codable {
    let title: String?
    let description: String?
    let annoyanceLevel: Int?
    let category: Category?
    let status: Status?

    enum CodingKeys: String, CodingKey {
        case title
        case description
        case annoyanceLevel = "annoyance_level"
        case category
        case status
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
    }
}
