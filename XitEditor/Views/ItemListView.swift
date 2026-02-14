import SwiftUI

struct ItemListView: View {
    @Binding var group: XitGroup
    @Binding var selectedItemId: UUID?
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
            List(selection: $selectedItemId) {
                ForEach(filteredItemIndices, id: \.self) { index in
                    ItemRow(item: $group.items[index])
                        .tag(group.items[index].id)
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
            if checkedCount > 0 {
                Label("\(checkedCount)", systemImage: "checkmark.circle.fill")
                    .font(.caption)
                    .foregroundColor(.green)
            }
        }
    }
}

#Preview {
    ItemListView(
        group: .constant(XitGroup(title: "Test", items: [
            XitItem(status: .open, priority: 1, description: "Test item #work", continuationLines: [], tags: [], dueDate: nil)
        ])),
        selectedItemId: .constant(nil)
    )
}
