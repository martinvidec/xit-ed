import SwiftUI

@main
struct XitEditorApp: App {
    var body: some Scene {
        DocumentGroup(newDocument: XitFileDocument()) { file in
            ContentView(document: file.$document)
        }
        .commands {
            CommandGroup(replacing: .newItem) { }
            CommandGroup(after: .newItem) {
                Button("New Task") {
                    NotificationCenter.default.post(name: .addNewItem, object: nil)
                }
                .keyboardShortcut("t", modifiers: [.command])
            }
        }
    }
}

extension Notification.Name {
    static let addNewItem = Notification.Name("addNewItem")
}
