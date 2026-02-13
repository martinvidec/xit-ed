import SwiftUI

struct ItemRow: View {
    @Binding var item: XitItem
    @State private var isEditing = false
    @State private var editedDescription = ""
    @State private var isHovering = false
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Checkbox
            StatusButton(status: $item.status)
            
            // Content
            VStack(alignment: .leading, spacing: 4) {
                // Priority and Description
                HStack(alignment: .top, spacing: 6) {
                    if item.priority > 0 {
                        PriorityBadge(level: item.priority)
                    }
                    
                    if isEditing {
                        TextField("Description", text: $editedDescription, onCommit: {
                            item.description = editedDescription
                            isEditing = false
                        })
                        .textFieldStyle(.plain)
                    } else {
                        DescriptionText(
                            text: item.description,
                            status: item.status
                        )
                        .onTapGesture(count: 2) {
                            editedDescription = item.description
                            isEditing = true
                        }
                    }
                }
                
                // Continuation lines
                if !item.continuationLines.isEmpty {
                    VStack(alignment: .leading, spacing: 2) {
                        ForEach(item.continuationLines, id: \.self) { line in
                            Text(line)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.leading, item.priority > 0 ? 30 : 0)
                }
                
                // Tags and Due Date
                if !item.tags.isEmpty || item.dueDate != nil {
                    HStack(spacing: 8) {
                        ForEach(item.tags) { tag in
                            TagBadge(tag: tag)
                        }
                        
                        if let dueDate = item.dueDate {
                            DueDateBadge(dueDate: dueDate)
                        }
                    }
                    .padding(.top, 2)
                }
            }
            
            Spacer()
            
            // Status menu on hover
            if isHovering {
                StatusMenu(status: $item.status)
            }
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
        .onHover { hovering in
            isHovering = hovering
        }
    }
}

struct StatusButton: View {
    @Binding var status: XitStatus
    
    var body: some View {
        Button(action: { status = status.next() }) {
            Image(systemName: status.icon)
                .font(.title2)
                .foregroundColor(colorForStatus(status))
        }
        .buttonStyle(.plain)
        .help("Click to toggle status")
    }
    
    private func colorForStatus(_ status: XitStatus) -> Color {
        switch status {
        case .open: return .secondary
        case .checked: return .green
        case .ongoing: return .orange
        case .obsolete: return .gray
        case .inQuestion: return .purple
        }
    }
}

struct StatusMenu: View {
    @Binding var status: XitStatus
    
    var body: some View {
        Menu {
            ForEach(XitStatus.allCases, id: \.self) { s in
                Button(action: { status = s }) {
                    Label(s.displayName, systemImage: s.icon)
                }
            }
        } label: {
            Image(systemName: "ellipsis.circle")
                .foregroundColor(.secondary)
        }
        .menuStyle(.borderlessButton)
        .frame(width: 24)
    }
}

struct PriorityBadge: View {
    let level: Int
    
    var body: some View {
        Text(String(repeating: "!", count: min(level, 3)))
            .font(.caption.bold())
            .foregroundColor(.white)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(priorityColor)
            .clipShape(RoundedRectangle(cornerRadius: 4))
    }
    
    private var priorityColor: Color {
        switch level {
        case 1: return .orange
        case 2: return .red
        default: return .purple
        }
    }
}

struct DescriptionText: View {
    let text: String
    let status: XitStatus
    
    var body: some View {
        Text(highlightedText)
            .strikethrough(status == .checked || status == .obsolete)
            .foregroundColor(status == .obsolete ? .secondary : .primary)
    }
    
    private var highlightedText: AttributedString {
        var result = AttributedString(text)
        
        // Highlight tags
        let tagPattern = #"#[a-zA-Z0-9_-]+(?:=(?:"[^"]+"|'[^']+'|[a-zA-Z0-9_-]+))?"#
        if let regex = try? NSRegularExpression(pattern: tagPattern) {
            let range = NSRange(text.startIndex..., in: text)
            let matches = regex.matches(in: text, options: [], range: range)
            
            for match in matches.reversed() {
                if let swiftRange = Range(match.range, in: text),
                   let attrRange = Range(swiftRange, in: result) {
                    result[attrRange].foregroundColor = .blue
                }
            }
        }
        
        // Highlight due dates
        let dueDatePattern = #"->\s*\d{4}(?:[-/]\d{2}(?:[-/]\d{2})?)?|\d{4}[-/][WQ]\d{1,2}"#
        if let regex = try? NSRegularExpression(pattern: dueDatePattern) {
            let range = NSRange(text.startIndex..., in: text)
            let matches = regex.matches(in: text, options: [], range: range)
            
            for match in matches.reversed() {
                if let swiftRange = Range(match.range, in: text),
                   let attrRange = Range(swiftRange, in: result) {
                    result[attrRange].foregroundColor = .purple
                }
            }
        }
        
        return result
    }
}

struct TagBadge: View {
    let tag: XitTag
    
    var body: some View {
        Text(tag.displayString)
            .font(.caption)
            .foregroundColor(.blue)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(Color.blue.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 4))
    }
}

struct DueDateBadge: View {
    let dueDate: XitDueDate
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "calendar")
            Text(dueDate.rawString)
        }
        .font(.caption)
        .foregroundColor(dueDate.isOverdue ? .red : .purple)
        .padding(.horizontal, 6)
        .padding(.vertical, 2)
        .background((dueDate.isOverdue ? Color.red : Color.purple).opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 4))
    }
}

#Preview {
    VStack {
        ItemRow(item: .constant(XitItem(
            status: .open,
            priority: 2,
            description: "Important task #work #urgent -> 2024-03-15",
            continuationLines: ["This is a continuation", "And another line"],
            tags: [XitTag(name: "work", value: nil), XitTag(name: "urgent", value: nil)],
            dueDate: nil
        )))
        
        ItemRow(item: .constant(XitItem(
            status: .checked,
            priority: 0,
            description: "Completed task",
            continuationLines: [],
            tags: [],
            dueDate: nil
        )))
    }
    .padding()
}
