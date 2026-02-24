# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

xit!ed is a native macOS SwiftUI application for editing [x]it! plain-text todo files. The [x]it! format specification is at https://xit.jotaen.net/.

## Git Workflow

- Create a **feature branch** for each change (e.g., `fix/sidebar-selection`)
- Commit with descriptive messages
- Push and create a **Pull Request**
- Merge PR after review/approval
- Delete branch after merge

## Build Commands

Open `XitEditor.xcodeproj` in Xcode and build with ⌘B. Requires macOS 13.0+ and Xcode 15.0+.

## Architecture

The app uses SwiftUI's `DocumentGroup` for native macOS document handling with `.xit` files.

### Data Flow

```
File → XitFileDocument → XitParser.parse() → XitDocument → Views
                                                    ↓
File ← XitFileDocument ← XitDocument.toXitString() ←┘
```

### Key Components

- **XitFileDocument** (`Models/XitFileDocument.swift`): Implements `FileDocument` protocol for file I/O. Registers UTType `net.jotaen.xit`.

- **XitParser** (`Parser/XitParser.swift`): Regex-based parser for the xit format. Handles checkboxes, priorities (`!`), tags (`#tag=value`), due dates (`-> 2024-03-31`), and continuation lines (4-space indent).

- **Domain Models** (`Models/XitItem.swift`):
  - `XitStatus`: Enum with 5 states (open/checked/ongoing/obsolete/inQuestion). Has `next()` for click cycling.
  - `XitItem`: Single todo with status, priority, description, tags, due date
  - `XitGroup`: Collection of items with optional title
  - `XitDocument`: Top-level container of groups

- **Views** (`Views/`):
  - `ContentView`: NavigationSplitView with group sidebar and item detail
  - `ItemListView`: Filtered item list with quick-add field
  - `ItemRow`: Item display with status button, syntax highlighting, badges

### Serialization

All domain models implement `toXitString()` for round-trip serialization back to the xit format.

### Notifications

`Notification.Name.addNewItem` is posted for ⌘T keyboard shortcut to add new tasks.
