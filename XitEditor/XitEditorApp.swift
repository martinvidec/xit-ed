import SwiftUI

@main
struct XitEditorApp: App {
    var body: some Scene {
        DocumentGroup(newDocument: XitFileDocument()) { file in
            ContentView(document: file.$document)
        }
        .commands {
            CommandGroup(replacing: .newItem) {
                Button("New Item") {
                    NotificationCenter.default.post(name: .addNewItem, object: nil)
                }
                .keyboardShortcut("n", modifiers: [.command])
            }
        }
    }
}

extension Notification.Name {
    static let addNewItem = Notification.Name("addNewItem")
}
