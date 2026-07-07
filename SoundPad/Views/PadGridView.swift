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
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible()),
    ]

    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 20) {
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
        .onDrop(of: [.fileURL], isTargeted: nil) { providers in
            handleDrop(providers: providers)
        }
    }

    private func handleDrop(providers: [NSItemProvider]) -> Bool {
        var accepted = false
        for provider in providers where provider.hasItemConformingToTypeIdentifier(UTType.fileURL.identifier) {
            accepted = true
            _ = provider.loadDataRepresentation(for: .fileURL) { data, _ in
                guard let data,
                      let fileURL = URL(dataRepresentation: data, relativeTo: nil),
                      let type = UTType(filenameExtension: fileURL.pathExtension),
                      type.conforms(to: .audio)
                else { return }
                DispatchQueue.main.async {
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
