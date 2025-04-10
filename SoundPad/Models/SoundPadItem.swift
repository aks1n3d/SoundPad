//
//  SoundPadItem.swift
//

import Foundation

struct SoundPadItem: Identifiable, Codable, Equatable {
    let id: UUID
    var title: String
    var url: URL

    // Громкость, пан, хоткей – что хотите
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
        self.volume = volume
        self.pan = pan
        self.hotkey = hotkey
    }
}
