//
//  PadView.swift
//  Элемент-пэд: Play/Stop, Delete, Rename, прогресс-бар, анимации
//

import SwiftUI

struct PadView: View {
    @EnvironmentObject var audioEngineManager: AudioEngineManager

    let item: SoundPadItem
    let renameAction: (String) -> Void
    let deleteAction: () -> Void

    @State private var isEditingTitle = false
    @State private var tempTitle: String = ""

    @State private var scale: CGFloat = 1.0
    @State private var progress: Double = 0.0
    @State private var timer: Timer?

    // Для hover-эффекта
    @State private var isHovering = false

    var body: some View {
        VStack(spacing: 8) {
            // Заголовок (Editable)
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
                        // двойной клик тоже может включить редактирование
                        startEdit()
                    }
            }

            // Кнопка Edit (если не редактируем)
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

            // Прогресс-бар
            ProgressView(value: progress, total: 1.0)
                .frame(width: 80)

            // Нижняя строка кнопок: [Play/Stop] [Delete]
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
                // Цвет фона с анимацией при hover
                RoundedRectangle(cornerRadius: 12)
                    .fill(isHovering ? Color.gray.opacity(0.2) : Color.gray.opacity(0.1))
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.gray, lineWidth: 2)
            }
        )
        .scaleEffect(scale)
        .animation(.spring(response: 0.3, dampingFraction: 0.5), value: scale)
        .onAppear {
            tempTitle = item.title
            startProgressTimer()
        }
        .onDisappear {
            timer?.invalidate()
        }
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.2)) {
                isHovering = hovering
            }
        }
    }

    private var isPlaying: Bool {
        audioEngineManager.audioPlayers[item.id]?.isPlaying ?? false
    }

    private func playOrStop() {
        // Анимация нажатия
        scale = 1.2
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            scale = 1.0
        }

        if isPlaying {
            audioEngineManager.stopSound(item: item)
        } else {
            audioEngineManager.playSound(item: item)
        }
    }

    private func startEdit() {
        isEditingTitle = true
        tempTitle = item.title
    }

    private func commitEdit() {
        isEditingTitle = false
        // Вызываем renameAction
        renameAction(tempTitle)
    }

    private func startProgressTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            if let player = audioEngineManager.audioPlayers[item.id] {
                let current = player.currentTime
                let total = player.duration
                self.progress = total > 0 ? current / total : 0
                if !player.isPlaying {
                    self.progress = 0
                }
            } else {
                self.progress = 0
            }
        }
    }
}
