import AppKit

let app = NSApplication.shared
app.setActivationPolicy(.accessory)
let peek = TextPeek()
Task { await peek.start() }
app.run()
