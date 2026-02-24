import SwiftUI

@main
struct XitEditorApp: App {
    var body: some Scene {
        DocumentGroup(newDocument: XitFileDocument()) { file in
            ContentView(document: file.$document)
        }
        .commands {
            CommandGroup(after: .newItem) {
                Button("New Task") {
                    NotificationCenter.default.post(name: .addNewItem, object: nil)
                }
                .keyboardShortcut("t", modifiers: [.command])
            }

            CommandMenu("Edit") {
                Menu("Set Status") {
                    Button("Open [ ]") {
                        NotificationCenter.default.post(name: .setStatusOpen, object: nil)
                    }
                    .keyboardShortcut(.space, modifiers: [])

                    Button("Checked [x]") {
                        NotificationCenter.default.post(name: .setStatusChecked, object: nil)
                    }
                    .keyboardShortcut(.init("x"), modifiers: [])

                    Button("Ongoing [@]") {
                        NotificationCenter.default.post(name: .setStatusOngoing, object: nil)
                    }
                    .keyboardShortcut(.init("l"), modifiers: [.option])

                    Button("Obsolete [~]") {
                        NotificationCenter.default.post(name: .setStatusObsolete, object: nil)
                    }
                    .keyboardShortcut(.init("n"), modifiers: [.option])

                    Button("In Question [?]") {
                        NotificationCenter.default.post(name: .setStatusInQuestion, object: nil)
                    }
                    .keyboardShortcut(.init("?"), modifiers: [])
                }
            }
        }
    }
}

extension Notification.Name {
    static let addNewItem = Notification.Name("addNewItem")
    static let setStatusOpen = Notification.Name("setStatusOpen")
    static let setStatusChecked = Notification.Name("setStatusChecked")
    static let setStatusOngoing = Notification.Name("setStatusOngoing")
    static let setStatusObsolete = Notification.Name("setStatusObsolete")
    static let setStatusInQuestion = Notification.Name("setStatusInQuestion")
}
