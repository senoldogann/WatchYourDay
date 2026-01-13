# 👁️ WatchYourDay

[![Swift 6](https://img.shields.io/badge/Swift-6.0-orange.svg)](https://swift.org)
[![Platform](https://img.shields.io/badge/Platform-macOS%2014%2B-lightgrey.svg)](https://apple.com/macos)
[![License](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Privacy](https://img.shields.io/badge/Privacy-Local--First-green.svg)](PROJECT_HANDBOOK.md#5-privacy--security)

**WatchYourDay** is a native macOS activity tracker built for privacy and automation. It runs silently in the background, capturing your work history and providing insights without sending a single byte of data to the cloud.

---

## Key Features

### 🕵️ Stealth Mode
Runs as a Menu Bar application with no Dock icon. Designed to be "install and forget" until you need it.

### 🧠 Intelligent Search
Don't just remember *that* you saw something; find it. The built-in OCR engine allows you to search through the text content of your screen history.

### 🤖 Local AI Analysis
Integrates with **Ollama** running locally on your machine to provide daily summaries of your activities.

### 🛡️ Privacy
- **Blacklist:** Exclude sensitive apps (like Banking or Password Managers) from recording.
- **Local Storage:** All data is stored locally in a high-performance SwiftData database.

---

## Documentation
For detailed usage and architecture, please see the **[Project Handbook](PROJECT_HANDBOOK.md)**.

- **[User Guide](PROJECT_HANDBOOK.md#4-user-guide)**
- **[Technical Architecture](PROJECT_HANDBOOK.md#6-architecture)**
- **[Privacy Policy](PROJECT_HANDBOOK.md#5-privacy--security)**

---

## Tech Stack
- **SwiftUI & AppKit**: Hybrid interface for modern aesthetics and system-level control.
- **SwiftData**: Modern persistence.
- **ScreenCaptureKit**: High-performance recording.
- **Vision**: On-device OCR.

## Setup

1.  Clone the repository.
2.  Install [Ollama](https://ollama.com) (Optional, if you want AI summaries).
3.  Open `WatchYourDay.xcodeproj`.
4.  Build & Run (CMD+R).

---

*Developed by Şenol Doğan*
