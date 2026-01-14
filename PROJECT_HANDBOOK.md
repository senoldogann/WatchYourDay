# WatchYourDay: Automated Activity Tracker Feature Handbook
**Native macOS Activity Tracking & Intelligence System**

> *Privacy-First. Local-First. Automated.*

---

## 📖 Table of Contents
1. [Overview](#1-overview)
2. [Core Concepts](#2-core-concepts)
3. [Features](#3-features)
4. [User Guide](#4-user-guide)
5. [Privacy & Security](#5-privacy--security)
6. [Architecture](#6-architecture)

---

## 1. Overview
**WatchYourDay** is a macOS utility designed to automatically track your daily digital activities. Unlike manual time trackers, it runs in the background and captures the "truth" of your work day without requiring you to start or stop timers.

It uses native macOS frameworks like `ScreenCaptureKit` for high-performance recording and `Vision` for on-device OCR and text analysis. The goal is to provide you with insights into your productivity while keeping all your data strictly on your device.

## 2. Core Concepts
1.  **Unobtrusive:** The app runs as a Menu Bar agent (`LSUIElement`). It has no Dock icon and doesn't clutter your workspace.
2.  **Intelligent:** It doesn't just save screenshots; it reads the text inside them to understand context (e.g., distinguishing between different project files).
3.  **Local Sovereignty:** No data is ever sent to the cloud. All processing happens on `localhost` or via on-device CoreML.

## 3. Features

### 🕵️ Stealth Agent
- **Background Execution:** Runs silently in the background (1 FPS capture).
- **Launch at Login:** Configurable auto-start via system settings.

### 🛡️ Privacy Controls
- **Blacklist:** You can exclude specific apps (like Password Managers or Banking apps) from ever being recorded.
- **Privacy Guard:** A dedicated `PrivacyGuard` service scans all captured text and prompts for sensitive patterns (Credit Cards, Emails, API Keys).
- **Auto-Redaction:** If configured, the system scrubs PII before it ever reaches the embedding layeer.

### 📊 Hybrid Intelligence (RAG + Analytics)
- **Hybrid Retrieval:** combines semantic vector search with statistical summaries from `StatsService` for broader context.
- **Natural Language Search:** Find captured moments using semantic meaning.
- **On-Device Embeddings:** Uses Apple's `NaturalLanguage` to vectorize text instantly.
- **OCR Search:** Apple Vision framework extracts text from screenshots.

### 🤖 Local AI & Chat
- **Ollama Integration:** Connects to a local `llama3.2` model to answer questions about your day ("What was I working on at 10 AM?").
- **Zero-Config Setup:** The app detects missing AI models and installs/runs them for you automatically.
- **Chat Persistence:** History is preserved via `ChatManager` across navigation and sessions.
- **Modern Chat UI:** A fluid, distraction-free chat interface with full Markdown formatting.

### 🔄 Auto-Update
- **Seamless Upgrades:** The app checks GitHub Releases for new versions and prompts you to upgrade, ensuring you always have the latest security patches.

## 4. User Guide

### Getting Started (Zero Config)
1.  **Launch:** Open the app. It will appear in your Menu Bar (Eye icon).
2.  **Onboarding:** The new "AI Setup Wizard" will guide you through setting up the local brain.
3.  **Permissions:** You must grant "Screen Recording" permission in System Settings.

### Dashboard Usage
- **Timeline Tab:** Scroll through captured snapshots.
- **Chat Tab:** Ask the AI questions about your history.
- **Stats Tab:** View time distribution across apps.
- **Search Tab:** Find specific text.
- **Settings:** Manage blacklist, updates, and data retention.

## 5. Privacy & Security
This project was built with a strict "Local Only" policy.
- **No Analytics:** We do not track usage.
- **No Cloud Uploads:** Your images and database (`SwiftData`) live in `~/Library/Application Support`.
- **Direct AI Connection:** AI requests go directly to `http://localhost:11434`.

## 6. Architecture

### Technical Stack
- **Languages:** Swift 6.0
- **UI:** SwiftUI (Dashboard) + AppKit (Window Management)
- **Database:** SwiftData (SQLite)
- **Embedding:** `NaturalLanguage` (Apple Native)
- **OCR:** `Vision` Framework
- **AI Inference:** `OllamaManager` -> `Ollama` (Localhost)

### Pipeline
1.  **Capture:** `ScreenCaptureKit` grabs a frame.
2.  **Privacy Check:** `BlacklistManager` verifies the app is safe.
3.  **Processing:**
    - `OCRService` extracts text.
    - `PrivacyGuard` scrubs PII.
    - `EmbeddingService` generates a vector (512-dim).
4.  **Store:** Saves compressed image + Vector + Metadata to SwiftData.
5.  **Retrieval (RAG):** When you chat, `RAGService` searches SwiftData vectors using Cosine Similarity and feeds relevant context to Ollama.

---

*Developed by Şenol Doğan*
