# IMPL-002: GitHub Auto-Update System

## Goal
Implement a fully automated update system where the app detects new versions published on GitHub Releases and prompts the user to update.

## User Constraints
- "Indirmelerini saglayacak" (Allow them to download).
- Use GitHub Actions for CI/CD.

## Architecture

### 1. The CI/CD Pipeline (.github/workflows/release.yml)
We will create a GitHub Action that triggers when a tag (e.g., `v1.0.5`) is pushed.
- **Build:** runs `xcodebuild release`.
- **Archive:** Zips `WatchYourDay.app` -> `WatchYourDay.zip`.
- **Release:** Uses `softprops/action-gh-release` to publish the artifact to GitHub.

### 2. The App Logic (`Services/UpdateService.swift`)
A new service that checks for updates silently.
- **Endpoint:** `https://api.github.com/repos/senoldogann/WatchYourDay/releases/latest`
- **Logic:** Compare `tag_name` (Remote) vs `CFBundleShortVersionString` (Local).
- **UI:** If update available, show a `Sheet` or `Alert` with "What's New" (body of release).

### 3. The Update UX
Since replacing a running macOS app requires a complex "ShipIt" style background process (like Sparkle), we will implement a "Direct Download" flow for V1.
- **Action:** User clicks "Update".
- **Result:** Opens the direct download URL (Browser) or (if feasible) downloads to Downloads folder and opens it.
- **Recommendation:** For maximum stability, we will open the GitHub Release page or the direct .zip link.

## Proposed Changes

### [NEW] .github/workflows/release.yml
- Workflow definition.

### [NEW] WatchYourDay/Services/UpdateService.swift
- Logic to fetch `releases/latest` and compare versions.

### [MODIFY] WatchYourDay/UI/SettingsView.swift
- Add "Check for Updates" button.

### [MODIFY] WatchYourDay/WatchYourDayApp.swift
- Trigger check on launch.

## Verification
- **Manual:** Push a fake tag `v9.9.9` to repo, check if app sees it.
- **Automated:** Verify JSON parsing logic via Unit Test.
