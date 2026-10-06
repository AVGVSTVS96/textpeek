# TextPeek

Message previews on macOS, but only for people you don't know.

macOS lets you show or hide message previews for every sender at once. TextPeek decides per sender: texts from your contacts stay private, and everything else (verification codes, delivery updates, unknown numbers) shows in full, so you can read a code without opening Messages.

```
contact texts you      ─▶  Alice          New message
unknown number         ─▶  +1 555 0142    Running 10 min late
short code / sender ID ─▶  72975          Your code is 481920
group chat             ─▶  same rules, by sender, with the group as subtitle
```

Clicking a banner opens the conversation in Messages.

## Requirements

- macOS 14+
- Xcode Command Line Tools (`xcode-select --install`)

## Install

Paste this into Claude Code:

```
Set up TextPeek for me: https://github.com/AVGVSTVS96/textpeek. Follow INSTALL.md in that repo.
```

Or by hand:

```sh
git clone https://github.com/AVGVSTVS96/textpeek
cd textpeek
make install
```

Then:

1. Allow the Notifications and Contacts prompts.
2. System Settings → Privacy & Security → Full Disk Access → turn on **TextPeek**, then **Quit & Reopen**.
3. System Settings → Notifications → Messages → turn off **Allow notifications**, so you don't get every text twice.

TextPeek starts at login and has no window or menu bar icon. To stop it, turn it off in System Settings → General → Login Items.

## How it works

```
Messages writes chat.db
  └─▶ TextPeek sees chat.db-wal change (kernel file event, no polling)
        └─▶ reads new incoming messages, read-only
              ├─ sender in Contacts ─▶ name only
              └─ anyone else        ─▶ name or number + full text
```

- Phone numbers match on their last 10 digits, so `(555) 123-4567` and `+1 555-123-4567` are the same person. Edits to Contacts apply right away.
- Short codes and sender IDs always show their text, even if you saved them as a contact.
- If TextPeek can't read your contacts, it hides the text from every personal number instead of showing it.
- It skips your own messages, messages already read on another device, and anything older than two minutes, so an iCloud sync can't flood you with old texts.
- About 250 lines of Swift, no dependencies.

TextPeek is signed locally, not notarized, so macOS asks for Full Disk Access again after each rebuild.

## License

[MIT](LICENSE)
