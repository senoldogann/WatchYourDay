# 👁️ WatchYourDay: The Silent Observer

[![Swift 6](https://img.shields.io/badge/Swift-6.0-orange.svg)](https://swift.org)
[![Platform](https://img.shields.io/badge/Platform-macOS%2014%2B-lightgrey.svg)](https://apple.com/macos)
[![License](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Privacy](https://img.shields.io/badge/Privacy-Local--First-green.svg)](PROJECT_HANDBOOK.md#5-privacy-manifesto)

> **"Your Personal Time Machine for Work."**

WatchYourDay is an autonomous, privacy-first activity tracker for macOS. It captures your digital life, indexes the text on your screen, and uses local AI to explain where your time actually went.

---

## 🌟 Key Features

### 🕵️ Stealth & Low Profile
Runs as a Menu Bar agent application with no Dock icon (`LSUIElement`). Starts automatically at login.

### 🧠 Intelligent Search
Remember seeing a document but forgot the filename? Search for the **text inside the image** using our built-in OCR engine.

### 🤖 Local AI Analysis
Connects to **Ollama** running on your machine to generate daily summaries. No data leaves your MAC.

### 🛡️ Ironclad Privacy
- **Blacklist:** Auto-pause recording for specific apps (Banking, 1Password).
- **Redaction:** Automatic PII blurring using Vision framework.
- **Local Storage:** All data stored in high-performance SwiftData local DB.

---

## 📚 Documentation
For detailed usage, architecture, and privacy philosophy, please consult the **[Project Handbook](PROJECT_HANDBOOK.md)**.

- **[Installation Guide](PROJECT_HANDBOOK.md#getting-started)**
- **[Technical Architecture](PROJECT_HANDBOOK.md#6-technical-architecture)**
- **[Privacy Manifesto](PROJECT_HANDBOOK.md#5-privacy-manifesto)**

---

## 🛠️ Tech Stack
- **SwiftUI & AppKit**: Hybrid interface for modern aesthetics and system-level control.
- **SwiftData**: Modern persistence framework.
- **ScreenCaptureKit**: High-performance, low-latency recording.
- **Vision**: OCR and Face/Text detection.

## 🚀 Getting Started

1.  Clone the repo.
2.  Install [Ollama](https://ollama.com) (Optional, for AI features).
3.  Open `WatchYourDay.xcodeproj`.
4.  Build & Run (CMD+R).

---

*Architected by Dogan & Antigravity*
