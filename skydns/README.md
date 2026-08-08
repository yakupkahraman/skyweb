# ☁️ SkyDNS Service

**SkyDNS**, `sky://` ağındaki özel alan adlarını GitHub depolarıyla eşleştiren ve çözen hafif bir uç (edge) DNS servisidir.

DNS çözümleme mantığını pratik etmek amacıyla **Cloudflare Workers** ve **Cloudflare D1** kullanılarak geliştirilmiştir.

---

## 📡 API Uç Noktaları

### 1. Alan Adı Çözümleme (`GET /resolve`)
- `https://skydns.yakupkahraman.com/resolve?domain=demo&tld=sky`

### 2. Alan Adı Kaydı (`POST /register`)
- `https://skydns.yakupkahraman.com/register`
```json
{
  "domain": "ornek",
  "tld": "sky",
  "repo": "kullanici/ornek-site"
}
```

---

## 💻 Çalıştırma ve Dağıtım

```bash
cd skydns/skydns-worker
npm install
npm run dev     # Yerel sunucu
npm run deploy  # Canlıya deploy etme
```
