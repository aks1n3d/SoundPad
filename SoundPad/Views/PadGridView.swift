//
//  PadGridView.swift
//  Сетка пэдов. Drag & Drop файлов.
//

import SwiftUI

struct PadGridView: View {
    @EnvironmentObject var audioEngineManager: AudioEngineManager
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
                    // Передаём колбэки rename/delete
                    PadView(
                        item: item,
                        renameAction: { newTitle in
                            audioEngineManager.renameItem(item, newTitle: newTitle)
                        },
                        deleteAction: {
                            audioEngineManager.deleteItem(item)
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
        guard let bankIndex = audioEngineManager.banks.firstIndex(where: { $0.id == bank.id }) else { return false }

        for provider in providers {
            provider.loadItem(forTypeIdentifier: kUTTypeFileURL as String, options: nil) { (urlData, error) in
                DispatchQueue.main.async {
                    if let data = urlData as? Data, let fileURL = URL(dataRepresentation: data, relativeTo: nil) {
                        let newItem = SoundPadItem(title: fileURL.lastPathComponent, url: fileURL)
                        audioEngineManager.banks[bankIndex].items.append(newItem)
                    }
                }
            }
        }
        return true
    }
}
