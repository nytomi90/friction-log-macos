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
            VStack(spacing: 20) {
                Text("Add Friction Item")
                    .font(.largeTitle)
                    .bold()

                Form {
                    Section("Details") {
                        TextField("Title", text: $title)
                            .textFieldStyle(.roundedBorder)

                        TextField("Description (optional)", text: $description, axis: .vertical)
                            .textFieldStyle(.roundedBorder)
                            .lineLimit(3...6)
                    }

                    Section("Annoyance Level") {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Low")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Slider(value: Binding(
                                    get: { Double(annoyanceLevel) },
                                    set: { annoyanceLevel = Int($0) }
                                ), in: 1...5, step: 1)
                                Text("High")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }

                            HStack {
                                ForEach(1...5, id: \.self) { level in
                                    Image(systemName: level <= annoyanceLevel ? "star.fill" : "star")
                                        .foregroundColor(annoyanceColor)
                                        .font(.title3)
                                }
                                Spacer()
                                Text("Level \(annoyanceLevel)")
                                    .font(.headline)
                                    .foregroundColor(annoyanceColor)
                            }
                        }
                        .padding(.vertical, 4)
                    }

                    Section("Category") {
                        Picker("Category", selection: $selectedCategory) {
                            ForEach(Category.allCases) { category in
                                Text(category.displayName).tag(category)
                            }
                        }
                        .pickerStyle(.segmented)
                    }
                }
                .formStyle(.grouped)

                // Messages
                if let error = viewModel.errorMessage {
                    HStack {
                        Image(systemName: "exclamationmark.circle")
                        Text(error)
                    }
                    .foregroundColor(.red)
                    .font(.callout)
                    .padding()
                    .background(Color.red.opacity(0.1))
                    .cornerRadius(8)
                }

                if let success = viewModel.successMessage {
                    HStack {
                        Image(systemName: "checkmark.circle")
                        Text(success)
                    }
                    .foregroundColor(.green)
                    .font(.callout)
                    .padding()
                    .background(Color.green.opacity(0.1))
                    .cornerRadius(8)
                }

                // Action buttons
                HStack(spacing: 12) {
                    Button("Clear") {
                        clearForm()
                    }
                    .buttonStyle(.bordered)
                    .disabled(viewModel.isLoading)

                    Button {
                        Task {
                            await saveFrictionItem()
                        }
                    } label: {
                        if viewModel.isLoading {
                            ProgressView()
                                .controlSize(.small)
                                .padding(.horizontal, 20)
                        } else {
                            Text("Add Friction Item")
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(title.isEmpty || viewModel.isLoading)
                }
                .padding(.top, 8)

                Spacer(minLength: 20)
            }
            .padding()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var annoyanceColor: Color {
        switch annoyanceLevel {
        case 1...2: return .green
        case 3: return .orange
        case 4...5: return .red
        default: return .gray
        }
    }

    private func saveFrictionItem() async {
        viewModel.clearMessages()

        let success = await viewModel.createItem(
            title: title,
            description: description,
            annoyanceLevel: annoyanceLevel,
            category: selectedCategory
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
    }
}

#Preview {
    AddFrictionView(viewModel: FrictionViewModel())
}
