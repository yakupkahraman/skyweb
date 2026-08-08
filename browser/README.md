# 🌐 SkyBrowser

**SkyBrowser** is an experimental web browser built with Flutter to understand web internals, such as HTML/CSS parsing, script execution, and DNS resolution.

It resolves custom domain names and renders pages over the `sky://` protocol.

---

## 🚀 Features

- **`sky://` Custom Protocol**: Resolves domains via the SkyDNS service and fetches page resources from GitHub repositories.
- **HTML to Widget Renderer**: Parses HTML elements and converts them directly into native Flutter widgets.
- **Custom CSS Parser**: Parses basic CSS rules and applies styles to layout components.
- **Dynamic Script Runtime (`dart_eval`)**: Executes `script.dart` files in a sandboxed environment for page interactivity.
- **Minimalist UI**: Features an address bar, favicon support, and a dark theme.

---

## 📦 How to Run

```bash
cd browser
flutter pub get
flutter run
```
