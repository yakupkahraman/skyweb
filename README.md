# 🌌 SkyWeb Monorepo

> 💡 **This is a personal hobby and experimental project.** 
> My main goal is to understand how the web works under the hood (how DNS resolution works, how browsers parse HTML/CSS and render widgets, and how dynamic scripts execute) by building a custom `sky://` web ecosystem from scratch.

---

## 🧐 What is SkyWeb?

SkyWeb is an experimental web network concept running independently of the traditional `http/https` web. 
Using a custom edge DNS service (**SkyDNS**) and a custom Flutter browser (**SkyBrowser**), it resolves custom domain names over the `sky://` protocol and renders web pages.

---

## 📂 Project Structure

1. [**`browser/` (SkyBrowser)**](./browser/README.md): A Flutter browser that resolves `sky://` domains, fetches HTML, CSS, and Dart scripts from GitHub, and renders them into native widgets.
2. [**`skydns/` (SkyDNS Service)**](./skydns/README.md): A lightweight Cloudflare Workers & D1 DNS service that maps `sky://` domains to GitHub repositories.
3. [**`sites/`**](./sites/): Sample web pages hosted on the `sky://` network, such as a domain registration interface.

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
