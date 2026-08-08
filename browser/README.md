# 🌐 SkyBrowser

**SkyBrowser** is an experimental web browser built with Flutter to understand web internals, such as HTML/CSS parsing, script execution, and DNS resolution.

It resolves custom domain names and renders pages over the `sky://` protocol.

---

## 🚀 Features

- **`sky://` Custom Protocol**: Resolves domains via the SkyDNS service and fetches page resources from GitHub repositories.
- **Modular Engine Architecture**:
  - 🎨 **`html.dart` (HTML Engine)**: Parses HTML DOM trees and converts them directly into native Flutter widgets. Supports flex containers (`direction`, `main-axis`, `cross-axis`, `gap`), text tags (`p`, `h1`-`h3`), links (`a`), images (`img`), inputs (`input`), buttons (`button`), and `width`/`height` dimensions.
  - 💅 **`css.dart` (CSS Engine)**: Parses CSS rules and resolves element styles using tag and class selectors with pre-compiled regular expressions for high performance.
  - ⚡ **`script.dart` (Script Runtime)**: Sandboxed Dart execution environment powered by `dart_eval` for client-side interactivity (`getInput`, `getText`, `get`, `post`, `setText`, `setTimeout`, `clearTimeout`, `setInterval`, `clearInterval`).
  - 🔌 **`engine.dart` (Facade & Hub)**: Central entry point for site fetching with parallel HTTP asset retrieval (`Future.wait`) and submodule exports.
- **Separation of UI & Logic**:
  - 🧠 **`BrowserController`**: `ChangeNotifier` state manager handling history navigation, DNS resolution, and script lifecycle.
  - 🖥️ **`MainPage`**: Reactive presentation layer listening to state updates via `ListenableBuilder`.
- **Minimalist Dark UI**: Integrated address bar, favicon rendering, and native dark theme.

---

## 📂 Codebase Structure

```
lib/
├── main.dart                 # App entrypoint & MaterialApp configuration
├── main_page.dart            # Reactive UI page component
├── browser_controller.dart   # Browser state, history, and navigation controller
├── dns_client.dart           # SkyDNS API client
└── engine/                   # Modular Browser Engine
    ├── engine.dart           # Integration hub, site fetcher & facade
    ├── html.dart             # HTML DOM to Widget renderer
    ├── css.dart              # CSS parser & style resolver
    └── script.dart           # Dart script runtime execution engine
```

---

## 📦 How to Run

```bash
cd browser
flutter pub get
flutter run
```
