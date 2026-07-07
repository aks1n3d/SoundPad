//
//  PadGridView.swift
//  Pad grid with drag & drop import of audio files.
//

import SwiftUI
import UniformTypeIdentifiers

struct PadGridView: View {
    @EnvironmentObject var bankStore: BankStore
    @EnvironmentObject var playbackEngine: PlaybackEngine
    var bank: SoundBank

    let columns = [
        GridItem(.adaptive(minimum: 150, maximum: 180), spacing: 18),
    ]

    var body: some View {
        Group {
            if bank.items.isEmpty {
                emptyState
            } else {
                ScrollView {
                    LazyVGrid(columns: columns, spacing: 18) {
                        ForEach(bank.items) { item in
                            PadView(
                                item: item,
                                renameAction: { newTitle in
                                    bankStore.renameItem(id: item.id, newTitle: newTitle)
                                },
                                deleteAction: {
                                    playbackEngine.unload(itemID: item.id)
                                    bankStore.deleteItem(id: item.id)
                                }
                            )
                        }
                    }
                    .padding()
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onDrop(of: [.fileURL], isTargeted: nil) { providers in
            handleDrop(providers: providers)
        }
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "music.note.list")
                .font(.system(size: 46))
                .foregroundStyle(Theme.textSecondary)
            Text("No sounds in this bank")
                .font(.title3.weight(.semibold))
                .foregroundStyle(.white)
            Text("Click ⊕ in the toolbar or drop audio files here")
                .font(.callout)
                .foregroundStyle(Theme.textSecondary)
        }
    }

    private func handleDrop(providers: [NSItemProvider]) -> Bool {
        var accepted = false
        for provider in providers where provider.hasItemConformingToTypeIdentifier(UTType.fileURL.identifier) {
            accepted = true
            _ = provider.loadDataRepresentation(for: .fileURL) { data, _ in
                guard let data,
                      let fileURL = URL(dataRepresentation: data, relativeTo: nil)
                else { return }
                // Only reject files positively identified as non-audio;
                // unknown or missing extensions get the benefit of the doubt
                // (playback reports unreadable files at play time).
                if let type = UTType(filenameExtension: fileURL.pathExtension),
                   !type.conforms(to: .audio) {
                    return
                }
                Task { @MainActor in
                    // Dropped URLs can arrive security-scoped; hold access while
                    // the bookmark is created inside addItems.
                    let hasScope = fileURL.startAccessingSecurityScopedResource()
                    bankStore.addItems(urls: [fileURL])
                    if hasScope { fileURL.stopAccessingSecurityScopedResource() }
                }
            }
        }
        return accepted
    }
}
