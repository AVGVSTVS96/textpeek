import Foundation
import ServiceManagement

@MainActor
final class TextPeek {
    private let contacts = ContactBook()
    private let notifier = Notifier()
    private var store: MessageStore?
    private var watcher: DispatchSourceFileSystemObject?
    private var lastID: Int64 = 0

    func start() async {
        try? SMAppService.mainApp.register()
        await notifier.requestAuthorization()
        await contacts.load()
        do {
            let store = try MessageStore()
            self.store = store
            lastID = store.latestID()
            watch()
        } catch {
            notifier.askForFullDiskAccess()
        }
    }

    // Our open connection keeps chat.db-wal from being deleted, so one watcher lasts the app's lifetime.
    private func watch() {
        let descriptor = open(MessageStore.path + "-wal", O_EVTONLY)
        let watcher = DispatchSource.makeFileSystemObjectSource(fileDescriptor: descriptor, eventMask: [.write, .extend], queue: .main)
        watcher.setEventHandler {
            MainActor.assumeIsolated { self.deliverNew() }
        }
        watcher.setCancelHandler { close(descriptor) }
        watcher.resume()
        self.watcher = watcher
    }

    private func deliverNew() {
        guard let store else { return }
        let top = store.latestID()
        guard top > lastID else { return }
        store.messages(after: lastID, through: top).forEach(notify)
        lastID = top
    }

    private func notify(_ message: IncomingMessage) {
        if let name = contacts.name(for: message.sender) {
            notifier.post(title: name, subtitle: message.group, body: "New message", sender: message.sender)
        } else {
            notifier.post(title: message.sender, subtitle: message.group, body: message.text, sender: message.sender)
        }
    }
}
