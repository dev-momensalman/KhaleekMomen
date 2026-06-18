<div align="center">

<img src="https://img.shields.io/badge/Flutter-3.x-02569B?style=for-the-badge&logo=flutter&logoColor=white" />
<img src="https://img.shields.io/badge/Dart-3.9+-0175C2?style=for-the-badge&logo=dart&logoColor=white" />
<img src="https://img.shields.io/badge/Material_3-Design-6750A4?style=for-the-badge&logo=materialdesign&logoColor=white" />
<img src="https://img.shields.io/badge/License-MIT-green?style=for-the-badge" />

# 🕌 KhaleekMomen

### تطبيق إسلامي متكامل للصوت، الأذان، القرآن الكريم، والأذكار

*A comprehensive Islamic audio platform built with Flutter & Material 3*

[Features](#-features) • [Architecture](#-architecture) • [Getting Started](#-getting-started) • [APIs Used](#-apis-used) • [Screenshots](#-screenshots) • [Contributing](#-contributing)

</div>

---

## 📖 Overview

**Islamic Audio Hub** is a feature-rich, offline-first Flutter application designed to serve the daily spiritual needs of Muslims worldwide. The app combines real-time prayer scheduling, high-quality Quran recitations, live Islamic radio, daily Azkar counters, and a mathematical Qibla compass — all inside a clean Material 3 UI with full Arabic/English localization and RTL support.

---

## ✨ Features

### 🕋 Quran Recitation
- Browse all **114 Surahs** with Arabic names, English transliterations, and verse counts
- Choose from **100+ reciters** fetched live from MP3Quran API (with offline fallback to 5 premium reciters)
- Read individual verse text using the authentic **Uthmani Quran font** alongside English translations
- Search Surahs by name (Arabic or English) or by number
- Favorite Surahs for quick access
- Persistent **last reciter selection** across sessions

### 📻 Islamic Radio
- Stream live Islamic radio stations from around the world
- Fetched dynamically from MP3Quran Radio API with **curated fallback stations**
- Search and filter stations by name or country
- Favorite stations saved locally

### 🌙 Daily Azkar
- Categorized Morning, Evening, and Sleep Azkar
- **Interactive tap counters** with visual completion state
- Arabic text with English translation for each dhikr
- Reset per-item or reset entire category

### 🕌 Prayer Times & Qibla
- Accurate prayer times fetched from **Al-Adhan API** using GPS coordinates
- Uses **Method 5 (Egyptian General Survey Authority)** calculation method
- Smart caching: serves today's cached times offline
- Highlights the **next upcoming prayer** in real-time
- Mathematical **Qibla compass** pointing toward the Kaaba (bearing angle calculation)
- Pull-to-refresh with force re-fetch support

### ⏰ Adhan Scheduler
- Automatic Adhan playback at each of the 5 daily prayers
- **10 bundled Adhan audio options** (Makkah, Alafasy, Abdulbasit, Refaat, Minshawi, and more)
- Preview any Adhan sound before selecting
- Dual-layer scheduling: **in-process Dart timer** (foreground/background) + **OS-level exact alarm notifications** (works even when app is killed)
- **Adhan Lock System**: audio is locked exclusively for Adhan playback; no other audio can interrupt
- Automatic clock-drift detection and self-correction

### 🎵 Global Audio Player
- Persistent floating player bar visible across all screens
- Real-time playback progress bar for Quran recitation
- Background audio support via `audio_service` + lock screen controls
- Custom User-Agent headers to prevent server-side blocking

### 🌐 Localization & Accessibility
- Full **Arabic (RTL)** and **English (LTR)** support
- Dynamic layout direction switching
- Light mode, Dark mode, and System-default theme
- Material 3 design system with accessible color contrast

---

## 🏗️ Architecture

The project follows a clean **MVC + Service Layer** architecture with `Provider` for state management:

```
lib/
├── main.dart                    # Bootstrap, service init, MultiProvider setup
│
├── core/
│   ├── services/
│   │   ├── audio_service.dart   # Audio engine (just_audio + audio_service)
│   │   ├── adhan_scheduler.dart # Prayer timer + OS notification scheduler
│   │   ├── prayer_service.dart  # Al-Adhan API + local cache
│   │   ├── quran_service.dart   # MP3Quran API + static Surah metadata
│   │   ├── radio_service.dart   # MP3Quran Radio API
│   │   ├── azkar_service.dart   # Curated Azkar dataset
│   │   ├── location_service.dart # GPS + permission handling
│   │   ├── notification_service.dart # OS-level exact alarms
│   │   ├── storage_service.dart # Hive local persistence
│   │   ├── http_service.dart    # HTTP client (timeout, error handling)
│   │   └── qibla_service.dart   # Bearing calculation to Kaaba
│   └── theme/
│       └── app_theme.dart       # Material 3 light/dark themes
│
├── controllers/
│   ├── home_controller.dart     # Countdown ticker, last-played resume
│   ├── quran_controller.dart    # Reciter selection, Surah playback
│   ├── radio_controller.dart    # Station playback, favorites
│   ├── prayer_controller.dart   # Prayer times fetch, lifecycle handling
│   ├── azkar_controller.dart    # Dhikr counters, category management
│   └── settings_controller.dart # Theme, language, Adhan sound
│
├── data/
│   └── models/
│       ├── audio_state.dart     # Playback state (mode, source, lock flag)
│       ├── prayer_times.dart    # 5 daily times + chronological validation
│       ├── surah.dart           # 114 Quran chapters model
│       ├── reciter.dart         # Reciter + server URL model
│       ├── station.dart         # Radio station model
│       ├── azkar_item.dart      # Dhikr text, count, translation
│       └── adhan_sound_option.dart # Bundled Adhan audio options
│
├── views/
│   ├── main_navigation_scaffold.dart
│   ├── home_view.dart
│   ├── quran_view.dart
│   ├── surah_detail_view.dart
│   ├── radio_view.dart
│   ├── azkar_view.dart
│   ├── prayer_times_view.dart
│   ├── settings_view.dart
│   └── favorites_view.dart
│
├── widgets/
│   ├── global_player_bar.dart   # Floating persistent player
│   ├── surah_tile.dart
│   ├── station_card.dart
│   └── azkar_card.dart
│
└── l10n/
    ├── app_ar.arb               # Arabic strings
    ├── app_en.arb               # English strings
    └── app_localizations*.dart  # Generated localization classes
```

### Data Flow

```
 Views ──► Controllers ──► Services ──► APIs / Local Storage
   ▲            │
   └────────────┘ (Provider notifyListeners)
```

---

## 🚀 Getting Started

### Prerequisites

- Flutter SDK `^3.9.2`
- Dart SDK `^3.9.2`
- Android SDK (API 21+) or iOS 13+
- A device or emulator with internet access for API calls

### Installation

```bash
# 1. Clone the repository
git clone https://github.com/dev-momensalman/Islamic-Audio.git
cd Islamic-Audio

# 2. Install dependencies
flutter pub get

# 3. Generate localization files (if needed)
flutter gen-l10n

# 4. Run the app
flutter run
```

### Android Permissions

The app requires the following permissions declared in `AndroidManifest.xml`:

```xml
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
<uses-permission android:name="android.permission.POST_NOTIFICATIONS" />
<uses-permission android:name="android.permission.SCHEDULE_EXACT_ALARM" />
<uses-permission android:name="android.permission.REQUEST_IGNORE_BATTERY_OPTIMIZATIONS" />
<uses-permission android:name="android.permission.FOREGROUND_SERVICE" />
<uses-permission android:name="android.permission.FOREGROUND_SERVICE_MEDIA_PLAYBACK" />
```

> ⚠️ **Android 9+ (Pie)**: The default radio streams use `http://` URLs. Make sure to add a `network_security_config.xml` or update streams to `https://` to avoid cleartext traffic blocking.

---

## 📦 Dependencies

| Package | Version | Purpose |
|---|---|---|
| `just_audio` | ^0.9.43 | Core audio playback engine |
| `audio_service` | ^0.18.15 | Background audio + lock screen controls |
| `rxdart` | ^0.28.0 | Reactive state streams (BehaviorSubject) |
| `hive` + `hive_flutter` | ^2.2.3 | Fast local key-value storage |
| `http` | ^1.2.2 | HTTP networking |
| `geolocator` | ^13.0.2 | GPS location access |
| `flutter_local_notifications` | ^18.0.1 | OS-level prayer time alarms |
| `timezone` | ^0.9.4 | Timezone-aware notification scheduling |
| `permission_handler` | ^11.3.1 | Runtime permission management |
| `provider` | ^6.1.2 | State management (ChangeNotifier) |
| `intl` | ^0.20.2 | Date/time formatting + localization |

---

## 🌐 APIs Used

| API | Endpoint | Purpose |
|---|---|---|
| **MP3Quran** | `https://mp3quran.net/api/v3/reciters` | Reciters list |
| **MP3Quran** | `https://mp3quran.net/api/v3/radios` | Radio stations |
| **Al Quran Cloud** | `https://api.alquran.cloud/v1/surah/{n}/editions/...` | Verse text + translation |
| **Al-Adhan** | `https://api.aladhan.com/v1/timings/{date}` | Daily prayer times |

All APIs have graceful offline fallbacks — the app remains functional without internet.

---

## 🎨 Design System

- **Primary Color**: Emerald Teal `#00695C`
- **Dark Mode Primary**: Bright Teal `#26A69A`
- **Typography**: Noto Sans Arabic (UI) + QuranUthmani (Quran text)
- **Design Language**: Material 3 with custom card elevations, rounded corners (16dp), and emerald-teal gradients
- **RTL Support**: Full right-to-left layout for Arabic locale

---

## 📁 Assets

### Bundled Adhan Audio Sounds

| Display Name | Reciter |
|---|---|
| أذان الحرم المكي | Makkah Grand Mosque |
| مشاري بن راشد العفاسي | Mishary Rashid Alafasy |
| عبد الباسط عبد الصمد | Abdulbasit Abdussamad |
| محمد رفعت | Mohamed Refaat |
| محمد صديق المنشاوي | Mohamed Siddiq Al-Minshawi |
| أحمد جلال يحيى | Ahmed Jalal Yahya |
| أبو العينين شعيشع | Abu Al-Aynayn Shuaysha' |
| بلبشير عبد القادر | Belbashir Abdulqadir |
| حمزة المجالي | Hamza Al-Majali |
| مصطفى إسماعيل | Mustafa Ismail |

### Fonts
- `QuranUthmani.ttf` — Authentic Uthmani Quran script rendering

---

## 🔒 Privacy & Data Safety

- **No user accounts required** — fully anonymous
- **No personal data transmitted** — GPS coordinates are used locally for prayer time calculation only
- **All settings stored on-device** — via Hive local database
- **No analytics or tracking SDKs**

---

## 🤝 Contributing

Contributions are welcome! Please follow these steps:

1. Fork the repository
2. Create a feature branch: `git checkout -b feature/your-feature-name`
3. Commit your changes: `git commit -m 'feat: add your feature'`
4. Push the branch: `git push origin feature/your-feature-name`
5. Open a Pull Request

### Coding Guidelines
- Follow the existing MVC + Service Layer architecture
- Use `Provider` for state; avoid direct widget state for business logic
- All user-facing strings must be added to both `app_ar.arb` and `app_en.arb`
- Crash-safe pattern: wrap all service calls in try/catch with graceful fallbacks

---

## 📄 License

This project is licensed under the **MIT License** — see the [LICENSE](LICENSE) file for details.

---

<div align="center">

Made with ❤️ for the Muslim community

**Islamic Audio Hub** — *Your daily companion for Quran, Azkar & Prayer*

</div>
