# xit-editor

A native macOS editor for [x]it! plain-text todo files.

## What is [x]it!?

[x]it! is a plain-text file format for todos and check lists. See the [specification](https://xit.jotaen.net/).

## Features (MVP)

- [x] Open and save `.xit` files
- [x] Syntax highlighting for checkboxes, priorities, tags, and due dates
- [x] Toggle checkbox status with click
- [x] Add new items
- [x] Group support with titles

## Status Legend

| Checkbox | Status |
|----------|--------|
| `[ ]` | Open |
| `[x]` | Checked/Done |
| `[@]` | Ongoing |
| `[~]` | Obsolete |
| `[?]` | In Question |

## Requirements

- macOS 13.0+
- Xcode 15.0+

## Building

Open `XitEditor.xcodeproj` in Xcode and build (⌘B).

## License

MIT
