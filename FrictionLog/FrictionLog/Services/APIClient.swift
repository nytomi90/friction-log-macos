//
//  APIClient.swift
//  FrictionLog
//
//  HTTP client for Friction Log backend API
//

import Foundation

enum APIError: Error, LocalizedError {
    case invalidURL
    case invalidResponse
    case httpError(statusCode: Int, message: String?)
    case decodingError(Error)
    case networkError(Error)

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .invalidResponse:
            return "Invalid response from server"
        case .httpError(let statusCode, let message):
            return "HTTP Error \(statusCode): \(message ?? "Unknown error")"
        case .decodingError(let error):
            return "Failed to decode response: \(error.localizedDescription)"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        }
    }
}

class APIClient: ObservableObject {
    private let baseURL: String
    private let session: URLSession

    private let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }()

    private let encoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.keyEncodingStrategy = .convertToSnakeCase
        return encoder
    }()

    init(baseURL: String = "http://localhost:8000") {
        self.baseURL = baseURL
        self.session = URLSession.shared
    }

    // MARK: - Generic Request Methods

    private func request<T: Decodable>(
        _ endpoint: String,
        method: String = "GET",
        body: (any Encodable)? = nil
    ) async throws -> T {
        guard let url = URL(string: "\(baseURL)\(endpoint)") else {
            throw APIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        if let body = body {
            do {
                request.httpBody = try encoder.encode(body)
            } catch {
                throw APIError.networkError(error)
            }
        }

        do {
            let (data, response) = try await session.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw APIError.invalidResponse
            }

            guard (200...299).contains(httpResponse.statusCode) else {
                let message = String(data: data, encoding: .utf8)
                throw APIError.httpError(statusCode: httpResponse.statusCode, message: message)
            }

            do {
                return try decoder.decode(T.self, from: data)
            } catch {
                throw APIError.decodingError(error)
            }
        } catch let error as APIError {
            throw error
        } catch {
            throw APIError.networkError(error)
        }
    }

    private func requestWithoutResponse(
        _ endpoint: String,
        method: String = "DELETE"
    ) async throws {
        guard let url = URL(string: "\(baseURL)\(endpoint)") else {
            throw APIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = method

        do {
            let (_, response) = try await session.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw APIError.invalidResponse
            }

            guard (200...299).contains(httpResponse.statusCode) else {
                throw APIError.httpError(statusCode: httpResponse.statusCode, message: nil)
            }
        } catch let error as APIError {
            throw error
        } catch {
            throw APIError.networkError(error)
        }
    }

    // MARK: - Health Check

    func healthCheck() async throws -> Bool {
        let response: [String: String] = try await request("/health")
        return response["status"] == "ok"
    }

    // MARK: - Friction Items CRUD

    func createFrictionItem(_ item: FrictionItemCreate) async throws -> FrictionItemResponse {
        try await request("/api/friction-items", method: "POST", body: item)
    }

    func listFrictionItems(status: Status? = nil, category: Category? = nil) async throws -> [FrictionItemResponse] {
        var endpoint = "/api/friction-items"
        var queryItems: [URLQueryItem] = []

        if let status = status {
            queryItems.append(URLQueryItem(name: "status", value: status.rawValue))
        }
        if let category = category {
            queryItems.append(URLQueryItem(name: "category", value: category.rawValue))
        }

        if !queryItems.isEmpty {
            var components = URLComponents(string: "\(baseURL)\(endpoint)")
            components?.queryItems = queryItems
            endpoint = components?.url?.absoluteString.replacingOccurrences(of: baseURL, with: "") ?? endpoint
        }

        return try await request(endpoint)
    }

    func getFrictionItem(_ id: Int) async throws -> FrictionItemResponse {
        try await request("/api/friction-items/\(id)")
    }

    func updateFrictionItem(_ id: Int, update: FrictionItemUpdate) async throws -> FrictionItemResponse {
        try await request("/api/friction-items/\(id)", method: "PUT", body: update)
    }

    func deleteFrictionItem(_ id: Int) async throws {
        try await requestWithoutResponse("/api/friction-items/\(id)", method: "DELETE")
    }

    func incrementEncounter(_ id: Int) async throws -> FrictionItemResponse {
        try await request("/api/friction-items/\(id)/encounter", method: "POST", body: Optional<String>.none)
    }

    // MARK: - Analytics

    func getCurrentScore() async throws -> CurrentScore {
        try await request("/api/analytics/score")
    }

    func getFrictionTrend(days: Int = 30) async throws -> [TrendDataPoint] {
        try await request("/api/analytics/trend?days=\(days)")
    }

    func getCategoryBreakdown() async throws -> CategoryBreakdown {
        try await request("/api/analytics/by-category")
    }
}
