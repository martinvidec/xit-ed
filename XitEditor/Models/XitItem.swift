import Foundation

/// Represents the status of a xit! item
enum XitStatus: String, CaseIterable {
    case open = " "
    case checked = "x"
    case ongoing = "@"
    case obsolete = "~"
    case inQuestion = "?"
    
    var symbol: String {
        switch self {
        case .open: return "[ ]"
        case .checked: return "[x]"
        case .ongoing: return "[@]"
        case .obsolete: return "[~]"
        case .inQuestion: return "[?]"
        }
    }
    
    var displayName: String {
        switch self {
        case .open: return "Open"
        case .checked: return "Done"
        case .ongoing: return "Ongoing"
        case .obsolete: return "Obsolete"
        case .inQuestion: return "In Question"
        }
    }
    
    var icon: String {
        switch self {
        case .open: return "circle"
        case .checked: return "checkmark.circle.fill"
        case .ongoing: return "arrow.triangle.2.circlepath.circle.fill"
        case .obsolete: return "minus.circle.fill"
        case .inQuestion: return "questionmark.circle.fill"
        }
    }
    
    /// Cycle to next status on click
    func next() -> XitStatus {
        switch self {
        case .open: return .checked
        case .checked: return .open
        case .ongoing: return .checked
        case .obsolete: return .open
        case .inQuestion: return .open
        }
    }
}

/// Represents a tag in a xit! item
struct XitTag: Identifiable, Equatable {
    let id = UUID()
    let name: String
    let value: String?
    
    var displayString: String {
        if let value = value {
            return "#\(name)=\(value)"
        }
        return "#\(name)"
    }
}

/// Represents a due date in a xit! item
struct XitDueDate: Equatable {
    enum DateType {
        case day(Date)
        case month(year: Int, month: Int)
        case week(year: Int, week: Int)
        case quarter(year: Int, quarter: Int)
        case year(Int)
    }
    
    let type: DateType
    let rawString: String
    
    var isOverdue: Bool {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        switch type {
        case .day(let date):
            return date < today
        case .month(let year, let month):
            let components = DateComponents(year: year, month: month)
            guard let date = calendar.date(from: components),
                  let endOfMonth = calendar.date(byAdding: DateComponents(month: 1, day: -1), to: date) else {
                return false
            }
            return endOfMonth < today
        case .week(let year, let week):
            var components = DateComponents()
            components.yearForWeekOfYear = year
            components.weekOfYear = week
            components.weekday = 7 // Saturday (end of week)
            guard let date = calendar.date(from: components) else { return false }
            return date < today
        case .quarter(let year, let quarter):
            let month = quarter * 3
            let components = DateComponents(year: year, month: month)
            guard let date = calendar.date(from: components),
                  let endOfMonth = calendar.date(byAdding: DateComponents(month: 1, day: -1), to: date) else {
                return false
            }
            return endOfMonth < today
        case .year(let year):
            let components = DateComponents(year: year, month: 12, day: 31)
            guard let date = calendar.date(from: components) else { return false }
            return date < today
        }
    }
}

/// Represents a single xit! item
struct XitItem: Identifiable, Equatable {
    let id = UUID()
    var status: XitStatus
    var priority: Int // Number of exclamation marks
    var description: String
    var continuationLines: [String]
    var tags: [XitTag]
    var dueDate: XitDueDate?
    
    var fullDescription: String {
        if continuationLines.isEmpty {
            return description
        }
        return ([description] + continuationLines).joined(separator: "\n    ")
    }
    
    /// Convert back to xit! format
    func toXitString() -> String {
        var result = status.symbol
        
        if priority > 0 {
            result += " " + String(repeating: "!", count: priority)
        }
        
        if !description.isEmpty {
            result += " " + description
        }
        
        for line in continuationLines {
            result += "\n    " + line
        }
        
        return result
    }
    
    static func == (lhs: XitItem, rhs: XitItem) -> Bool {
        lhs.id == rhs.id
    }
}

/// Represents a group of xit! items with optional title
struct XitGroup: Identifiable, Equatable {
    let id = UUID()
    var title: String?
    var items: [XitItem]
    
    /// Convert back to xit! format
    func toXitString() -> String {
        var lines: [String] = []
        
        if let title = title {
            lines.append(title)
        }
        
        for item in items {
            lines.append(item.toXitString())
        }
        
        return lines.joined(separator: "\n")
    }
    
    static func == (lhs: XitGroup, rhs: XitGroup) -> Bool {
        lhs.id == rhs.id
    }
}

/// Represents an entire xit! document
struct XitDocument: Equatable {
    var groups: [XitGroup]
    
    /// Convert back to xit! format
    func toXitString() -> String {
        groups.map { $0.toXitString() }.joined(separator: "\n\n")
    }
    
    static func == (lhs: XitDocument, rhs: XitDocument) -> Bool {
        lhs.groups.map { $0.id } == rhs.groups.map { $0.id }
    }
}
