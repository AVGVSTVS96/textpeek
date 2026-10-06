# TextPeek

A background macOS app that shows message previews only for senders who aren't in Contacts.

- `make app` builds `build/TextPeek.app`; `make install` copies it to `~/Applications` and relaunches it.
- `MessageStore` reads `~/Library/Messages/chat.db` read-only. Message text lives in `text` or, on newer macOS, in the `attributedBody` typedstream.
- `ContactBook` maps phone numbers (last 10 digits) and emails to names. Without Contacts access, every personal sender counts as known, so text stays hidden.
- `TextPeek` watches `chat.db-wal` for writes. No timers.
- Testing needs Full Disk Access, which an agent's shell usually doesn't have. Ask the user to send a real test text.
