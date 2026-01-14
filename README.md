# 👁️ WatchYourDay

[![Swift 6](https://img.shields.io/badge/Swift-6.0-orange.svg)](https://swift.org)
[![Platform](https://img.shields.io/badge/Platform-macOS%2014%2B-lightgrey.svg)](https://apple.com/macos)
[![License](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Privacy](https://img.shields.io/badge/Privacy-Local--First-green.svg)](PROJECT_HANDBOOK.md#5-privacy--security)
[![Release](https://img.shields.io/github/v/release/senoldogann/WatchYourDay)](https://github.com/senoldogann/WatchYourDay/releases)

**WatchYourDay** is a native macOS activity tracker built for privacy and automation. It runs silently in the background, capturing your work history and providing insights without sending a single byte of data to the cloud.

> 🚀 **New in v1.0:** Zero-Config AI Setup, Auto-Updates, and Modern Chat UI.

---

## Key Features

### 🕵️ Stealth Mode
Runs as a Menu Bar application with no Dock icon. Designed to be "install and forget" until you need it.

### 🧠 Intelligent Search (Apple Native RAG)
Don't just remember *that* you saw something; find it.
- **Offline Embeddings:** Uses Apple's `NaturalLanguage` framework (NLEmbedding) to vectorise your data instantly on-device.
- **OCR:** Swift Vision framework reads text from your screen history.
- **Privacy:** No search data ever leaves your computer.

### 🤖 Local AI & Zero-Config Setup
Integrates with **Ollama** locally to provide daily summaries and chat.
- **One-Click Setup:** No terminal needed. The built-in wizard handles downloading and configuring the AI engine for you.
- **Interactive Chat:** Chat with your history using a modern, fluid interface.

### 🔄 Auto-Update
Always stay on the latest version with built-in update checks and GitHub Actions powered releases.

### 🛡️ Privacy First
- **Blacklist:** Exclude sensitive apps (like Banking or Password Managers).
- **Local Storage:** All data stored in high-performance SwiftData.
- **PII Scrubbing:** Auto-redaction of sensitive patterns using `PrivacyGuard`.

---

## Documentation
For detailed usage and architecture, please see the **[Project Handbook](PROJECT_HANDBOOK.md)**.

- **[User Guide](PROJECT_HANDBOOK.md#4-user-guide)**
- **[Technical Architecture](PROJECT_HANDBOOK.md#6-architecture)**
- **[Privacy Policy](PROJECT_HANDBOOK.md#5-privacy--security)**

---

## Tech Stack
- **SwiftUI & AppKit**: Hybrid interface for modern aesthetics.
- **SwiftData**: Thread-safe persistence.
- **ScreenCaptureKit**: High-performance 1 FPS recording.
- **NaturalLanguage**: On-device vector embeddings.
- **Ollama**: Local LLM Inference.

## Setup

1.  Download the latest release from [GitHub Releases](https://github.com/senoldogann/WatchYourDay/releases).
2.  Unzip and move to `/Applications`.
3.  Launch the app.
4.  Follow the **AI Setup Wizard** to initialize your local brain.

### ⚠️ Installation Troubleshooting
Since this is an open-source app not signed by a $99/year Apple Developer ID, you may see a warning:
> *"WatchYourDay" cannot be opened because it is from an unidentified developer.*

**Fix:**
1.  **Right-Click** (or Control-Click) the app icon.
2.  Select **Open**.
3.  Click **Open** in the dialog box.
*(You only need to do this once)*

---

*Developed by Şenol Doğan*
