# SoundPad

A simple **macOS** application built with **SwiftUI** that allows you to:

- Quickly load and play sound files (MP3, WAV, M4A, etc.)  
- Run multiple sounds in parallel  
- Adjust volume and optionally apply **Fade In/Out** on playback  
- Rename items, delete them, and organize them in “Banks” (sets)  
- Save or load custom sets (projects) of sound files  
- Choose your audio output device from within the app (via Core Audio)  
- Optionally manage mixing settings (mute, solo, volume, and pan)  
- Use drag & drop to import files  
- Keep track of playback progress in real time  

**Important**: This app **does not record from the microphone**; it only plays audio files. If you want to feed audio into Discord/Zoom as a “microphone,” use a virtual audio driver like **BlackHole**, then select that driver as Output in SoundPad and Input in your conferencing software.

## Table of Contents

- [Features](#features)  
- [Screenshots](#screenshots)  
- [Installation](#installation)  
- [Usage](#usage)  
- [Preferences](#preferences)  
- [Building a Release](#building-a-release)  
- [Contributing](#contributing)  
- [License](#license)

---

## Features

1. **Multiple Banks**  
   Organize your sounds into different “banks” (e.g. “Music,” “SFX,” “Voice Clips”) and switch between them easily.

2. **Parallel Playback**  
   Several sounds can play at once. Each has its own volume control.

3. **Add/Rename/Delete**  
   - Quickly add files via an “Open File” dialog or by **drag & drop** from Finder.  
   - Rename an item by clicking “Edit” or double-clicking on its name.  
   - Delete an item with the **Delete** button.

4. **Playback Controls**  
   - **Play/Stop** buttons for each sound.  
   - Optional **Fade In/Out** for smoother transitions.

5. **Mixer**  
   - A separate **Mixer** view to adjust volume, pan, mute, or solo for each sound.

6. **Choose Output Device**  
   - A built-in Preferences panel that lets you pick your audio device, so you can direct audio to **BlackHole** or any other device.

7. **Save/Load Projects**  
   - Save your current bank configurations (lists of sounds) to a `.json` file and load them later.

8. **macOS 12+** Support  
   - Uses SwiftUI and the modern Uniform Type Identifiers (UTI) for file handling.  
   - On macOS 14 or newer, we use the recommended `.onChange` and `UTType.fileURL` APIs.

---

## Installation

1. **Install Xcode** (version 13 or higher, recommended macOS 12+).  
2. **Clone** this repository:
   ```bash
   git clone https://github.com/YourUsername/SoundPad.git
   cd SoundPad
   ```
3. **Open the project** in Xcode:
   ```bash
   open SoundPad.xcodeproj
   ```
4. **Build & Run** (select `Product` → `Build`, then `Product` → `Run` or press `Cmd + R`).  

When it starts up:
- The app automatically creates a default “Bank 1.”  
- **Add Audio File** to import .mp3, .wav, .m4a, etc.

---

## Usage

1. **Load sounds**  
   - Click **Add Audio File** and choose your audio files, or just **drag & drop** them onto the app window.  
2. **Play/Stop**  
   - Click the **Play** button to play. Click **Stop** to halt playback.  
   - A small progress bar shows the playback progress in real time.  
3. **Edit/Rename**  
   - Click **Edit** (or double-click the name) to change a file’s title.  
4. **Delete**  
   - Click **Delete** to remove the file from the list.  
5. **Banks**  
   - The top segmented control switches between different banks. You can create new banks with **New Bank**.  
6. **Projects**  
   - Use **Save Project As…** to save your entire bank configuration (including multiple banks) to a JSON file, and **Open Project…** to load it back later.

---

## Preferences

Access **Preferences** (macOS 13+ “Settings…”) to:

- Toggle **Fade In/Out** for smoother playback transitions.  
- Adjust highlight color in the UI.  
- Select an **Output Device** (useful if you plan to route audio to BlackHole or a multi-output device).

---

## Building a Release

To create a release version:

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

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell 
copies of the Software, and to permit persons to whom the Software is 
furnished to do so, subject to the following conditions:

...

*(Include the full license text in a separate LICENSE file if needed.)*
