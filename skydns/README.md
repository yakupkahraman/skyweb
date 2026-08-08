# ☁️ SkyDNS Service

**SkyDNS** is a lightweight edge DNS service that resolves custom `sky://` domain names to GitHub repositories.

It is built on **Cloudflare Workers** and **Cloudflare D1** to experiment with serverless edge architecture and domain resolution.

---

## 📡 API Endpoints

### 1. Resolve Domain (`GET /resolve`)
- `https://skydns.yakupkahraman.com/resolve?domain=demo&tld=sky`

### 2. Register Domain (`POST /register`)
- `https://skydns.yakupkahraman.com/register`
```json
{
  "domain": "example",
  "tld": "sky",
  "repo": "user/my-site"
}
```

---

## 💻 Development & Deployment

```bash
cd skydns/skydns-worker
npm install
npm run dev     # Local dev server
npm run deploy  # Deploy to Cloudflare Workers
```
