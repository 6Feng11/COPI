# Copy Local Clipboard Tool Design

## Product Positioning

Copy is a lightweight Mac clipboard history utility. It records everything the user copies on the device, keeps all history local, and helps the user quickly find and reuse previously copied text, links, and images.

The first version is a pure local tool:

- No account system.
- No cloud sync.
- No upload or remote analysis.
- No server dependency.
- All clipboard data is stored on the user's Mac.

## Target User

The primary user is a Mac user who frequently switches between chat, browser, documents, design tools, and development tools, and wants to recover copied content without manually keeping notes.

The tool should feel quiet and utilitarian. It should stay out of the way until the user needs clipboard history.

## MVP Scope

The MVP should do five things well:

1. Record copied text, links, and images.
2. Store all records locally.
3. Open a compact history panel with a global shortcut.
4. Search and preview clipboard history.
5. Copy a selected history item back to the system clipboard.

## Non-Goals For Version 1

The first version will not include:

- iCloud sync.
- Cross-device sync.
- User accounts.
- OCR for image text.
- AI classification.
- Shared clipboard history.
- Team features.
- Browser extensions.
- Automatic sensitive-content filtering.

These are intentionally excluded so the product remains a reliable local utility first.

## Core Interaction Model

Copy runs as a menu bar app.

The menu bar menu includes:

- Open Clipboard History.
- Pause Recording.
- Clear All History.
- Settings.
- Quit.

The user can also press a global shortcut to open the clipboard history panel. The recommended default shortcut is `Command + Shift + V`, with a setting to change it if there is a conflict.

The history panel contains:

- A search field at the top.
- A scrollable history list.
- A preview area or inline preview depending on available space.
- Keyboard support for moving through results and copying the selected item.

The primary flow is:

1. User copies content in any app.
2. Copy detects the pasteboard change.
3. Copy stores a normalized local record.
4. User presses the global shortcut.
5. User searches or navigates recent records.
6. User presses Enter or clicks a record.
7. Copy writes that item back to the system clipboard.

## Clipboard Content Types

### Text

Plain text should be stored directly in the local database. The list preview should show the first useful line and a short body excerpt.

### Links

URLs should be detected from copied text. They should still be stored as text, but displayed with a link type indicator. Version 1 can use the URL itself as the title. Fetching web page titles is not required.

### Images

Images should be stored as local files in the app support directory. The database should store metadata and file paths rather than binary image data.

The list should show a thumbnail preview and basic metadata such as image dimensions when available.

## Local Storage

Recommended storage location:

```text
~/Library/Application Support/Copy/
```

Recommended internal layout:

```text
Copy/
  copy.sqlite
  Images/
    original/
    thumbnails/
```

The SQLite database stores structured metadata. Image files are stored separately.

Suggested record fields:

```text
id
type
preview
plainText
url
imagePath
thumbnailPath
sourceAppBundleId
sourceAppName
contentHash
createdAt
lastUsedAt
useCount
isFavorite
```

## Deduplication

Copy should avoid storing repeated identical entries when the same content is copied multiple times in a short period.

Version 1 deduplication rule:

- Generate a content hash from the normalized content.
- If the newest record has the same hash, update its timestamp instead of inserting a duplicate.
- If an older non-adjacent record has the same hash, update that existing record, move it to the top of the history list, and increment its use count instead of inserting a new duplicate.

## Privacy And Trust Model

Copy records all clipboard content by default because it is positioned as a pure local utility.

Trust boundaries:

- Clipboard history remains on the user's Mac.
- The app does not upload clipboard content.
- The app does not require login.
- The app does not send analytics containing clipboard content.

User controls:

- Pause recording.
- Delete one record.
- Clear all history.
- Limit retained history count.
- Quit the app.

Recommended settings:

- Retain latest 500 items.
- Retain latest 1000 items.
- Retain forever.
- Clear image cache together with history.

## Settings

Version 1 settings should include:

- Global shortcut.
- Maximum history count.
- Launch at login.
- Pause recording state.
- Clear all history.

Advanced app exclusion rules can be added later, but are not required for the MVP.

## Architecture

### ClipboardMonitor

Observes the macOS pasteboard change count and extracts supported content types.

Responsibilities:

- Poll or observe pasteboard changes.
- Ignore changes written by Copy itself when restoring history items.
- Normalize detected content.
- Send new items to the store.

### ClipboardStore

Persists and queries clipboard history.

Responsibilities:

- Insert or update records.
- Manage deduplication.
- Search records.
- Delete records.
- Enforce retention limits.

### ImageStore

Stores image originals and thumbnails on disk.

Responsibilities:

- Save copied images.
- Generate thumbnails.
- Delete image files when records are deleted.
- Keep database paths and files consistent.

### HistoryPanel

Provides the main user interface for searching and reusing clipboard items.

Responsibilities:

- Show recent records.
- Search text and link records.
- Show image thumbnails.
- Support keyboard navigation.
- Restore selected record to the pasteboard.

### MenuBarController

Owns menu bar interactions.

Responsibilities:

- Show app status.
- Open the history panel.
- Pause or resume recording.
- Clear all history.
- Quit the app.

### PasteboardWriter

Writes selected history items back to the system clipboard.

Responsibilities:

- Restore text, links, and images with the right pasteboard types.
- Mark self-originated pasteboard changes so ClipboardMonitor does not immediately duplicate them.

## Error Handling

Clipboard read failures should fail silently and avoid interrupting the user.

Storage failures should be visible only when they affect core behavior. For example, if the database cannot be opened, the app should show a simple error and avoid pretending history is being saved.

Image write failures should still allow text and link history to continue working.

When clearing history, the app should delete both database records and image files.

## Testing Strategy

Unit tests:

- Text normalization.
- URL detection.
- Content hashing.
- Deduplication behavior.
- Retention limit behavior.

Integration tests:

- Insert and query text records.
- Insert image metadata and delete associated files.
- Restore text to the pasteboard.
- Confirm self-originated pasteboard writes do not create duplicate records.

Manual QA:

- Copy text from Notes, browser, chat, and code editor.
- Copy links from browser address bar and page content.
- Copy images from browser and Finder.
- Open history with global shortcut.
- Search history.
- Restore records and paste into another app.
- Pause recording and verify new copies are not recorded.
- Clear history and verify image files are removed.

## Initial Milestones

### Milestone 1: Local Text Clipboard History

- Menu bar app shell.
- Pasteboard monitor.
- Local SQLite store.
- Text record capture.
- Basic history panel.
- Restore text to pasteboard.

### Milestone 2: Links And Search

- URL detection.
- Search field.
- Better record previews.
- Keyboard navigation.
- Deduplication.

### Milestone 3: Image History

- Image extraction.
- Local image file storage.
- Thumbnail generation.
- Image list preview.
- Restore image to pasteboard.

### Milestone 4: Settings And Controls

- Global shortcut customization.
- Launch at login.
- Pause recording.
- Delete single record.
- Clear all history.
- History retention limit.

## Recommended First Implementation Stack

- Swift.
- SwiftUI.
- AppKit for menu bar, pasteboard, and global shortcut behavior where needed.
- SQLite for metadata.
- Local file storage for images.

This stack gives the app a native Mac feel and avoids unnecessary runtime dependencies.

## Open Product Decisions

The following decisions can wait until implementation planning:

- Exact app name and icon.
- Exact default shortcut if `Command + Shift + V` conflicts.
- Whether the history panel should be a floating panel, popover, or small window.
- Whether favorites are included in Version 1 or reserved for Version 2.
