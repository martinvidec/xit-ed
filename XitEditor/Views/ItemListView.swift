import SwiftUI

struct ItemListView: View {
    @Binding var group: XitGroup
    @Binding var selectedItemId: UUID?
    @Binding var editingItemId: UUID?
    @State private var newItemText = ""
    @State private var statusFilter: XitStatus? = nil
    @FocusState private var isAddingItem: Bool

    private var filteredItemIndices: [Int] {
        group.items.indices.filter { index in
            guard let filter = statusFilter else { return true }
            return group.items[index].status == filter
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            if let title = group.title {
                HStack {
                    Text(title)
                        .font(.title2)
                        .fontWeight(.semibold)
                    Spacer()

                    ItemStatsView(items: group.items)
                }
                .padding()
                .background(Color(nsColor: .windowBackgroundColor))
            }

            Divider()

            // Item list
            ScrollViewReader { proxy in
                List {
                    ForEach(filteredItemIndices, id: \.self) { index in
                        let item = group.items[index]
                        ItemRow(
                            item: $group.items[index],
                            isSelected: selectedItemId == item.id,
                            isEditing: editingItemId == item.id,
                            onSelect: {
                                selectedItemId = item.id
                            },
                            onStartEdit: {
                                editingItemId = item.id
                            },
                            onEndEdit: {
                                editingItemId = nil
                            }
                        )
                        .id(item.id)
                        .contextMenu {
                            Button("Edit") {
                                selectedItemId = item.id
                                editingItemId = item.id
                            }
                            Divider()
                            Menu("Set Status") {
                                ForEach(XitStatus.allCases, id: \.self) { status in
                                    Button(status.displayName) {
                                        group.items[index].status = status
                                    }
                                }
                            }
                            Divider()
                            Button("Delete", role: .destructive) {
                                group.items.remove(at: index)
                            }
                        }
                    }
                    .onDelete(perform: deleteFilteredItems)
                    .onMove(perform: statusFilter == nil ? moveItems : nil)

                    // Quick add field
                    HStack(spacing: 12) {
                        Image(systemName: "plus.circle")
                            .foregroundColor(.secondary)

                        TextField("Add new item...", text: $newItemText)
                            .textFieldStyle(.plain)
                            .focused($isAddingItem)
                            .onSubmit {
                                addItem()
                            }
                    }
                    .padding(.vertical, 4)
                }
                .listStyle(.inset)
                .onChange(of: selectedItemId) { newId in
                    if let id = newId {
                        withAnimation {
                            proxy.scrollTo(id, anchor: .center)
                        }
                    }
                }
            }
        }
        .onChange(of: group.id) { _ in
            // Reset editing state when switching groups
            editingItemId = nil
        }
        .onChange(of: selectedItemId) { _ in
            // Reset editing state when selecting different item
            editingItemId = nil
        }
        .toolbar {
            ToolbarItemGroup {
                Button(action: { isAddingItem = true }) {
                    Label("Add Item", systemImage: "plus")
                }
                
                Menu {
                    Button {
                        statusFilter = nil
                    } label: {
                        if statusFilter == nil {
                            Label("Show All", systemImage: "checkmark")
                        } else {
                            Text("Show All")
                        }
                    }
                    Divider()
                    ForEach(XitStatus.allCases, id: \.self) { status in
                        Button {
                            statusFilter = status
                        } label: {
                            if statusFilter == status {
                                Label(status.displayName, systemImage: "checkmark")
                            } else {
                                Text(status.displayName)
                            }
                        }
                    }
                } label: {
                    Label("Filter", systemImage: statusFilter == nil ? "line.3.horizontal.decrease.circle" : "line.3.horizontal.decrease.circle.fill")
                }
            }
        }
    }
    
    private func addItem() {
        guard !newItemText.isEmpty else { return }
        
        let newItem = XitItem(
            status: .open,
            priority: 0,
            description: newItemText,
            continuationLines: [],
            tags: XitParser.parseTags(newItemText),
            dueDate: nil
        )
        
        group.items.append(newItem)
        newItemText = ""
    }
    
    private func deleteItems(at offsets: IndexSet) {
        group.items.remove(atOffsets: offsets)
    }
    
    private func deleteFilteredItems(at offsets: IndexSet) {
        let indicesToDelete = offsets.map { filteredItemIndices[$0] }
        for index in indicesToDelete.sorted().reversed() {
            group.items.remove(at: index)
        }
    }
    
    private func moveItems(from source: IndexSet, to destination: Int) {
        group.items.move(fromOffsets: source, toOffset: destination)
    }
}

struct ItemStatsView: View {
    let items: [XitItem]
    
    var openCount: Int { items.filter { $0.status == .open }.count }
    var checkedCount: Int { items.filter { $0.status == .checked }.count }
    var ongoingCount: Int { items.filter { $0.status == .ongoing }.count }
    var obsoleteCount: Int { items.filter { $0.status == .obsolete }.count }
    var inQuestionCount: Int { items.filter { $0.status == .inQuestion }.count }
    
    var body: some View {
        HStack(spacing: 12) {
            if openCount > 0 {
                Label("\(openCount)", systemImage: "circle")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            if ongoingCount > 0 {
                Label("\(ongoingCount)", systemImage: "arrow.triangle.2.circlepath.circle.fill")
                    .font(.caption)
                    .foregroundColor(.orange)
            }
            if inQuestionCount > 0 {
                Label("\(inQuestionCount)", systemImage: "questionmark.circle.fill")
                    .font(.caption)
                    .foregroundColor(.purple)
            }
            if checkedCount > 0 {
                Label("\(checkedCount)", systemImage: "checkmark.circle.fill")
                    .font(.caption)
                    .foregroundColor(.green)
            }
            if obsoleteCount > 0 {
                Label("\(obsoleteCount)", systemImage: "minus.circle.fill")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
        }
    }
}

#Preview {
    ItemListView(
        group: .constant(XitGroup(title: "Test", items: [
            XitItem(status: .open, priority: 1, description: "Test item #work", continuationLines: [], tags: [], dueDate: nil)
        ])),
        selectedItemId: .constant(nil),
        editingItemId: .constant(nil)
    )
}
