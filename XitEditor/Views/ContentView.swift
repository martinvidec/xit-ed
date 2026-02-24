import SwiftUI

struct ContentView: View {
    @Binding var document: XitFileDocument
    @State private var selectedGroupId: UUID?
    @State private var selectedItemId: UUID?
    @State private var editingGroupId: UUID?

    var body: some View {
        NavigationSplitView {
            // Sidebar: Groups
            List {
                ForEach(document.document.groups) { group in
                    GroupRow(
                        group: group,
                        isSelected: selectedGroupId == group.id,
                        isEditing: editingGroupId == group.id,
                        onSelect: {
                            selectedGroupId = group.id
                        },
                        onTitleChange: { newTitle in
                            if let index = document.document.groups.firstIndex(where: { $0.id == group.id }) {
                                document.document.groups[index].title = newTitle.isEmpty ? nil : newTitle
                            }
                            editingGroupId = nil
                        },
                        onCancelEdit: {
                            editingGroupId = nil
                        }
                    )
                    .contextMenu {
                        Button("Rename") {
                            editingGroupId = group.id
                        }
                        Divider()
                        Button("Delete", role: .destructive) {
                            deleteGroup(group)
                        }
                    }
                }
            }
            .listStyle(.sidebar)
            .frame(minWidth: 200)
            .toolbar {
                ToolbarItem {
                    Button(action: addGroup) {
                        Label("Add Group", systemImage: "folder.badge.plus")
                    }
                }
            }
        } detail: {
            // Detail: Items in selected group
            if let groupIndex = document.document.groups.firstIndex(where: { $0.id == selectedGroupId }) {
                ItemListView(
                    group: $document.document.groups[groupIndex],
                    selectedItemId: $selectedItemId
                )
            } else if !document.document.groups.isEmpty {
                // Placeholder while onAppear sets the selection
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                VStack(spacing: 16) {
                    Image(systemName: "folder")
                        .font(.system(size: 48))
                        .foregroundColor(.secondary)
                    Text("No Groups")
                        .font(.title2)
                        .fontWeight(.semibold)
                    Text("Create a group to get started")
                        .foregroundColor(.secondary)
                    Button("Add Group", action: addGroup)
                        .buttonStyle(.borderedProminent)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .addNewItem)) { _ in
            addItemToCurrentGroup()
        }
        .task(id: document.document.groups.isEmpty) {
            if selectedGroupId == nil, let firstGroup = document.document.groups.first {
                selectedGroupId = firstGroup.id
            }
        }
    }
    
    private func addGroup() {
        let newGroup = XitGroup(title: "New Group", items: [])
        document.document.groups.append(newGroup)
        selectedGroupId = newGroup.id
    }

    private func deleteGroup(_ group: XitGroup) {
        let needsNewSelection = selectedGroupId == group.id
        let newSelection = document.document.groups.first { $0.id != group.id }?.id

        document.document.groups.removeAll { $0.id == group.id }

        if needsNewSelection {
            selectedGroupId = newSelection
        }
    }
    
    private func addItemToCurrentGroup() {
        let newItem = XitItem(
            status: .open,
            priority: 0,
            description: "New task",
            continuationLines: [],
            tags: [],
            dueDate: nil
        )
        
        if let groupIndex = document.document.groups.firstIndex(where: { $0.id == selectedGroupId }) {
            document.document.groups[groupIndex].items.append(newItem)
        } else if !document.document.groups.isEmpty {
            document.document.groups[0].items.append(newItem)
        }
    }
}

struct GroupRow: View {
    let group: XitGroup
    let isSelected: Bool
    let isEditing: Bool
    let onSelect: () -> Void
    let onTitleChange: (String) -> Void
    let onCancelEdit: () -> Void

    @State private var editedTitle = ""
    @FocusState private var isFocused: Bool

    var body: some View {
        HStack {
            Image(systemName: "folder")
                .foregroundColor(isSelected ? .white : .secondary)

            if isEditing {
                TextField("Group Title", text: $editedTitle)
                    .textFieldStyle(.plain)
                    .focused($isFocused)
                    .onSubmit {
                        onTitleChange(editedTitle)
                    }
                    .onExitCommand {
                        onCancelEdit()
                    }
            } else {
                Text(group.title ?? "Untitled")
                    .foregroundColor(isSelected ? .white : .primary)
            }

            Spacer()

            Text("\(group.items.count)")
                .font(.caption)
                .foregroundColor(isSelected ? .white.opacity(0.8) : .secondary)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(isSelected ? Color.white.opacity(0.2) : Color.secondary.opacity(0.2))
                .clipShape(Capsule())
        }
        .padding(.vertical, 4)
        .padding(.horizontal, 8)
        .background(isSelected ? Color.accentColor : Color.clear)
        .cornerRadius(6)
        .contentShape(Rectangle())
        .onTapGesture {
            onSelect()
        }
        .onChange(of: isEditing) { editing in
            if editing {
                editedTitle = group.title ?? ""
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                    isFocused = true
                }
            }
        }
    }
}

#Preview {
    ContentView(document: .constant(XitFileDocument()))
}
