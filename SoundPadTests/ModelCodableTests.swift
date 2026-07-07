//
//  ModelCodableTests.swift
//  Codable round-trips and backward compatibility with sessions saved by
//  older app versions (which had no bookmarkData field).
//

import Foundation
import Testing
@testable import SoundPad

struct ModelCodableTests {

    @Test func soundPadItemRoundTripPreservesAllFields() throws {
        var item = SoundPadItem(title: "Kick",
                                url: URL(fileURLWithPath: "/tmp/kick.wav"),
                                volume: 0.7,
                                pan: -0.25,
                                hotkey: "k")
        // Bookmark creation fails for a nonexistent path; use stand-in data
        // (the codable path doesn't care what the bytes are).
        item.bookmarkData = Data([1, 2, 3, 4])

        let data = try JSONEncoder().encode(item)
        let decoded = try JSONDecoder().decode(SoundPadItem.self, from: data)

        #expect(decoded == item)
        #expect(decoded.bookmarkData == Data([1, 2, 3, 4]))
        #expect(decoded.hotkey == "k")
    }

    @Test func legacySessionJSONWithoutBookmarkDecodes() throws {
        // Exactly the shape the pre-bookmark app wrote (no bookmarkData, no hotkey).
        let legacyJSON = """
        [
          {
            "id": "9A0DA168-6E9C-4BA0-9E51-C0A2E1DBD803",
            "name": "Bank 1",
            "items": [
              {
                "id": "5B7B7B54-4E8B-4E0D-8F2B-2C3D4E5F6A7B",
                "title": "airhorn.mp3",
                "url": "file:///Users/denys/Music/airhorn.mp3",
                "volume": 0.5,
                "pan": 0
              }
            ]
          }
        ]
        """
        let banks = try JSONDecoder().decode([SoundBank].self,
                                             from: Data(legacyJSON.utf8))

        #expect(banks.count == 1)
        #expect(banks[0].name == "Bank 1")
        let item = try #require(banks[0].items.first)
        #expect(item.title == "airhorn.mp3")
        #expect(item.volume == 0.5)
        #expect(item.bookmarkData == nil)
        #expect(item.hotkey == nil)
    }

    @Test func soundBankArrayRoundTrip() throws {
        let banks = [
            SoundBank(name: "Music", items: [
                SoundPadItem(title: "A", url: URL(fileURLWithPath: "/tmp/a.mp3")),
                SoundPadItem(title: "B", url: URL(fileURLWithPath: "/tmp/b.mp3"), volume: 0.2),
            ]),
            SoundBank(name: "SFX", items: []),
        ]

        let data = try JSONEncoder().encode(banks)
        let decoded = try JSONDecoder().decode([SoundBank].self, from: data)

        #expect(decoded == banks)
    }

    @Test func resolveURLFallsBackToRawURLWithoutBookmark() throws {
        var item = SoundPadItem(title: "X", url: URL(fileURLWithPath: "/tmp/x.wav"))
        item.bookmarkData = nil

        let resolved = try #require(item.resolveURL())
        #expect(resolved.url == item.url)
        #expect(resolved.refreshedBookmark == nil)
    }
}
