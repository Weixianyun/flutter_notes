**English** | [中文](README_zh.md)

# flutter_notes

A Flutter-based Markdown note-taking application with local encrypted storage and GitHub cloud sync.

## Features

- **Markdown Editor** — WYSIWYG-style editing with live preview powered by `flutter_markdown`
- **Local Database** — Offline-first storage using `sqflite` + `drift` ORM
- **AES-256 Encryption** — All notes are encrypted at rest via `encrypt` + `crypto`
- **GitHub Cloud Sync** — Bi-directional sync through GitHub REST API + OAuth 2.0
- **Knowledge Graph** — Visualize note relationships (planned)
- **Full-Text Search** — Fast in-app note search (planned)
- **Dark / Light Theme** — Material 3 adaptive themes

## Tech Stack

| Category | Technology |
|---|---|
| Framework | Flutter 3.x / Dart 3.x |
| State Management | Riverpod 2.x + riverpod_generator |
| Local Database | sqflite + drift |
| Markdown Rendering | flutter_markdown + markdown |
| Encryption | AES-256 (encrypt + crypto) |
| Cloud Sync | GitHub REST API + OAuth 2.0 |
| Android Target | API 36 (Android 16.0) |

## Project Structure

```
lib/
├── core/           # Routing, themes, utilities
│   ├── router/
│   ├── theme/
│   └── utils/
├── data/           # Data layer
│   ├── database/   # Drift database definitions
│   ├── models/     # Data models
│   └── repositories/ # Repository pattern
├── features/       # Feature modules
│   ├── editor/     # Markdown editor
│   ├── graph/      # Knowledge graph
│   ├── notes/      # Note list & detail
│   ├── search/     # Full-text search
│   └── sync/       # Cloud sync UI
├── services/       # Business services
│   ├── crypto_service.dart
│   ├── github_service.dart
│   └── sync_service.dart
├── shared/         # Shared widgets
├── app.dart        # App entry & theme config
└── main.dart       # Main entry point
```

## Getting Started

### Prerequisites

- Flutter SDK 3.x (Dart 3.x)
- Android Studio (with Android SDK API 36)
- Git

### Installation

```bash
# Clone the repository
git clone https://github.com/Weixianyun/flutter_notes.git
cd flutter_notes

# Install dependencies
flutter pub get

# Run code generation (drift, riverpod)
dart run build_runner build --delete-conflicting-outputs
```

### Run the App

```bash
# Debug mode
flutter run

# Release build
flutter build apk --release
```

## Development

### Code Generation

After modifying models or providers, regenerate code:

```bash
dart run build_runner build --delete-conflicting-outputs

# Watch mode for development
dart run build_runner watch --delete-conflicting-outputs
```

### Linting

```bash
flutter analyze
```

## Documentation

- [Development Log](docs/dev-log.md)

## License

This project is for personal use and is not licensed for distribution.
