import SwiftUI
import UniformTypeIdentifiers

extension UTType {
    static var xitFile: UTType {
        UTType(importedAs: "net.jotaen.xit", conformingTo: .plainText)
    }
}

struct XitFileDocument: FileDocument {
    var document: XitDocument
    var rawText: String
    
    static var readableContentTypes: [UTType] { [.xitFile, .plainText] }
    static var writableContentTypes: [UTType] { [.xitFile, .plainText] }
    
    init() {
        self.document = XitDocument(groups: [
            XitGroup(title: "My Tasks", items: [
                XitItem(status: .open, priority: 0, description: "Your first task", continuationLines: [], tags: [], dueDate: nil)
            ])
        ])
        self.rawText = document.toXitString()
    }
    
    init(configuration: ReadConfiguration) throws {
        guard let data = configuration.file.regularFileContents,
              let string = String(data: data, encoding: .utf8)
        else {
            throw CocoaError(.fileReadCorruptFile)
        }
        self.rawText = string
        self.document = XitParser.parse(string)
    }
    
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        let text = document.toXitString()
        guard let data = text.data(using: .utf8) else {
            throw CocoaError(.fileWriteUnknown)
        }
        return .init(regularFileWithContents: data)
    }
}
