import SwiftUI

struct ItemListView: View {
    @Binding var group: XitGroup
    @Binding var selectedItemId: UUID?
    @State private var newItemText = ""
    @FocusState private var isAddingItem: Bool
    
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
                ForEach($group.items) { $item in
                    ItemRow(item: $item)
                        .tag(item.id)
                }
                .onDelete(perform: deleteItems)
                .onMove(perform: moveItems)
                
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
                    Button("Show All") { }
                    Divider()
                    ForEach(XitStatus.allCases, id: \.self) { status in
                        Button(status.displayName) { }
                    }
                } label: {
                    Label("Filter", systemImage: "line.3.horizontal.decrease.circle")
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

// Extension to make tag parsing accessible
extension XitParser {
    static func parseTags(_ text: String) -> [XitTag] {
        var tags: [XitTag] = []
        let tagPattern = #"#([a-zA-Z0-9_-]+)(?:=(?:"([^"]+)"|'([^']+)'|([a-zA-Z0-9_-]+)))?"#
        
        guard let regex = try? NSRegularExpression(pattern: tagPattern, options: []) else {
            return tags
        }
        
        let range = NSRange(text.startIndex..., in: text)
        let matches = regex.matches(in: text, options: [], range: range)
        
        for match in matches {
            guard let nameRange = Range(match.range(at: 1), in: text) else { continue }
            let name = String(text[nameRange])
            
            var value: String?
            for groupIndex in [2, 3, 4] {
                if let valueRange = Range(match.range(at: groupIndex), in: text) {
                    value = String(text[valueRange])
                    break
                }
            }
            
            tags.append(XitTag(name: name, value: value))
        }
        
        return tags
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
