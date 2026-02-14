import Foundation

/// Parser for xit! files according to spec v1.1
struct XitParser {
    
    // MARK: - Regex Patterns
    
    private static let checkboxPattern = #"^\[([\ x@~?])\]"#
    private static let priorityPattern = #"^(\.*)(!+)(\.*)$"#
    private static let tagPattern = #"#([a-zA-Z0-9_-]+)(?:=(?:"([^"]+)"|'([^']+)'|([a-zA-Z0-9_-]+)))?"#
    private static let dueDatePattern = #"->\s*(\d{4}(?:[-/]\d{2}(?:[-/]\d{2})?)?|\d{4}[-/][WQ]\d{1,2})"#
    
    // MARK: - Parsing
    
    /// Parse a xit! file content into a document
    static func parse(_ content: String) -> XitDocument {
        let lines = content.components(separatedBy: .newlines)
        var groups: [XitGroup] = []
        var currentGroup: XitGroup?
        var currentItem: XitItem?
        var pendingTitle: String?
        
        for line in lines {
            // Check if this is a blank line
            if line.trimmingCharacters(in: .whitespaces).isEmpty {
                // Save current item to group
                if let item = currentItem {
                    if currentGroup == nil {
                        currentGroup = XitGroup(title: pendingTitle, items: [])
                        pendingTitle = nil
                    }
                    currentGroup?.items.append(item)
                    currentItem = nil
                }
                
                // Save current group
                if let group = currentGroup, !group.items.isEmpty {
                    groups.append(group)
                    currentGroup = nil
                }
                continue
            }
            
            // Check if this is a continuation line (starts with 4 spaces)
            if line.hasPrefix("    ") && currentItem != nil {
                let continuation = String(line.dropFirst(4))
                currentItem?.continuationLines.append(continuation)
                continue
            }
            
            // Try to parse as an item
            if let item = parseItem(line) {
                // Save previous item
                if let prevItem = currentItem {
                    if currentGroup == nil {
                        currentGroup = XitGroup(title: pendingTitle, items: [])
                        pendingTitle = nil
                    }
                    currentGroup?.items.append(prevItem)
                }
                currentItem = item
                continue
            }
            
            // If not an item and not a continuation, it's a title
            // First, save any pending item and group
            if let item = currentItem {
                if currentGroup == nil {
                    currentGroup = XitGroup(title: pendingTitle, items: [])
                    pendingTitle = nil
                }
                currentGroup?.items.append(item)
                currentItem = nil
            }
            
            if let group = currentGroup, !group.items.isEmpty {
                groups.append(group)
                currentGroup = nil
            }
            
            pendingTitle = line
        }
        
        // Don't forget the last item and group
        if let item = currentItem {
            if currentGroup == nil {
                currentGroup = XitGroup(title: pendingTitle, items: [])
                pendingTitle = nil
            }
            currentGroup?.items.append(item)
        }
        
        if let group = currentGroup, !group.items.isEmpty {
            groups.append(group)
        }
        
        return XitDocument(groups: groups)
    }
    
    /// Parse a single line as a xit! item
    private static func parseItem(_ line: String) -> XitItem? {
        // Must start with checkbox
        guard let checkboxMatch = line.range(of: checkboxPattern, options: .regularExpression) else {
            return nil
        }
        
        let checkboxStr = String(line[checkboxMatch])
        guard checkboxStr.count >= 3 else { return nil }
        
        let statusChar = String(checkboxStr[checkboxStr.index(checkboxStr.startIndex, offsetBy: 1)])
        guard let status = XitStatus(rawValue: statusChar) else { return nil }
        
        // Get the rest after checkbox
        var remainder = String(line[checkboxMatch.upperBound...]).trimmingCharacters(in: .whitespaces)
        
        // Try to parse priority
        var priority = 0
        let words = remainder.split(separator: " ", maxSplits: 1, omittingEmptySubsequences: false)
        if let firstWord = words.first {
            let wordStr = String(firstWord)
            if let _ = wordStr.range(of: priorityPattern, options: .regularExpression) {
                priority = wordStr.filter { $0 == "!" }.count
                remainder = words.count > 1 ? String(words[1]) : ""
            }
        }
        
        // Parse tags from description
        let tags = parseTags(remainder)
        
        // Parse due date from description
        let dueDate = parseDueDate(remainder)
        
        return XitItem(
            status: status,
            priority: priority,
            description: remainder,
            continuationLines: [],
            tags: tags,
            dueDate: dueDate
        )
    }
    
    /// Parse tags from a description string
    static func parseTags(_ text: String) -> [XitTag] {
        var tags: [XitTag] = []
        
        guard let regex = try? NSRegularExpression(pattern: tagPattern, options: []) else {
            return tags
        }
        
        let range = NSRange(text.startIndex..., in: text)
        let matches = regex.matches(in: text, options: [], range: range)
        
        for match in matches {
            guard let nameRange = Range(match.range(at: 1), in: text) else { continue }
            let name = String(text[nameRange])
            
            var value: String?
            // Check quoted values first (groups 2 and 3), then unquoted (group 4)
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
    
    /// Parse due date from a description string
    private static func parseDueDate(_ text: String) -> XitDueDate? {
        guard let regex = try? NSRegularExpression(pattern: dueDatePattern, options: []) else {
            return nil
        }
        
        let range = NSRange(text.startIndex..., in: text)
        guard let match = regex.firstMatch(in: text, options: [], range: range),
              let dateRange = Range(match.range(at: 1), in: text) else {
            return nil
        }
        
        let dateStr = String(text[dateRange])
        return parseDateString(dateStr)
    }
    
    /// Parse a date string into XitDueDate
    private static func parseDateString(_ dateStr: String) -> XitDueDate? {
        let normalized = dateStr.replacingOccurrences(of: "/", with: "-")
        
        // Week pattern: yyyy-Www
        if normalized.contains("-W") {
            let parts = normalized.split(separator: "-W")
            if parts.count == 2,
               let year = Int(parts[0]),
               let week = Int(parts[1]) {
                return XitDueDate(type: .week(year: year, week: week), rawString: dateStr)
            }
        }
        
        // Quarter pattern: yyyy-Qq
        if normalized.contains("-Q") {
            let parts = normalized.split(separator: "-Q")
            if parts.count == 2,
               let year = Int(parts[0]),
               let quarter = Int(parts[1]) {
                return XitDueDate(type: .quarter(year: year, quarter: quarter), rawString: dateStr)
            }
        }
        
        let parts = normalized.split(separator: "-")
        
        switch parts.count {
        case 1:
            // Year only
            if let year = Int(parts[0]) {
                return XitDueDate(type: .year(year), rawString: dateStr)
            }
        case 2:
            // Year-Month
            if let year = Int(parts[0]), let month = Int(parts[1]) {
                return XitDueDate(type: .month(year: year, month: month), rawString: dateStr)
            }
        case 3:
            // Full date
            if let year = Int(parts[0]), let month = Int(parts[1]), let day = Int(parts[2]) {
                var components = DateComponents()
                components.year = year
                components.month = month
                components.day = day
                if let date = Calendar.current.date(from: components) {
                    return XitDueDate(type: .day(date), rawString: dateStr)
                }
            }
        default:
            break
        }
        
        return nil
    }
}
