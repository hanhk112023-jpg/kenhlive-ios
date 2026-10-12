# KenhLive iOS Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build and publish a complete native iPhone app (`KenhLive-iOS.ipa`) with all 6 core OTT modules from KenhLive TV v7.3.0 and a typography-driven minimalist Apple Glassmorphism UI with minimal icons.

**Architecture:** Pure SwiftUI app with MVVM architecture, structured across dedicated module services (Sports, IPTV, Phim, MultiView, Search, Player). Managed and generated with XcodeGen, built and packaged as an unsigned `.ipa` via GitHub Actions on `macos-14`.

**Tech Stack:** Swift 5.9, SwiftUI, AVKit (AVPlayer + PiP), WebKit (WKWebView), XcodeGen, GitHub Actions (`macos-14`, Xcode 15/16).

**Spec:** `docs/superpowers/specs/2026-10-11-kenhlive-ios-design.md`

## Global Constraints
- **Platform**: iOS 15.0+ (iPhone optimized, portrait & landscape).
- **Design Directive**: Minimalist typography-first layout ("ít dùng icon"), SF Pro weights, clean pill badges (`IMDb`, `FHD`, `LIVE`), dark glassmorphic surfaces (`.ultraThinMaterial`).
- **Feature Parity**: Complete 6 tabs (Live Sports, Schedule, IPTV, Phim Cinema, MultiView, Search & Settings).
- **Sports Separation**: Strict requirement: 4 separate rails for Socolive, ColaTV, Gà Vàng, and Khán Đài; never merge into one.
- **Security**: Zero hardcoded secrets/API keys; all tokens loaded from environment or secrets.

## Review Focus
1. **HLS Stream Headers**: AVPlayer streaming from `vnres.co` requires `Referer: https://vnres.co/`; ensure custom asset loader or HTTP headers are passed correctly.
2. **NguonC Embed Sandboxing**: Embedded film iframes require `Referer: https://phim.nguonc.com/` and full inline playback configuration without crashing on audio interruptions.
3. **MultiView Audio Isolation**: When playing 2 video streams simultaneously, only the focused slot must output audio (`isMuted = true` on the non-focused slot).
4. **BLV Notice Spam Filtering**: Regex sanitizer must cleanly strip all Zalo/Telegram/VIP betting invites from Socolive room notices.
5. **XcodeGen & IPA Packaging**: The CI pipeline must produce a valid `Payload/KenhLive.app` zip renamed to `.ipa` that installs cleanly via TrollStore/Sideloadly.

---

### Task 1: Project Scaffolding & XcodeGen Specification

**Files:**
- Create: `project.yml`
- Create: `.gitignore`
- Create: `KenhLive/Info.plist`
- Create: `KenhLive/KenhLiveApp.swift`
- Create: `KenhLive/App/Theme.swift`

**Interfaces:**
- Produces: `KenhLiveApp`, `Theme` colors (`bgDeep`, `surfaceCard`, `brandOrange`, `imdbGold`, `textSecondary`).

- [ ] **Step 1: Create `.gitignore` for Xcode & Swift**
- [ ] **Step 2: Create `project.yml` defining the iOS app target `com.kenhlive.ios` (iOS 15.0+) with background audio and arbitrary HTTP loads**
- [ ] **Step 3: Create `KenhLive/Info.plist` and `KenhLive/App/Theme.swift` with typographic design tokens and glass card modifiers**
- [ ] **Step 4: Create entry point `KenhLive/KenhLiveApp.swift` configuring `AVAudioSession` category `playback`**
- [ ] **Step 5: Commit scaffolding**

```bash
git add project.yml .gitignore KenhLive/
git commit -m "chore(project): initialize XcodeGen spec and core theme tokens"
```

---

### Task 2: Core Data Normalizer, Storage & Models

**Files:**
- Create: `KenhLive/Core/DataNormalizer.swift`
- Create: `KenhLive/Core/StorageManager.swift`
- Create: `KenhLive/Sports/SportsModels.swift`
- Create: `KenhLive/IPTV/IptvModels.swift`
- Create: `KenhLive/Phim/PhimModels.swift`

**Interfaces:**
- Produces: `DataNormalizer.cleanTitle(String)`, `DataNormalizer.sanitizeNotice(String)`, `DataNormalizer.formatGMT7(Date)`, `StorageManager.shared` (`watchHistory`, `favoriteFilmSlugs`, `favoriteChannelIds`).

- [ ] **Step 1: Implement `DataNormalizer` with Vietnam GMT+7 calendar formatters, noise stripper, and BLV VIP/Zalo notice filter**
- [ ] **Step 2: Implement `StorageManager` using `UserDefaults` with Codable storage for continue watching progress and favorites**
- [ ] **Step 3: Define data models for Live Sports (`LiveRoom`, `LiveMatchGroup`, `StreamServer`), IPTV (`IptvChannel`, `IptvCategory`), and Phim (`FilmItem`, `FilmDetail`, `EpisodeItem`, `WatchProgress`)**
- [ ] **Step 4: Commit core utilities and models**

```bash
git add KenhLive/Core/ KenhLive/Sports/ KenhLive/IPTV/ KenhLive/Phim/
git commit -m "feat(core): add data normalizer, persistent storage and data models"
```

---

### Task 3: Live Sports & Schedule Module (4 Separate Rails)

**Files:**
- Create: `KenhLive/Sports/SportsService.swift`
- Create: `KenhLive/Sports/LiveSportsView.swift`
- Create: `KenhLive/Sports/ScheduleView.swift`
- Create: `KenhLive/Sports/RoomPickerSheet.swift`

**Interfaces:**
- Consumes: `SportsModels`, `DataNormalizer`
- Produces: `SportsService.fetchGroupedMatches()`, `SportsService.resolveStream(roomNum:)`, `LiveSportsView`, `ScheduleView`

- [ ] **Step 1: Implement `SportsService` to fetch Socolive room list, resolve stream HLS URLs, and fetch ColaTV/Gà Vàng/Khán Đài fixtures**
- [ ] **Step 2: Implement `LiveSportsView` featuring Hero Spotlight banner + 4 strictly separated rails (Socolive, ColaTV, Gà Vàng, Khán Đài) with minimal typographic cards**
- [ ] **Step 3: Implement `RoomPickerSheet` presenting available commentators (BLVs), level badges, and direct play action**
- [ ] **Step 4: Implement `ScheduleView` with horizontal 7-day date pills, live match scores, and match status tags**
- [ ] **Step 5: Commit sports module**

```bash
git add KenhLive/Sports/
git commit -m "feat(sports): implement 4-rail live sports, schedule and room picker"
```

---

### Task 4: Truyền Hình (IPTV) Module & Channel Grid

**Files:**
- Create: `KenhLive/IPTV/IptvService.swift`
- Create: `KenhLive/IPTV/IptvView.swift`

**Interfaces:**
- Consumes: `IptvModels`, `StorageManager`
- Produces: `IptvService.fetchChannels()`, `IptvService.resolveTv360(channelId:)`, `IptvView`

- [ ] **Step 1: Implement `IptvService` with M3U parsing for VN and Sports playlists + TV360 API resolver + reliable fallback links (VTV1-VTV9, HTV, THVL)**
- [ ] **Step 2: Implement `IptvView` with inline top live preview player, category filter strip, typography-first channel grid, and long-press favorite bookmarking**
- [ ] **Step 3: Commit IPTV module**

```bash
git add KenhLive/IPTV/
git commit -m "feat(iptv): implement curated IPTV channels, preview player and favorites"
```

---

### Task 5: Kho Phim (Cinema VOD Hub) Module

**Files:**
- Create: `KenhLive/Phim/PhimService.swift`
- Create: `KenhLive/Phim/PhimView.swift`
- Create: `KenhLive/Phim/EpisodePickerSheet.swift`

**Interfaces:**
- Consumes: `PhimModels`, `StorageManager`
- Produces: `PhimService.fetchCatalogBatch()`, `PhimService.fetchDetail(slug:)`, `PhimView`

- [ ] **Step 1: Implement `PhimService` with NguonC REST API client (paginated category fetch, film search, episode list extraction)**
- [ ] **Step 2: Implement `PhimView` with 16:9 Cinema Spotlight Hero, `IMDb` rating badges, `Đổi Phim ↻` button, `Tiếp Tục Xem` resume rail, and catalog poster carousels**
- [ ] **Step 3: Implement `EpisodePickerSheet` for multi-episode series selection with watched state indicator**
- [ ] **Step 4: Commit Cinema VOD module**

```bash
git add KenhLive/Phim/
git commit -m "feat(phim): implement Cinema Spotlight, IMDb badges, episode picker and continue watching"
```

---

### Task 6: MultiView Dual-Player & Video Player Engines

**Files:**
- Create: `KenhLive/Player/HLSPlayerView.swift`
- Create: `KenhLive/Player/VodWebPlayerView.swift`
- Create: `KenhLive/MultiView/MultiViewScreen.swift`

**Interfaces:**
- Consumes: `AVPlayer`, `WKWebView`, `StorageManager`
- Produces: `HLSPlayerView` (supports PiP & server switching), `VodWebPlayerView` (supports NguonC embed & resume), `MultiViewScreen` (dual concurrent streams)

- [ ] **Step 1: Implement `HLSPlayerView` wrapping `AVPlayerViewController` with custom referer headers, server selector sheet, and PiP background playback**
- [ ] **Step 2: Implement `VodWebPlayerView` wrapping `WKWebView` with `Referer: https://phim.nguonc.com/` header injection, fullscreen web video support, and playback progress callbacks**
- [ ] **Step 3: Implement `MultiViewScreen` for 2 simultaneous streams with portrait (vertical) and landscape (side-by-side) layout + one-tap audio active switching**
- [ ] **Step 4: Commit player and MultiView engines**

```bash
git add KenhLive/Player/ KenhLive/MultiView/
git commit -m "feat(player,multiview): implement HLS player with PiP, WebPlayer and MultiView dual-screen"
```

---

### Task 7: Search, Settings & Main Navigation Tab Bar

**Files:**
- Create: `KenhLive/SearchAndSettings/SearchAndSettingsView.swift`
- Create: `KenhLive/App/MainTabView.swift`

**Interfaces:**
- Consumes: All views from Tasks 3, 4, 5, 6
- Produces: `MainTabView` (root navigation), `SearchAndSettingsView`

- [ ] **Step 1: Implement `SearchAndSettingsView` with unified instant search across Sports, IPTV, and Movies + video quality preferences and Telegram `@T990512S` contact link**
- [ ] **Step 2: Implement `MainTabView` with minimalist typography-first bottom tab bar using clean labels and subtle active indicator pills**
- [ ] **Step 3: Commit navigation and settings**

```bash
git add KenhLive/SearchAndSettings/ KenhLive/App/MainTabView.swift
git commit -m "feat(nav,settings): implement minimalist bottom tab bar and unified search"
```

---

### Task 8: CI/CD GitHub Actions `.ipa` Build & Release Workflow

**Files:**
- Create: `.github/workflows/build-ipa.yml`
- Create: `README.md`

**Interfaces:**
- Produces: Automated build producing `KenhLive-iOS.ipa` attached to GitHub Actions runs and GitHub Releases on `v*` tags.

- [ ] **Step 1: Create `.github/workflows/build-ipa.yml` using `macos-14`, installing `xcodegen`, generating Xcode project, building archive, packaging `Payload/KenhLive.app` -> `KenhLive-iOS.ipa`, and uploading artifact**
- [ ] **Step 2: Add GitHub Release step on `v*` tag push with automated release notes and direct `.ipa` download link**
- [ ] **Step 3: Create `README.md` with installation guide (Sideloadly, TrollStore, Scarlet, ESign) and feature documentation**
- [ ] **Step 4: Commit CI/CD pipeline**

```bash
git add .github/ README.md
git commit -m "ci: add GitHub Actions workflow to build and release installable IPA"
```
