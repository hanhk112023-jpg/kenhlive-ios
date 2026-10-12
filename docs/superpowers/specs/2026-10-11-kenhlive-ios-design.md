# KenhLive iOS — Design Specification

## 1. Intent & Why
Build **KenhLive iOS**, a native iPhone application packaged as an installable `.ipa` via GitHub Actions (`macos-14` + Xcode + XcodeGen) that brings the complete 6-module OTT experience of KenhLive TV v7.3.0 to iOS with a refined, typography-driven, minimalist Apple Glassmorphism UI ("ít dùng icon" — minimal icons, content-first).

## 2. Goals, Non-Goals, and Anti-Goals
### Goals
- **Full Feature Parity with KenhLive TV v7.3.0**:
  1. **Trực Tiếp (Live Sports)**: Separate horizontal rails per provider (`Socolive`, `ColaTV`, `Gà Vàng`, `Khán Đài`), never merged. Clean match metadata (GMT+7, VIP/Zalo spam stripped). Room selection sheet (`BLV` list) and multi-server stream playback.
  2. **Lịch Đấu (Schedule)**: 7-day fixture selector, live score display, match status (`ĐANG ĐÁ`, `SẮP ĐÁ`, `KẾT THÚC`), tap to open active commentary rooms.
  3. **Truyền Hình (IPTV)**: Curated Vietnamese and Sports channels (`VTV`, `HTV`, `TV360`, `Thể Thao`, `Giải Trí`, `Yêu Thích`), inline top preview player, typographic channel badges, long-press favorite toggle.
  4. **Kho Phim (Cinema VOD Hub)**: 16:9 Cinema Spotlight Hero with `IMDb` rating badge, `Full HD · Vietsub` tag, `Đổi Phim` spotlight cycler, horizontal category filter pills, `Tiếp Tục Xem` (Continue Watching) persistence, and Episode Picker sheet.
  5. **Đa Màn Hình (MultiView)**: Dual-stream simultaneous player (vertical stack in portrait, side-by-side in landscape) with active audio slot selection and channel/match swap sheet.
  6. **Tìm Kiếm & Cài Đặt (Search & Settings)**: Unified search across Live Sports, IPTV channels, and NguonC Movies; stream quality selector, cache management, and Telegram feedback (`@T990512S`).
- **Minimalist Typography-First UI ("Ít dùng icon")**:
  - Rely on clean typography hierarchy (SF Pro Display / Rounded, weights, tracking, uppercase micro-labels, subtle glass pill badges) rather than decorative icons or emoji clutter.
  - Pure dark OLED palette (`#07080E` deep background, `#121521` surface cards, `#FF6500` brand accent, `#FBBF24` IMDb gold) with native `.ultraThinMaterial` blur sheets and navigation bar.
- **Native iOS Playback & `.ipa` Build**:
  - `AVPlayerViewController` with native Picture-in-Picture (PiP), background audio, and fullscreen orientation support for HLS (`.m3u8`) streams.
  - `WKWebView` with custom `Referer: https://phim.nguonc.com/` and desktop/mobile Safari User-Agent for VOD embed streams.
  - Automated CI workflow on `macos-14` that compiles, packages `Payload/KenhLive.app`, signs ad-hoc (`ldid` / `codesign -s -`), and publishes `KenhLive-iOS.ipa` to GitHub Releases.

### Non-Goals
- App Store submission or paid Apple Developer certificate provisioning (targets unsigned/ad-hoc `.ipa` for Sideloadly, TrollStore, AltStore, ESign, Scarlet).
- tvOS / Apple TV target in this repository (Android TV is already served by `kenhlive-tv`).

### Anti-Goals
- Never merge the 4 sports providers (`Socolive`, `ColaTV`, `Gà Vàng`, `Khán Đài`) into a single rail.
- Never clutter cards, headers, or pills with decorative icons or emojis.
- Never hardcode secrets, tokens, or API keys in source code or logs.

## 3. Architecture & File Layout
- `project.yml`: XcodeGen specification targeting iOS 15.0+, bundle ID `com.kenhlive.ios`, enabling `UIBackgroundModes: [audio]` and `NSAppTransportSecurity: { NSAllowsArbitraryLoads: true }`.
- `KenhLive/App/`:
  - `KenhLiveApp.swift`: Entry point, dark color scheme enforcement, audio session configuration (`AVAudioSession.Category.playback`).
  - `MainTabView.swift`: Minimalist typography-first bottom navigation bar switching between the 6 core modules.
  - `Theme.swift`: Color tokens, glassmorphic card modifiers, pill badge components.
- `KenhLive/Core/`:
  - `DataNormalizer.swift`: GMT+7 formatting, league name normalization, Socolive VIP/Zalo notice spam sanitizer.
  - `StorageManager.swift`: `UserDefaults` persistence for Watch History (`Continue Watching`), Favorite Films, and Favorite IPTV Channels.
- `KenhLive/Sports/`:
  - `SportsModels.swift`: `LiveRoom`, `LiveMatchGroup`, `StreamServer`, `ScheduleItem`.
  - `SportsService.swift`: Async client for `json.vnres.co` + multi-provider aggregator (`Socolive`, `ColaTV`, `Gà Vàng`, `Khán Đài`) + HLS stream resolver.
  - `LiveSportsView.swift`: Spotlight Hero + 4 separate provider rails + RoomPicker sheet.
  - `ScheduleView.swift`: 7-day date strip + match list + live room lookup.
- `KenhLive/IPTV/`:
  - `IptvModels.swift` & `IptvService.swift`: M3U parser (`vn.m3u`, `sports.m3u`), TV360 composite link resolver, curated fallback channels.
  - `IptvView.swift`: Inline live preview player + category pills + typographic channel grid.
- `KenhLive/Phim/`:
  - `PhimModels.swift` & `PhimService.swift`: Async client for `https://phim.nguonc.com/api` (batch category loader, film detail & episode parser, search).
  - `PhimView.swift`: 16:9 Cinema Spotlight Hero (`IMDb`, `Full HD`, `Đổi Phim` cycler), category filter strip, `Tiếp Tục Xem` rail, catalog rails, Episode Picker sheet.
- `KenhLive/MultiView/`:
  - `MultiViewScreen.swift`: 2-slot simultaneous HLS player (vertical split in portrait, horizontal split in landscape), active audio border highlight, stream picker sheet.
- `KenhLive/SearchAndSettings/`:
  - `SearchAndSettingsView.swift`: Unified instant search across Sports, IPTV, and Movies + minimalist settings & Telegram `@T990512S` sheet.
- `KenhLive/Player/`:
  - `HLSPlayerView.swift`: `AVPlayerViewController` wrapper with custom HTTP headers (`Referer`, `User-Agent`), PiP support, and server switcher overlay.
  - `VodWebPlayerView.swift`: `WKWebView` video player for NguonC embeds with `Referer: https://phim.nguonc.com/` and watch progress tracking.
- `.github/workflows/build-ipa.yml`: Automated macOS build, `xctest` unit test execution, `.ipa` packaging, and GitHub Release publishing.
