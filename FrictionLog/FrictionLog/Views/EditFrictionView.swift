//
//  EditFrictionView.swift
//  FrictionLog
//
//  Modal sheet for editing friction items
//

import SwiftUI

struct EditFrictionView: View {
    let item: FrictionItemResponse
    @ObservedObject var viewModel: FrictionViewModel
    @Binding var isPresented: Bool

    @State private var title: String
    @State private var description: String
    @State private var annoyanceLevel: Int
    @State private var selectedCategory: Category
    @State private var selectedStatus: Status

    init(item: FrictionItemResponse, viewModel: FrictionViewModel, isPresented: Binding<Bool>) {
        self.item = item
        self.viewModel = viewModel
        self._isPresented = isPresented

        // Initialize state from item
        _title = State(initialValue: item.title)
        _description = State(initialValue: item.description ?? "")
        _annoyanceLevel = State(initialValue: item.annoyanceLevel)
        _selectedCategory = State(initialValue: item.category)
        _selectedStatus = State(initialValue: item.status)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
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

                        Section("Status") {
                            Picker("Status", selection: $selectedStatus) {
                                ForEach(Status.allCases, id: \.self) { status in
                                    Text(status.displayName).tag(status)
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

                    Spacer(minLength: 20)
                }
                .padding()
            }
            .navigationTitle("Edit Friction Item")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        isPresented = false
                    }
                    .disabled(viewModel.isLoading)
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        Task {
                            await saveChanges()
                        }
                    } label: {
                        if viewModel.isLoading {
                            ProgressView()
                                .controlSize(.small)
                        } else {
                            Text("Save")
                        }
                    }
                    .disabled(title.isEmpty || viewModel.isLoading || !hasChanges)
                }
            }
        }
        .frame(minWidth: 600, minHeight: 500)
    }

    private var annoyanceColor: Color {
        switch annoyanceLevel {
        case 1...2: return .green
        case 3: return .orange
        case 4...5: return .red
        default: return .gray
        }
    }

    private var hasChanges: Bool {
        title != item.title ||
        description != (item.description ?? "") ||
        annoyanceLevel != item.annoyanceLevel ||
        selectedCategory != item.category ||
        selectedStatus != item.status
    }

    private func saveChanges() async {
        viewModel.clearMessages()

        let success = await viewModel.updateItem(
            item.id,
            title: title != item.title ? title : nil,
            description: description != (item.description ?? "") ? (description.isEmpty ? nil : description) : nil,
            annoyanceLevel: annoyanceLevel != item.annoyanceLevel ? annoyanceLevel : nil,
            category: selectedCategory != item.category ? selectedCategory : nil,
            status: selectedStatus != item.status ? selectedStatus : nil
        )

        if success {
            isPresented = false
        }
    }
}

#Preview {
    EditFrictionView(
        item: FrictionItemResponse(
            id: 1,
            title: "Test Item",
            description: "Test description",
            annoyanceLevel: 3,
            category: .home,
            status: .notFixed,
            createdAt: Date(),
            updatedAt: Date(),
            fixedAt: nil
        ),
        viewModel: FrictionViewModel(),
        isPresented: .constant(true)
    )
}
