import SwiftUI

struct ContentView: View {
    @Binding var document: XitFileDocument
    @State private var selectedGroupId: UUID?
    @State private var selectedItemId: UUID?
    @State private var editingGroupId: UUID?
    @State private var editingItemId: UUID?
    @State private var statusFilter: XitStatus? = nil

    var body: some View {
        NavigationSplitView {
            // Sidebar: Groups
            ScrollViewReader { proxy in
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
                        .id(group.id)
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
                .onChange(of: selectedGroupId) { newId in
                    if let id = newId {
                        withAnimation {
                            proxy.scrollTo(id, anchor: .center)
                        }
                    }
                }
            }
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
                    selectedItemId: $selectedItemId,
                    editingItemId: $editingItemId,
                    statusFilter: $statusFilter
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
        .onChange(of: selectedGroupId) { _ in
            // Cancel group editing when selecting different group
            editingGroupId = nil
            // Clear item selection when switching groups
            selectedItemId = nil
            editingItemId = nil
        }
        .background(
            Group {
                // Only enable navigation shortcuts when not editing
                if editingItemId == nil && editingGroupId == nil {
                    // Central Enter key handler
                    Button("") {
                        if let selectedId = selectedItemId {
                            editingItemId = selectedId
                        } else if let selectedId = selectedGroupId {
                            editingGroupId = selectedId
                        }
                    }
                    .keyboardShortcut(.return, modifiers: [])

                    // Arrow key navigation
                    Button("") { navigateUp() }
                        .keyboardShortcut(.upArrow, modifiers: [])
                    Button("") { navigateDown() }
                        .keyboardShortcut(.downArrow, modifiers: [])
                    Button("") { navigateLeft() }
                        .keyboardShortcut(.leftArrow, modifiers: [])
                    Button("") { navigateRight() }
                        .keyboardShortcut(.rightArrow, modifiers: [])
                }
            }
            .opacity(0)
            .frame(width: 0, height: 0)
        )
        .onReceive(NotificationCenter.default.publisher(for: .setStatusOpen)) { _ in
            setSelectedItemStatus(.open)
        }
        .onReceive(NotificationCenter.default.publisher(for: .setStatusChecked)) { _ in
            setSelectedItemStatus(.checked)
        }
        .onReceive(NotificationCenter.default.publisher(for: .setStatusOngoing)) { _ in
            setSelectedItemStatus(.ongoing)
        }
        .onReceive(NotificationCenter.default.publisher(for: .setStatusObsolete)) { _ in
            setSelectedItemStatus(.obsolete)
        }
        .onReceive(NotificationCenter.default.publisher(for: .setStatusInQuestion)) { _ in
            setSelectedItemStatus(.inQuestion)
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

    private func setSelectedItemStatus(_ status: XitStatus) {
        // Don't change status while editing
        guard editingItemId == nil, editingGroupId == nil else { return }
        guard let itemId = selectedItemId else { return }
        guard let groupIndex = document.document.groups.firstIndex(where: { $0.id == selectedGroupId }) else { return }
        guard let itemIndex = document.document.groups[groupIndex].items.firstIndex(where: { $0.id == itemId }) else { return }

        document.document.groups[groupIndex].items[itemIndex].status = status
    }

    // MARK: - Arrow Key Navigation

    private func navigateUp() {
        guard editingItemId == nil, editingGroupId == nil else { return }

        if selectedItemId != nil {
            // Navigate items
            navigateItems(direction: -1)
        } else {
            // Navigate groups
            navigateGroups(direction: -1)
        }
    }

    private func navigateDown() {
        guard editingItemId == nil, editingGroupId == nil else { return }

        if selectedItemId != nil {
            navigateItems(direction: 1)
        } else {
            navigateGroups(direction: 1)
        }
    }

    private func navigateLeft() {
        guard editingItemId == nil, editingGroupId == nil else { return }
        // Switch to groups (clear item selection)
        selectedItemId = nil
    }

    private func navigateRight() {
        guard editingItemId == nil, editingGroupId == nil else { return }
        // Switch to items (select first item if none selected)
        if selectedItemId == nil,
           let groupIndex = document.document.groups.firstIndex(where: { $0.id == selectedGroupId }),
           let firstItem = document.document.groups[groupIndex].items.first {
            selectedItemId = firstItem.id
        }
    }

    private func navigateGroups(direction: Int) {
        let groups = document.document.groups
        guard !groups.isEmpty else { return }

        if let currentId = selectedGroupId,
           let currentIndex = groups.firstIndex(where: { $0.id == currentId }) {
            let newIndex = max(0, min(groups.count - 1, currentIndex + direction))
            selectedGroupId = groups[newIndex].id
        } else {
            selectedGroupId = groups.first?.id
        }
    }

    private func navigateItems(direction: Int) {
        guard let groupIndex = document.document.groups.firstIndex(where: { $0.id == selectedGroupId }) else { return }
        let allItems = document.document.groups[groupIndex].items

        // Filter items based on current filter
        let filteredItems: [XitItem]
        if let filter = statusFilter {
            filteredItems = allItems.filter { $0.status == filter }
        } else {
            filteredItems = allItems
        }

        guard !filteredItems.isEmpty else { return }

        if let currentId = selectedItemId,
           let currentIndex = filteredItems.firstIndex(where: { $0.id == currentId }) {
            let newIndex = max(0, min(filteredItems.count - 1, currentIndex + direction))
            selectedItemId = filteredItems[newIndex].id
        } else {
            selectedItemId = filteredItems.first?.id
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
