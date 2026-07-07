//
//  PadView.swift
//  One pad: Play/Stop, Delete, Rename, progress, hotkey badge.
//  Playback state and progress come from PlaybackEngine (no local timers).
//

import SwiftUI

struct PadView: View {
    @EnvironmentObject var playbackEngine: PlaybackEngine

    let item: SoundPadItem
    let renameAction: (String) -> Void
    let deleteAction: () -> Void

    @AppStorage("highlightColor") private var highlightColorHex: String = "#FFD700"

    @State private var isEditingTitle = false
    @State private var tempTitle: String = ""
    @State private var scale: CGFloat = 1.0
    @State private var isHovering = false

    private var isPlaying: Bool {
        playbackEngine.isPlaying(item.id)
    }

    private var progress: Double {
        playbackEngine.progress[item.id] ?? 0
    }

    private var highlightColor: Color {
        Color(hex: highlightColorHex) ?? .yellow
    }

    var body: some View {
        VStack(spacing: 8) {
            if isEditingTitle {
                TextField("", text: $tempTitle)
                    .textFieldStyle(PlainTextFieldStyle())
                    .frame(maxWidth: 100)
                    .multilineTextAlignment(.center)
                    .onSubmit {
                        commitEdit()
                    }
            } else {
                Text(item.title)
                    .font(.headline)
                    .multilineTextAlignment(.center)
                    .onTapGesture(count: 2) {
                        startEdit()
                    }
            }

            if !isEditingTitle {
                Button("Edit") {
                    startEdit()
                }
                .buttonStyle(LinkButtonStyle())
                .font(.caption2)
            } else {
                Button("Done") {
                    commitEdit()
                }
                .font(.caption2)
            }

            ProgressView(value: progress, total: 1.0)
                .frame(width: 80)

            HStack(spacing: 10) {
                Button(action: playOrStop) {
                    Text(isPlaying ? "Stop" : "Play")
                }

                Button("Delete", role: .destructive) {
                    deleteAction()
                }
            }
            .padding(.top, 4)
        }
        .padding(8)
        .frame(width: 140, height: 160)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(backgroundFill)
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isPlaying ? highlightColor : Color.gray, lineWidth: 2)
            }
        )
        .overlay(alignment: .topTrailing) {
            if let hotkey = item.hotkey {
                Text(hotkey.uppercased())
                    .font(.caption2.bold())
                    .padding(.horizontal, 5)
                    .padding(.vertical, 2)
                    .background(Capsule().fill(highlightColor.opacity(0.8)))
                    .foregroundStyle(.black)
                    .padding(6)
            }
        }
        .scaleEffect(scale)
        .animation(.spring(response: 0.3, dampingFraction: 0.5), value: scale)
        .onAppear {
            tempTitle = item.title
        }
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.2)) {
                isHovering = hovering
            }
        }
    }

    private var backgroundFill: Color {
        if isPlaying {
            return highlightColor.opacity(0.25)
        }
        return isHovering ? Color.gray.opacity(0.2) : Color.gray.opacity(0.1)
    }

    private func playOrStop() {
        scale = 1.2
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            scale = 1.0
        }
        playbackEngine.toggle(item: item)
    }

    private func startEdit() {
        isEditingTitle = true
        tempTitle = item.title
    }

    private func commitEdit() {
        isEditingTitle = false
        renameAction(tempTitle)
    }
}
