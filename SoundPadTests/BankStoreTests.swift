//
//  BankStoreTests.swift
//  BankStore logic and persistence, using a throwaway directory per test.
//

import Foundation
import Testing
@testable import SoundPad

@MainActor
struct BankStoreTests {

    private func makeTempDirectory() -> URL {
        FileManager.default.temporaryDirectory
            .appendingPathComponent("SoundPadTests-\(UUID().uuidString)")
    }

    private func makeItemURL(_ name: String) -> URL {
        URL(fileURLWithPath: "/tmp/\(name)")
    }

    // MARK: - Fresh state

    @Test func freshStoreStartsWithOneEmptyBank() {
        let store = BankStore(sessionDirectory: makeTempDirectory())
        #expect(store.banks.count == 1)
        #expect(store.banks[0].name == "Bank 1")
        #expect(store.banks[0].items.isEmpty)
        #expect(store.selectedBankIndex == 0)
    }

    // MARK: - Bank / item operations

    @Test func addBankNamesAndSelectsIt() {
        let store = BankStore(sessionDirectory: makeTempDirectory())
        store.addBank()
        #expect(store.banks.count == 2)
        #expect(store.banks[1].name == "Bank 2")
        #expect(store.selectedBankIndex == 1)
        #expect(store.selectedBank?.name == "Bank 2")
    }

    @Test func deleteBankRemovesItAndClampsSelection() {
        let store = BankStore(sessionDirectory: makeTempDirectory())
        store.addBank()
        store.addBank() // three banks, "Bank 3" selected
        #expect(store.selectedBankIndex == 2)

        store.deleteBank(at: 2)

        #expect(store.banks.map(\.name) == ["Bank 1", "Bank 2"])
        #expect(store.selectedBankIndex == 1)
        #expect(store.selectedBank?.name == "Bank 2")
    }

    @Test func deleteMiddleBankKeepsOthersIntact() {
        let store = BankStore(sessionDirectory: makeTempDirectory())
        store.addItems(urls: [makeItemURL("a.mp3")])
        store.addBank()
        store.addBank()
        store.selectedBankIndex = 0

        store.deleteBank(at: 1)

        #expect(store.banks.map(\.name) == ["Bank 1", "Bank 3"])
        #expect(store.selectedBankIndex == 0)
        #expect(store.banks[0].items.count == 1)
    }

    @Test func deletingLastBankLeavesFreshEmptyBank() {
        let store = BankStore(sessionDirectory: makeTempDirectory())
        store.addItems(urls: [makeItemURL("a.mp3")])

        store.deleteBank(at: 0)

        #expect(store.banks.count == 1)
        #expect(store.banks[0].name == "Bank 1")
        #expect(store.banks[0].items.isEmpty)
        #expect(store.selectedBankIndex == 0)
    }

    @Test func deleteBankIgnoresInvalidIndex() {
        let store = BankStore(sessionDirectory: makeTempDirectory())
        store.deleteBank(at: 5)
        #expect(store.banks.count == 1)
    }

    @Test func addItemsAppendsToSelectedBank() {
        let store = BankStore(sessionDirectory: makeTempDirectory())
        store.addBank()
        store.addItems(urls: [makeItemURL("a.mp3"), makeItemURL("b.wav")])

        #expect(store.banks[0].items.isEmpty)
        #expect(store.banks[1].items.map(\.title) == ["a.mp3", "b.wav"])
    }

    @Test func renameAndDeleteItem() {
        let store = BankStore(sessionDirectory: makeTempDirectory())
        store.addItems(urls: [makeItemURL("a.mp3"), makeItemURL("b.mp3")])
        let first = store.banks[0].items[0]

        store.renameItem(id: first.id, newTitle: "Airhorn")
        #expect(store.item(id: first.id)?.title == "Airhorn")

        store.deleteItem(id: first.id)
        #expect(store.banks[0].items.map(\.title) == ["b.mp3"])
        #expect(store.item(id: first.id) == nil)
    }

    @Test func updateItemChangesVolumeAndPan() {
        let store = BankStore(sessionDirectory: makeTempDirectory())
        store.addItems(urls: [makeItemURL("a.mp3")])
        let id = store.banks[0].items[0].id

        store.updateItem(id: id) {
            $0.volume = 0.3
            $0.pan = 0.5
        }

        #expect(store.item(id: id)?.volume == 0.3)
        #expect(store.item(id: id)?.pan == 0.5)
    }

    @Test func refreshBookmarkPersistsData() {
        let store = BankStore(sessionDirectory: makeTempDirectory())
        store.addItems(urls: [makeItemURL("a.mp3")])
        let id = store.banks[0].items[0].id

        store.refreshBookmark(for: id, data: Data([9, 9, 9]))
        #expect(store.item(id: id)?.bookmarkData == Data([9, 9, 9]))
    }

    // MARK: - Hotkeys

    @Test func hotkeyLookupIsScopedToSelectedBank() {
        let store = BankStore(sessionDirectory: makeTempDirectory())
        store.addItems(urls: [makeItemURL("a.mp3")])
        let idInBank1 = store.banks[0].items[0].id
        store.assignHotkey("q", to: idInBank1)

        #expect(store.item(withHotkey: "q")?.id == idInBank1)
        #expect(store.item(withHotkey: "Q")?.id == idInBank1)

        store.addBank()
        #expect(store.item(withHotkey: "q") == nil)
    }

    @Test func assigningHotkeyClearsPreviousHolderInSameBank() {
        let store = BankStore(sessionDirectory: makeTempDirectory())
        store.addItems(urls: [makeItemURL("a.mp3"), makeItemURL("b.mp3")])
        let a = store.banks[0].items[0].id
        let b = store.banks[0].items[1].id

        store.assignHotkey("1", to: a)
        store.assignHotkey("1", to: b)

        #expect(store.item(id: a)?.hotkey == nil)
        #expect(store.item(id: b)?.hotkey == "1")
        #expect(store.item(withHotkey: "1")?.id == b)
    }

    @Test func nilHotkeyUnbinds() {
        let store = BankStore(sessionDirectory: makeTempDirectory())
        store.addItems(urls: [makeItemURL("a.mp3")])
        let id = store.banks[0].items[0].id

        store.assignHotkey("z", to: id)
        store.assignHotkey(nil, to: id)

        #expect(store.item(id: id)?.hotkey == nil)
        #expect(store.item(withHotkey: "z") == nil)
    }

    // MARK: - Session persistence

    @Test func sessionRoundTripAcrossStoreInstances() throws {
        let directory = makeTempDirectory()

        let store = BankStore(sessionDirectory: directory)
        store.addItems(urls: [makeItemURL("kick.wav")])
        store.addBank()
        store.addItems(urls: [makeItemURL("snare.wav")])
        try store.saveSession()

        let reloaded = BankStore(sessionDirectory: directory)
        #expect(reloaded.banks == store.banks)
        #expect(reloaded.selectedBankIndex == 0)
    }

    @Test func corruptSessionFileFallsBackToEmptyBank() throws {
        let directory = makeTempDirectory()
        try FileManager.default.createDirectory(at: directory,
                                                withIntermediateDirectories: true)
        try Data("not json at all {{{".utf8)
            .write(to: directory.appendingPathComponent("DefaultSession.json"))

        let store = BankStore(sessionDirectory: directory)
        #expect(store.banks.count == 1)
        #expect(store.banks[0].name == "Bank 1")
        #expect(store.banks[0].items.isEmpty)
    }

    // MARK: - Project files

    @Test func projectSaveOpenRoundTripAndSelectionReset() throws {
        let store = BankStore(sessionDirectory: makeTempDirectory())
        store.addItems(urls: [makeItemURL("a.mp3")])
        store.addBank()
        let savedBanks = store.banks
        #expect(store.selectedBankIndex == 1)

        let projectURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("SoundPadTests-project-\(UUID().uuidString).json")
        try store.saveProject(to: projectURL)
        defer { try? FileManager.default.removeItem(at: projectURL) }

        let other = BankStore(sessionDirectory: makeTempDirectory())
        try other.openProject(from: projectURL)

        #expect(other.banks == savedBanks)
        #expect(other.selectedBankIndex == 0)
    }

    @Test func openingEmptyProjectYieldsDefaultBank() throws {
        let projectURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("SoundPadTests-empty-\(UUID().uuidString).json")
        try Data("[]".utf8).write(to: projectURL)
        defer { try? FileManager.default.removeItem(at: projectURL) }

        let store = BankStore(sessionDirectory: makeTempDirectory())
        try store.openProject(from: projectURL)

        #expect(store.banks.count == 1)
        #expect(store.banks[0].name == "Bank 1")
    }
}
