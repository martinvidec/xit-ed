import SwiftUI

struct ContentView: View {
    @Binding var document: XitFileDocument
    @State private var selectedGroupId: UUID?
    @State private var selectedItemId: UUID?
    @State private var isEditing = false
    
    var body: some View {
        NavigationSplitView {
            // Sidebar: Groups
            List(selection: $selectedGroupId) {
                ForEach($document.document.groups) { $group in
                    GroupRow(group: $group)
                        .tag(group.id)
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
            } else if let firstGroup = document.document.groups.first {
                ItemListView(
                    group: Binding(
                        get: { document.document.groups[0] },
                        set: { document.document.groups[0] = $0 }
                    ),
                    selectedItemId: $selectedItemId
                )
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
    }
    
    private func addGroup() {
        let newGroup = XitGroup(title: "New Group", items: [])
        document.document.groups.append(newGroup)
        selectedGroupId = newGroup.id
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
    @Binding var group: XitGroup
    @State private var isEditing = false
    @State private var editedTitle = ""
    
    var body: some View {
        HStack {
            Image(systemName: "folder")
                .foregroundColor(.secondary)
            
            if isEditing {
                TextField("Group Title", text: $editedTitle, onCommit: {
                    group.title = editedTitle.isEmpty ? nil : editedTitle
                    isEditing = false
                })
                .textFieldStyle(.plain)
            } else {
                Text(group.title ?? "Untitled")
                    .onTapGesture(count: 2) {
                        editedTitle = group.title ?? ""
                        isEditing = true
                    }
            }
            
            Spacer()
            
            Text("\(group.items.count)")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(Color.secondary.opacity(0.2))
                .clipShape(Capsule())
        }
    }
}

#Preview {
    ContentView(document: .constant(XitFileDocument()))
}
