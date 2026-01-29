//
//  AddFrictionView.swift
//  FrictionLog
//
//  Form for adding new friction items
//

import SwiftUI

struct AddFrictionView: View {
    @ObservedObject var viewModel: FrictionViewModel
    @State private var title = ""
    @State private var description = ""
    @State private var annoyanceLevel = 3
    @State private var selectedCategory: Category = .home
    @State private var encounterLimit: String = ""
    @State private var hasEncounterLimit = false

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Modern Header
                VStack(spacing: 8) {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [.blue.opacity(0.2), .purple.opacity(0.2)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 80, height: 80)

                        Text("➕")
                            .font(.system(size: 48))
                    }

                    Text("Add New Friction")
                        .font(.title).bold()

                    Text("Track what's bothering you")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.top, 20)

                VStack(spacing: 20) {
                    // Title Card
                    ModernFormCard(title: "📝 What's the friction?", icon: "text.bubble.fill") {
                        VStack(alignment: .leading, spacing: 12) {
                            TextField("e.g., Slow WiFi connection", text: $title)
                                .textFieldStyle(.plain)
                                .font(.headline)
                                .padding(12)
                                .background(Color.gray.opacity(0.08))
                                .cornerRadius(10)

                            TextField("Add more details (optional)", text: $description, axis: .vertical)
                                .textFieldStyle(.plain)
                                .font(.subheadline)
                                .padding(12)
                                .background(Color.gray.opacity(0.08))
                                .cornerRadius(10)
                                .lineLimit(3...6)
                        }
                    }

                    // Annoyance Level Card
                    ModernFormCard(title: "🌡️ How annoying is it?", icon: "flame.fill") {
                        VStack(spacing: 16) {
                            // Flame indicators
                            HStack(spacing: 8) {
                                ForEach(1...5, id: \.self) { level in
                                    VStack(spacing: 4) {
                                        Image(systemName: level <= annoyanceLevel ? "flame.fill" : "flame")
                                            .font(.title2)
                                            .foregroundColor(level <= annoyanceLevel ? flameColor(for: level) : .gray.opacity(0.3))
                                            .scaleEffect(level == annoyanceLevel ? 1.2 : 1.0)
                                            .animation(.spring(response: 0.3), value: annoyanceLevel)

                                        Text("\(level)")
                                            .font(.caption2)
                                            .foregroundColor(level == annoyanceLevel ? .primary : .secondary)
                                            .bold(level == annoyanceLevel)
                                    }
                                    .frame(maxWidth: .infinity)
                                }
                            }

                            // Slider
                            Slider(value: Binding(
                                get: { Double(annoyanceLevel) },
                                set: { annoyanceLevel = Int($0) }
                            ), in: 1...5, step: 1)
                            .tint(annoyanceColor)

                            // Description
                            Text(annoyanceDescription)
                                .font(.subheadline)
                                .foregroundColor(annoyanceColor)
                                .bold()
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 8)
                                .background(annoyanceColor.opacity(0.1))
                                .cornerRadius(8)
                        }
                    }

                    // Category Selection Card
                    ModernFormCard(title: "📂 Choose a category", icon: "square.grid.2x2.fill") {
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                            ForEach(Category.allCases) { category in
                                CategoryPill(
                                    category: category,
                                    isSelected: selectedCategory == category
                                ) {
                                    selectedCategory = category
                                }
                            }
                        }
                    }

                    // Encounter Limit Card
                    ModernFormCard(title: "⚠️ Set daily limit (optional)", icon: "bell.badge.fill") {
                        VStack(alignment: .leading, spacing: 12) {
                            Toggle(isOn: $hasEncounterLimit) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Enable encounter limit")
                                        .font(.subheadline)
                                        .bold()
                                    Text("Get notified when exceeded")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                            .toggleStyle(.switch)

                            if hasEncounterLimit {
                                HStack {
                                    Text("Max encounters per day:")
                                        .font(.subheadline)
                                    TextField("e.g., 5", text: $encounterLimit)
                                        .textFieldStyle(.plain)
                                        .font(.headline)
                                        .padding(8)
                                        .background(Color.gray.opacity(0.08))
                                        .cornerRadius(8)
                                        .frame(width: 80)
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, 24)

                // Messages
                if let error = viewModel.errorMessage {
                    MessageBanner(message: error, type: .error)
                        .padding(.horizontal, 24)
                }

                if let success = viewModel.successMessage {
                    MessageBanner(message: success, type: .success)
                        .padding(.horizontal, 24)
                }

                // Action buttons
                HStack(spacing: 16) {
                    Button {
                        clearForm()
                    } label: {
                        HStack {
                            Image(systemName: "xmark.circle.fill")
                            Text("Clear")
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                    }
                    .buttonStyle(.bordered)
                    .disabled(viewModel.isLoading)

                    Button {
                        Task {
                            await saveFrictionItem()
                        }
                    } label: {
                        HStack {
                            if viewModel.isLoading {
                                ProgressView()
                                    .controlSize(.small)
                            } else {
                                Image(systemName: "plus.circle.fill")
                                Text("Add Friction")
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(title.isEmpty || viewModel.isLoading)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var annoyanceColor: Color {
        switch annoyanceLevel {
        case 1: return .green
        case 2: return .mint
        case 3: return .orange
        case 4: return .red
        case 5: return .purple
        default: return .gray
        }
    }

    private func flameColor(for level: Int) -> Color {
        switch level {
        case 1: return .green
        case 2: return .yellow
        case 3: return .orange
        case 4: return .red
        case 5: return .purple
        default: return .gray
        }
    }

    private var annoyanceDescription: String {
        switch annoyanceLevel {
        case 1: return "😊 Barely noticeable"
        case 2: return "😐 Mildly annoying"
        case 3: return "😤 Moderately frustrating"
        case 4: return "😡 Very frustrating"
        case 5: return "🤬 Extremely disruptive"
        default: return ""
        }
    }

    private func saveFrictionItem() async {
        viewModel.clearMessages()

        let limit: Int? = hasEncounterLimit && !encounterLimit.isEmpty ? Int(encounterLimit) : nil

        let success = await viewModel.createItem(
            title: title,
            description: description.isEmpty ? nil : description,
            annoyanceLevel: annoyanceLevel,
            category: selectedCategory,
            encounterLimit: limit
        )

        if success {
            clearForm()
        }
    }

    private func clearForm() {
        title = ""
        description = ""
        annoyanceLevel = 3
        selectedCategory = .home
        encounterLimit = ""
        hasEncounterLimit = false
    }
}

// MARK: - Modern Form Card

struct ModernFormCard<Content: View>: View {
    let title: String
    let icon: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .foregroundColor(.blue)
                Text(title)
                    .font(.headline)
            }

            content
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(NSColor.controlBackgroundColor))
                .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 4)
        )
    }
}

// MARK: - Category Pill

struct CategoryPill: View {
    let category: Category
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(isSelected ? category.gradient : LinearGradient(colors: [.gray.opacity(0.1)], startPoint: .top, endPoint: .bottom))
                        .frame(width: 50, height: 50)

                    Text(category.emoji)
                        .font(.title2)
                }

                Text(category.displayName)
                    .font(.caption)
                    .fontWeight(isSelected ? .semibold : .regular)
                    .foregroundColor(isSelected ? category.color : .secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? category.color : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Message Banner

struct MessageBanner: View {
    enum MessageType {
        case success, error

        var color: Color {
            switch self {
            case .success: return .green
            case .error: return .red
            }
        }

        var icon: String {
            switch self {
            case .success: return "checkmark.circle.fill"
            case .error: return "exclamationmark.triangle.fill"
            }
        }
    }

    let message: String
    let type: MessageType

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: type.icon)
                .font(.title3)
            Text(message)
                .font(.subheadline)
            Spacer()
        }
        .foregroundColor(type.color)
        .padding()
        .background(type.color.opacity(0.1))
        .cornerRadius(12)
    }
}

#Preview {
    AddFrictionView(viewModel: FrictionViewModel())
}
