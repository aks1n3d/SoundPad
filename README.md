# SoundPad

A simple **macOS** application built with **SwiftUI** that allows you to:

- Quickly load and play sound files (MP3, WAV, M4A, etc.)
- Run multiple sounds in parallel through a single `AVAudioEngine`
- Adjust volume and pan per sound, with optional **Fade In/Out**
- Trigger pads with **keyboard hotkeys**
- Rename items, delete them, and organize them in “Banks” (sets)
- Save or load custom sets (projects) of sound files
- Route the app's audio to any output device — **without changing your system default**
- Mix live: volume, pan, mute, and solo per sound
- Use drag & drop to import files
- Keep track of playback progress in real time

Imported sounds are remembered across launches via security-scoped bookmarks,
so the sandboxed app keeps access to your files after a restart.

**Important**: This app **does not record from the microphone**; it only plays
audio files. If you want to feed audio into Discord/Zoom as a “microphone,”
use a virtual audio driver like **BlackHole**, then select that driver as the
Output Device in SoundPad's Preferences and as the Input in your conferencing
software.

## Table of Contents

- [Features](#features)
- [Installation](#installation)
- [Usage](#usage)
- [Preferences](#preferences)
- [Running the Tests](#running-the-tests)
- [Building a Release](#building-a-release)
- [Contributing](#contributing)
- [License](#license)

---

## Features

1. **Multiple Banks**
   Organize your sounds into different “banks” (e.g. “Music,” “SFX,” “Voice Clips”) and switch between them easily.

2. **Parallel Playback**
   Several sounds can play at once, each on its own player node with independent volume and pan.

3. **Add/Rename/Delete**
   - Add files via “Add Audio File” or by **drag & drop** from Finder (non-audio files are rejected).
   - Rename an item by clicking “Edit” or double-clicking its name.
   - Delete an item with the **Delete** button.

4. **Playback Controls**
   - **Play/Stop** per pad, with a live progress bar.
   - Optional **Fade In/Out** for smooth starts and stops.
   - Playing pads light up in your chosen highlight color.

5. **Hotkeys**
   Assign a single key to any pad (in the Mixer window). Pressing it toggles
   that pad while the app is frontmost — except while you're typing in a text
   field. Each key maps to at most one pad per bank.

6. **Mixer**
   Open the **Mixer** window from the toolbar: volume and pan apply live to
   playing sounds; **Mute** silences a sound without stopping it; **Solo**
   silences everything else and restores it when released.

7. **Per-App Output Device**
   Pick an output device in Preferences (e.g. **BlackHole**). Only SoundPad's
   audio is routed there — your system default output is left alone.

8. **Save/Load Projects**
   Save your current bank configuration to a `.json` file via
   **File → Save Project As…** and load it back with **Open Project…**.
   The current session is also auto-saved continuously.

---

## Installation

1. **Install Xcode 16+** (the project targets macOS 15).
2. **Clone** this repository:
   ```bash
   git clone https://github.com/YourUsername/SoundPad.git
   cd SoundPad
   ```
3. **Open the project** in Xcode:
   ```bash
   open SoundPad.xcodeproj
   ```
4. **Build & Run** (`Cmd + R`).

When it starts up:
- The app automatically creates a default “Bank 1.”
- **Add Audio File** to import .mp3, .wav, .m4a, etc.

---

## Usage

1. **Load sounds** — click **Add Audio File**, or drag & drop audio files onto the window.
2. **Play/Stop** — click **Play**; the progress bar tracks playback. Click **Stop** to halt (with a fade-out if enabled).
3. **Edit/Rename** — click **Edit** or double-click the name.
4. **Delete** — removes the pad and releases its file.
5. **Banks** — switch with the segmented control at the top; **New Bank** adds another.
6. **Mixer** — click **Mixer** in the toolbar for volume/pan/mute/solo and hotkey assignment.
7. **Hotkeys** — type a key into the “Key” field of a mixer row; the pad shows a badge with its key.
8. **Projects** — **File → Save Project As…** / **Open Project…** for portable `.json` sets.

---

## Preferences

Open **Settings…** (`Cmd + ,`) to:

- Toggle **Fade In/Out**.
- Pick the **highlight color** used for playing pads.
- Select the **Output Device** for SoundPad's audio (e.g. BlackHole or a
  multi-output device). “System Default” follows whatever macOS is using.

---

## Running the Tests

Unit tests (Swift Testing) cover the data models, session/project persistence,
hotkey assignment, and fade math:

```bash
xcodebuild -project SoundPad.xcodeproj -scheme SoundPad \
  -destination 'platform=macOS' -only-testing:SoundPadTests test
```

---

## Building a Release

1. In Xcode, choose **Any Mac** as the run destination.
2. Go to **Product → Archive**.
3. In the **Organizer**, select your new archive, then click **Distribute App**.
4. You can sign/notarize the `.app` if you have an Apple Developer ID. Otherwise, you can export an unsigned `.app` for personal use or distribution to users who enable Gatekeeper for unidentified developers.

---

## Contributing

Feel free to:

- **Open an issue** if you find bugs or have feature requests.
- **Submit Pull Requests** if you’d like to fix an issue or enhance the code.
- Provide feedback or suggestions for improvement.

---

## License

MIT License

Copyright (c) 2025 Aks1n3d

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
