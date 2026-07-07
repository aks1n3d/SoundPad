//
//  SoundPadItem.swift
//

import Foundation

struct SoundPadItem: Identifiable, Codable, Equatable {
    let id: UUID
    var title: String
    var url: URL
    // Security-scoped bookmark so the sandboxed app keeps access across relaunches.
    // Optional: sessions saved by older versions have no bookmark (they decode as nil).
    var bookmarkData: Data?

    var volume: Float
    var pan: Float
    var hotkey: String?

    init(title: String, url: URL,
         volume: Float = 1.0,
         pan: Float = 0.0,
         hotkey: String? = nil)
    {
        self.id = UUID()
        self.title = title
        self.url = url
        // Must be created while sandbox access to the URL is live
        // (right after NSOpenPanel / drag & drop).
        self.bookmarkData = try? url.bookmarkData(options: .withSecurityScope,
                                                  includingResourceValuesForKeys: nil,
                                                  relativeTo: nil)
        self.volume = volume
        self.pan = pan
        self.hotkey = hotkey
    }

    /// Resolve the bookmark to a usable URL. Returns the URL plus refreshed
    /// bookmark data when the stored bookmark was stale (caller should persist it).
    /// Falls back to the raw URL for legacy items without a bookmark.
    func resolveURL() -> (url: URL, refreshedBookmark: Data?)? {
        guard let bookmarkData else {
            return (url, nil)
        }
        var isStale = false
        guard let resolved = try? URL(resolvingBookmarkData: bookmarkData,
                                      options: .withSecurityScope,
                                      relativeTo: nil,
                                      bookmarkDataIsStale: &isStale)
        else {
            // Bookmark unusable (file deleted, volume gone) — try the raw URL.
            return (url, nil)
        }
        if isStale {
            // Recreating the bookmark needs live access to the resolved URL.
            let didStart = resolved.startAccessingSecurityScopedResource()
            let refreshed = try? resolved.bookmarkData(options: .withSecurityScope,
                                                       includingResourceValuesForKeys: nil,
                                                       relativeTo: nil)
            if didStart { resolved.stopAccessingSecurityScopedResource() }
            return (resolved, refreshed)
        }
        return (resolved, nil)
    }
}
