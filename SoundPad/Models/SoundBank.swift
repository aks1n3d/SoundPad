//
//  SoundBank.swift
//

import Foundation

struct SoundBank: Identifiable, Codable, Equatable {
    let id: UUID
    var name: String
    var items: [SoundPadItem]

    init(name: String, items: [SoundPadItem]) {
        self.id = UUID()
        self.name = name
        self.items = items
    }
}
