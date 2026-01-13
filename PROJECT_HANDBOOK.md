# WatchYourDay: Automated Activity Tracker
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
3.  **Local Sovereignty:** No data is ever sent to the cloud. All processing happens on `localhost`.

## 3. Features

### 🕵️ Stealth Agent
- **Background Execution:** Runs silently in the background.
- **Launch at Login:** Configurable auto-start via system settings.

### 🛡️ Privacy Controls
- **Blacklist:** You can exclude specific apps (like Password Managers or Banking apps) from ever being recorded.
- **Auto-Redaction:** Detects potential PII on screen and attempts to blur it before saving.

### 🧠 Search & History
- **OCR Search:** Search for text that appeared on your screen. Useful for finding "that one document" you saw earlier.
- **Timeline:** Visual history of your day.

### 🤖 Local AI Summary
- **Ollama Support:** Connects to a local running instance of Ollama to generate text summaries of your day (e.g., "Spent 3 hours on iOS Development").

## 4. User Guide

### Getting Started
1.  **Launch:** Open the app. It will appear in your Menu Bar (Eye icon).
2.  **Dashboard:** Click the icon -> "Open Dashboard".
3.  **Permissions:** You must grant "Screen Recording" permission in System Settings for the app to function.

### Dashboard Usage
- **Timeline Tab:** Scroll through captured snapshots.
- **Stats Tab:** View time distribution across apps and generic AI insights.
- **Search Tab:** Find specific text in your history.
- **Settings:** Manage blacklist and data retention (auto-delete after 30 days).

## 5. Privacy & Security
This project was built with a strict "Local Only" policy.
- **No Analytics:** We do not track how you use the app.
- **No Cloud Uploads:** Your images and database (`SwiftData`) live in your local Application Support folder.
- **Direct AI Connection:** AI requests go directly to `http://localhost:11434`.

## 6. Architecture

### Technical Stack
- **Languages:** Swift 6.0
- **UI:** SwiftUI (Dashboard) + AppKit (Window Management)
- **Database:** SwiftData (SQLite)
- **AI Integration:** REST API to Ollama

### Pipeline
1.  **Capture:** `ScreenCaptureKit` grabs a frame.
2.  **Filter:** Checks if the frontmost app is in the Blacklist.
3.  **Process:** Extracts text (OCR) and blurs sensitive regions (Vision).
4.  **Store:** Saves compressed image and metadata.

---

*Developed by Şenol Doğan*
