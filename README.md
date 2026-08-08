# 🌌 SkyWeb Monorepo

> 💡 **This is a personal hobby and experimental project.** 
> My main goal is to understand how the web works under the hood (how DNS resolution works, how browsers parse HTML/CSS and render widgets, and how dynamic scripts execute) by building a custom `sky://` web ecosystem from scratch.

---

## 🧐 What is SkyWeb?

SkyWeb is an experimental web network concept running independently of the traditional `http/https` web. 
Using a custom edge DNS service (**SkyDNS**) and a custom Flutter browser (**SkyBrowser**), it resolves custom domain names over the `sky://` protocol and renders web pages.

---

## 📂 Project Structure

1. [**`browser/` (SkyBrowser)**](./browser/README.md): A Flutter browser featuring a modular rendering engine (`html.dart`, `css.dart`, `script.dart`, `engine.dart`) and state controller (`BrowserController`) that resolves `sky://` domains, fetches assets in parallel, and renders interactive pages.
2. [**`skydns/` (SkyDNS Service)**](./skydns/README.md): A lightweight Cloudflare Workers & D1 DNS service that maps `sky://` domains to GitHub repositories.
3. [**`sites/`**](./sites/): Sample web pages hosted on the `sky://` network, such as `docs` and domain registration interfaces (`domainget`).

---

## 🏗️ SkyBrowser Engine Architecture

- **`browser/lib/engine/`**:
  - `engine.dart`: Integration hub and facade for parallel asset fetching (`Future.wait`).
  - `html.dart`: HTML parser & Flutter widget builder (flex containers, headings, links, inputs, dimensions).
  - `css.dart`: Optimized CSS parser and selector resolution engine with pre-compiled RegEx.
  - `script.dart`: `dart_eval` runtime for executing page scripts in a sandboxed environment.
- **`browser/lib/browser_controller.dart`**: State manager (`ChangeNotifier`) decoupling business logic from UI.
- **`browser/lib/main_page.dart`**: Reactive presentation layer listening to `BrowserController`.

---

## 🚀 Quick Start

### 1. Running the Browser (`browser`)
```bash
cd browser
flutter pub get
flutter run
```

### 2. Developing & Deploying DNS (`skydns`)
```bash
cd skydns/skydns-worker
npm install
npm run dev     # Local development
npm run deploy  # Deploy to Cloudflare Workers
```
