//
//  PadView.swift
//  One pad: big play button, rename, delete, progress, hotkey badge.
//  Playback state and progress come from PlaybackEngine (no local timers).
//

import SwiftUI

struct PadView: View {
    @EnvironmentObject var playbackEngine: PlaybackEngine

    let item: SoundPadItem
    let renameAction: (String) -> Void
    let deleteAction: () -> Void

    @AppStorage("highlightColor") private var highlightColorHex: String = Theme.defaultHighlightHex

    @State private var isEditingTitle = false
    @State private var tempTitle: String = ""
    @State private var isHovering = false

    private var isPlaying: Bool {
        playbackEngine.isPlaying(item.id)
    }

    private var progress: Double {
        playbackEngine.progress[item.id] ?? 0
    }

    private var highlight: Color {
        Theme.highlight(fromHex: highlightColorHex)
    }

    var body: some View {
        VStack(spacing: 8) {
            titleView
                .frame(height: 34)

            Spacer(minLength: 0)

            playButton

            Spacer(minLength: 0)

            progressBar
        }
        .padding(14)
        .frame(width: 150, height: 150)
        .background(cardBackground)
        .overlay(alignment: .topTrailing) {
            if let hotkey = item.hotkey {
                Text(hotkey.uppercased())
                    .font(.caption2.bold())
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Capsule().fill(highlight.opacity(0.85)))
                    .foregroundStyle(.black)
                    .padding(8)
            }
        }
        .overlay(alignment: .topLeading) {
            if isHovering && !isEditingTitle {
                Button(action: deleteAction) {
                    Image(systemName: "trash")
                        .font(.caption)
                        .foregroundStyle(Theme.textSecondary)
                        .frame(width: 22, height: 22)
                        .background(Circle().fill(Theme.controlFill))
                }
                .buttonStyle(.plain)
                .help("Delete")
                .padding(6)
            }
        }
        .scaleEffect(isHovering ? 1.03 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isHovering)
        .animation(.easeInOut(duration: 0.2), value: isPlaying)
        .onAppear {
            tempTitle = item.title
        }
        .onHover { hovering in
            isHovering = hovering
        }
    }

    private var titleView: some View {
        Group {
            if isEditingTitle {
                TextField("", text: $tempTitle)
                    .textFieldStyle(PlainTextFieldStyle())
                    .multilineTextAlignment(.center)
                    .font(.headline)
                    .onSubmit {
                        commitEdit()
                    }
            } else {
                Text(item.title)
                    .font(.headline)
                    .foregroundStyle(.white)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                    .help("Double-click to rename")
                    .onTapGesture(count: 2) {
                        startEdit()
                    }
            }
        }
    }

    private var playButton: some View {
        Button(action: { playbackEngine.toggle(item: item) }) {
            ZStack {
                Circle()
                    .fill(isPlaying ? highlight : Color.white.opacity(0.12))
                    .frame(width: 52, height: 52)
                Image(systemName: isPlaying ? "stop.fill" : "play.fill")
                    .font(.system(size: 19, weight: .bold))
                    .foregroundStyle(isPlaying ? Color.black.opacity(0.85) : .white)
                    .offset(x: isPlaying ? 0 : 1.5)
            }
        }
        .buttonStyle(.plain)
        .help(isPlaying ? "Stop" : "Play")
    }

    private var progressBar: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color.white.opacity(0.10))
                Capsule()
                    .fill(highlight)
                    .frame(width: max(4, geo.size.width * progress))
                    .opacity(isPlaying ? 1 : 0)
            }
        }
        .frame(height: 4)
    }

    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: 16)
            .fill(Theme.card)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(
                        isPlaying ? highlight.opacity(0.9)
                            : (isHovering ? Theme.cardBorderHover : Theme.cardBorder),
                        lineWidth: isPlaying ? 2 : 1
                    )
            )
            .shadow(color: isPlaying ? highlight.opacity(0.35) : Color.black.opacity(0.35),
                    radius: isPlaying ? 12 : 6, y: 3)
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
