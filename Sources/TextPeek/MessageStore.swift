import Foundation
import SQLite3

struct IncomingMessage {
    let sender: String
    let text: String
    let group: String?
}

struct MessageStoreError: Error {
    let reason: String
}

final class MessageStore {
    static let path = NSHomeDirectory() + "/Library/Messages/chat.db"

    private var db: OpaquePointer?

    init(path: String = MessageStore.path) throws {
        guard sqlite3_open_v2(path, &db, SQLITE_OPEN_READWRITE, nil) == SQLITE_OK,
              sqlite3_exec(db, "PRAGMA query_only = ON; SELECT 1 FROM message LIMIT 1", nil, nil, nil) == SQLITE_OK
        else {
            let reason = String(cString: sqlite3_errmsg(db))
            sqlite3_close(db)
            throw MessageStoreError(reason: reason)
        }
    }

    deinit {
        sqlite3_close(db)
    }

    func latestID() -> Int64 {
        var latest: Int64 = 0
        query("SELECT IFNULL(MAX(ROWID), 0) FROM message") { row in
            latest = sqlite3_column_int64(row, 0)
        }
        return latest
    }

    func messages(after first: Int64, through last: Int64) -> [IncomingMessage] {
        let sql = """
            SELECT h.id, m.text, m.attributedBody, c.style, c.display_name
            FROM message m
            JOIN handle h ON h.ROWID = m.handle_id
            LEFT JOIN chat_message_join cmj ON cmj.message_id = m.ROWID
            LEFT JOIN chat c ON c.ROWID = cmj.chat_id
            WHERE m.ROWID > ?1 AND m.ROWID <= ?2
              AND m.is_from_me = 0 AND m.is_read = 0 AND m.item_type = 0
              AND m.date > ?3
            ORDER BY m.ROWID
            """
        let recent = Int64((Date.now.timeIntervalSinceReferenceDate - 120) * 1_000_000_000)
        var messages: [IncomingMessage] = []
        query(sql, bind: [first, last, recent]) { row in
            let isGroup = sqlite3_column_int(row, 3) == 43
            messages.append(IncomingMessage(
                sender: string(row, 0) ?? "Unknown",
                text: Self.readable(string(row, 1) ?? body(row, 2)),
                group: isGroup ? (string(row, 4).flatMap { $0.isEmpty ? nil : $0 } ?? "Group") : nil
            ))
        }
        return messages
    }

    private func query(_ sql: String, bind values: [Int64] = [], row: (OpaquePointer) -> Void) {
        var statement: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK, let statement else { return }
        defer { sqlite3_finalize(statement) }
        for (index, value) in values.enumerated() {
            sqlite3_bind_int64(statement, Int32(index + 1), value)
        }
        while sqlite3_step(statement) == SQLITE_ROW {
            row(statement)
        }
    }

    private func string(_ row: OpaquePointer, _ column: Int32) -> String? {
        sqlite3_column_text(row, column).map { String(cString: $0) }
    }

    private func body(_ row: OpaquePointer, _ column: Int32) -> String? {
        guard let bytes = sqlite3_column_blob(row, column) else { return nil }
        let data = Data(bytes: bytes, count: Int(sqlite3_column_bytes(row, column)))
        // chat.db stores bodies as legacy typedstream archives, which only NSUnarchiver can read.
        return (NSUnarchiver.unarchiveObject(with: data) as? NSAttributedString)?.string
    }

    static func readable(_ text: String?) -> String {
        let cleaned = (text ?? "")
            .replacingOccurrences(of: "\u{FFFC}", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return cleaned.isEmpty ? "Attachment" : cleaned
    }
}
