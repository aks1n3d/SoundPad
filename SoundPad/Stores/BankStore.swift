//
//  BankStore.swift
//  Banks, selection and persistence. No AppKit panels, no audio —
//  the session directory is injectable so all of this is unit-testable.
//

import Foundation

@MainActor
final class BankStore: ObservableObject {
    @Published var banks: [SoundBank] = []
    @Published var selectedBankIndex: Int = 0

    private let sessionDirectory: URL

    init(sessionDirectory: URL = BankStore.defaultSessionDirectory()) {
        self.sessionDirectory = sessionDirectory
        loadSession()
    }

    static func defaultSessionDirectory() -> URL {
        FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
    }

    var selectedBank: SoundBank? {
        guard banks.indices.contains(selectedBankIndex) else { return nil }
        return banks[selectedBankIndex]
    }

    // MARK: - Bank / item mutations

    func addBank() {
        banks.append(SoundBank(name: "Bank \(banks.count + 1)", items: []))
        selectedBankIndex = banks.count - 1
    }

    /// Append items for the given file URLs to the selected bank.
    /// Bookmarks are created by SoundPadItem's init, so this must be called
    /// while sandbox access to the URLs is live (after a panel or drop).
    func addItems(urls: [URL]) {
        guard banks.indices.contains(selectedBankIndex) else { return }
        for url in urls {
            banks[selectedBankIndex].items.append(
                SoundPadItem(title: url.lastPathComponent, url: url)
            )
        }
    }

    func renameItem(id: UUID, newTitle: String) {
        updateItem(id: id) { $0.title = newTitle }
    }

    func deleteItem(id: UUID) {
        guard let (bankIndex, itemIndex) = locate(id) else { return }
        banks[bankIndex].items.remove(at: itemIndex)
    }

    func updateItem(id: UUID, mutate: (inout SoundPadItem) -> Void) {
        guard let (bankIndex, itemIndex) = locate(id) else { return }
        mutate(&banks[bankIndex].items[itemIndex])
    }

    func item(id: UUID) -> SoundPadItem? {
        guard let (bankIndex, itemIndex) = locate(id) else { return nil }
        return banks[bankIndex].items[itemIndex]
    }

    /// Persist refreshed bookmark data produced by a stale-bookmark resolution.
    func refreshBookmark(for id: UUID, data: Data) {
        updateItem(id: id) { $0.bookmarkData = data }
    }

    // MARK: - Hotkeys

    /// Find the item in the *selected* bank bound to the given key.
    func item(withHotkey key: String) -> SoundPadItem? {
        selectedBank?.items.first { $0.hotkey?.lowercased() == key.lowercased() }
    }

    /// Assign a hotkey to an item, clearing it from any other item in the
    /// same bank so a key never triggers two pads. Pass nil to unbind.
    func assignHotkey(_ key: String?, to id: UUID) {
        guard let (bankIndex, _) = locate(id) else { return }
        let normalized = key?.lowercased()
        if let normalized {
            for index in banks[bankIndex].items.indices
            where banks[bankIndex].items[index].hotkey?.lowercased() == normalized
                && banks[bankIndex].items[index].id != id
            {
                banks[bankIndex].items[index].hotkey = nil
            }
        }
        updateItem(id: id) { $0.hotkey = normalized }
    }

    private func locate(_ id: UUID) -> (bankIndex: Int, itemIndex: Int)? {
        for (bankIndex, bank) in banks.enumerated() {
            if let itemIndex = bank.items.firstIndex(where: { $0.id == id }) {
                return (bankIndex, itemIndex)
            }
        }
        return nil
    }

    // MARK: - Session persistence (automatic)

    private var sessionFileURL: URL {
        sessionDirectory.appendingPathComponent("DefaultSession.json")
    }

    func loadSession() {
        let url = sessionFileURL
        if FileManager.default.fileExists(atPath: url.path),
           let data = try? Data(contentsOf: url),
           let decoded = try? JSONDecoder().decode([SoundBank].self, from: data),
           !decoded.isEmpty
        {
            banks = decoded
        } else {
            banks = [SoundBank(name: "Bank 1", items: [])]
        }
        selectedBankIndex = 0
    }

    func saveSession() throws {
        try FileManager.default.createDirectory(at: sessionDirectory,
                                                withIntermediateDirectories: true)
        let data = try JSONEncoder().encode(banks)
        try data.write(to: sessionFileURL)
    }

    // MARK: - Project files (explicit save/open; panels live in SoundPadApp)

    func saveProject(to url: URL) throws {
        let data = try JSONEncoder().encode(banks)
        try data.write(to: url)
    }

    func openProject(from url: URL) throws {
        let data = try Data(contentsOf: url)
        let decoded = try JSONDecoder().decode([SoundBank].self, from: data)
        banks = decoded.isEmpty ? [SoundBank(name: "Bank 1", items: [])] : decoded
        selectedBankIndex = 0
    }
}
